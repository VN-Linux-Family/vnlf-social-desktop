import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/api_client.dart';
import '../../../core/session_storage_contract.dart';
import '../data/live_activity_repository.dart';
import '../domain/activity_models.dart';
import '../domain/activity_service.dart';
import '../domain/activity_uncertainty.dart';
import '../presentation/activity_screen.dart';
import 'automatic_checkin_coordinator.dart';

/// Share one tracker between distinct observers on every app navigator.
/// Popup routes remain blocking even when another route covers them.
class AutomaticModalTracker extends ChangeNotifier {
  AutomaticModalTracker({this.blockedPageNames = const {}});

  final Set<String> blockedPageNames;
  final Set<Route<dynamic>> _routes = {};
  bool get modalOpen => _routes.isNotEmpty;
  NavigatorObserver observer() => _ModalObserver(this);

  void _add(Route<dynamic> route) {
    if ((route is PopupRoute ||
            blockedPageNames.contains(route.settings.name)) &&
        _routes.add(route)) {
      notifyListeners();
    }
  }

  void _remove(Route<dynamic> route) {
    if (_routes.remove(route)) notifyListeners();
  }
}

class _ModalObserver extends NavigatorObserver {
  _ModalObserver(this.tracker);
  final AutomaticModalTracker tracker;
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      tracker._add(route);
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      tracker._remove(route);
  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      tracker._remove(route);
  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (oldRoute != null) tracker._remove(oldRoute);
    if (newRoute != null) tracker._add(newRoute);
  }
}

/// Wrap the router's child. [confirmation] must be a fresh identity for each
/// successful server session confirmation; null means unconfirmed.
class AutomaticCheckInBinding extends StatefulWidget {
  const AutomaticCheckInBinding({
    super.key,
    required this.client,
    required this.storage,
    required this.tracker,
    required this.navigatorKey,
    required this.ownerId,
    required this.confirmation,
    required this.live,
    required this.onViewActivity,
    required this.child,
    this.onAcknowledged,
    this.clock,
  });

  final ApiClient client;
  final SessionStorage storage;
  final AutomaticModalTracker tracker;
  final GlobalKey<NavigatorState> navigatorKey;
  final String? ownerId;
  final Object? confirmation;
  final bool live;
  final VoidCallback onViewActivity;
  final ValueChanged<String>? onAcknowledged;
  final Widget child;
  final DateTime Function()? clock;

  @override
  State<AutomaticCheckInBinding> createState() =>
      _AutomaticCheckInBindingState();
}

class _AutomaticCheckInBindingState extends State<AutomaticCheckInBinding>
    with WidgetsBindingObserver {
  AutomaticCheckInCoordinator? _coordinator;
  ApiSessionScope? _scope;
  VoidCallback? _unobserve;
  Timer? _timer;
  DialogRoute<void>? _dialog;
  NavigatorState? _dialogNavigator;
  Object? _invalidConfirmation;
  int _generation = 0;
  int _acknowledgedWrites = 0;
  bool _visible = false;
  bool _running = false;
  AutomaticCheckInCoordinator? _activeCoordinator;
  bool _dirty = false;
  bool _frameQueued = false;
  String? _day;

  DateTime get _now => widget.clock?.call() ?? DateTime.now();
  bool get _valid {
    if (!widget.live ||
        widget.ownerId == null ||
        widget.ownerId!.trim().isEmpty ||
        widget.confirmation == null ||
        identical(widget.confirmation, _invalidConfirmation)) {
      return false;
    }
    try {
      _scope?.ensureCurrent();
      return _scope != null;
    } catch (_) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _visible =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    widget.tracker.addListener(_changed);
    _attach();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      final day = activityDayString(_now);
      if (day != _day ||
          _coordinator?.status == AutomaticCheckInStatus.blocked) {
        _changed();
      }
    });
  }

  void _attach() {
    _scope = widget.client.captureSession();
    _unobserve = widget.client.observeSessionInvalidation(() {
      _invalidConfirmation = widget.confirmation;
      _reset();
    });
    _changed();
  }

  void _reset() {
    _generation++;
    _coordinator?.clear();
    _coordinator = null;
    _acknowledgedWrites = 0;
    _closeDialog();
    _dirty = false;
  }

  @override
  void didUpdateWidget(covariant AutomaticCheckInBinding oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tracker != widget.tracker) {
      oldWidget.tracker.removeListener(_changed);
      widget.tracker.addListener(_changed);
    }
    if (oldWidget.client != widget.client ||
        oldWidget.storage != widget.storage ||
        oldWidget.ownerId != widget.ownerId ||
        oldWidget.live != widget.live ||
        !identical(oldWidget.confirmation, widget.confirmation)) {
      _reset();
      _unobserve?.call();
      _attach();
    } else {
      _changed();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _visible = state == AppLifecycleState.resumed;
    _changed();
  }

  void _changed() {
    if (!mounted) return;
    _day = activityDayString(_now);
    if (!_valid) {
      _reset();
      return;
    }
    final owner = widget.ownerId!;
    final coordinator = _coordinator ??= AutomaticCheckInCoordinator(
      ownerId: owner,
      service: ActivityService(
        LiveActivityRepository(
          widget.client,
          ownerId: owner,
          currentOwnerId: () => _valid ? widget.ownerId : null,
        ),
        uncertainty: ActivityUncertainty(widget.storage, owner),
      ),
      storage: widget.storage,
      clock: () => _now,
    );
    final context = AutomaticCheckInContext(
      ownerId: owner,
      sessionGeneration: _generation,
      confirmed: true,
      visible: _visible,
      modalOpen: widget.tracker.modalOpen,
    );
    // Update immediately, even during a pending call, to invalidate its view.
    if (_running) {
      if (identical(_activeCoordinator, coordinator)) {
        unawaited(coordinator.update(context));
      }
      _dirty = true;
      return;
    }
    _running = true;
    _activeCoordinator = coordinator;
    final future = coordinator.update(context);
    final generation = _generation;
    future.whenComplete(() {
      _running = false;
      _activeCoordinator = null;
      if (!mounted) return;
      if (generation == _generation &&
          _valid &&
          identical(_coordinator, coordinator) &&
          coordinator.acknowledgedWrites > _acknowledgedWrites) {
        _acknowledgedWrites = coordinator.acknowledgedWrites;
        widget.onAcknowledged?.call(owner);
      }
      if (generation != _generation || _dirty) {
        _dirty = false;
        _changed();
      } else {
        _queuePresentation();
      }
    });
  }

  void _queuePresentation() {
    if (_frameQueued) return;
    _frameQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _frameQueued = false;
      if (!mounted ||
          !_valid ||
          !_visible ||
          widget.tracker.modalOpen ||
          _dialog != null) {
        return;
      }
      final navigator = widget.navigatorKey.currentState;
      if (navigator == null || !navigator.mounted) return;
      final acknowledgment = _coordinator?.takeCelebration();
      if (acknowledgment == null) return;
      final generation = _generation;
      late final DialogRoute<void> route;
      route = DialogRoute<void>(
        context: navigator.context,
        builder: (_) => ActivityCheckInCelebration(
          acknowledgment: acknowledgment,
          onContinue: () => _removeDialog(route),
          onViewActivity: () {
            if (!mounted || generation != _generation || !_valid) return;
            _removeDialog(route);
            if (mounted && generation == _generation && _valid) {
              widget.onViewActivity();
            }
          },
        ),
      );
      _dialog = route;
      _dialogNavigator = navigator;
      navigator.push(route).whenComplete(() {
        if (identical(_dialog, route)) {
          _dialog = null;
          _dialogNavigator = null;
        }
      });
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  void _removeDialog(DialogRoute<void> route) {
    if (!identical(_dialog, route)) return;
    _closeDialog();
  }

  void _closeDialog() {
    final route = _dialog;
    final navigator = _dialogNavigator;
    _dialog = null;
    _dialogNavigator = null;
    if (route != null &&
        navigator != null &&
        navigator.mounted &&
        route.isActive) {
      navigator.removeRoute(route);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.tracker.removeListener(_changed);
    _timer?.cancel();
    _unobserve?.call();
    _reset();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
