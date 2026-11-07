import '../../../core/session_storage_contract.dart';
import '../domain/activity_models.dart';
import '../domain/activity_service.dart';

/// A snapshot supplied by the session, application lifecycle and modal owners.
final class AutomaticCheckInContext {
  const AutomaticCheckInContext({
    required this.ownerId,
    required this.sessionGeneration,
    required this.confirmed,
    required this.visible,
    required this.modalOpen,
  });

  final String? ownerId;
  final int sessionGeneration;
  final bool confirmed;
  final bool visible;
  final bool modalOpen;
}

enum AutomaticCheckInStatus { idle, busy, blocked, uncertain, failed, recorded }

/// Owner-bound coordinator. Call [update] on session, visibility, modal and
/// periodic day changes. Call [clear] on disposal or session teardown.
///
/// The service must be bound to the same confirmed owner and session generation
/// by its repository. The context must be updated synchronously when either
/// changes, including when a previously confirmed session becomes unconfirmed.
final class AutomaticCheckInCoordinator {
  AutomaticCheckInCoordinator({
    required this.ownerId,
    required this.service,
    required this.storage,
    DateTime Function()? clock,
  }) : clock = clock ?? DateTime.now {
    if (ownerId.isEmpty || service.uncertainty?.ownerId != ownerId) {
      throw ArgumentError('An uncertainty marker for the owner is required');
    }
  }

  final String ownerId;
  final ActivityService service;
  final SessionStorage storage;
  final DateTime Function() clock;
  String get _key => 'vnlf.activity.automatic.${Uri.encodeComponent(ownerId)}';

  AutomaticCheckInContext? _context;
  CheckInAcknowledgment? _celebration;
  String? _celebrationDay;
  bool _running = false;
  bool _cleared = false;
  int _revision = 0;
  AutomaticCheckInStatus _status = AutomaticCheckInStatus.idle;
  AutomaticCheckInStatus get status => _status;

  /// Schedules at most one operation; concurrent updates only replace context.
  /// Failures are represented by [status]; uncertain writes are never retried.
  Future<void> update(AutomaticCheckInContext context) async {
    if (_cleared) return;
    final previous = _context;
    if (previous == null ||
        previous.ownerId != context.ownerId ||
        previous.sessionGeneration != context.sessionGeneration ||
        previous.confirmed != context.confirmed) {
      _revision++;
      _celebration = null;
      _celebrationDay = null;
    }
    _context = context;
    if (_running || !_eligible(context)) return;
    _running = true;
    try {
      await _run();
    } finally {
      _running = false;
    }
  }

  bool _eligible(AutomaticCheckInContext context) =>
      context.ownerId == ownerId && context.confirmed && context.visible;

  bool _current(int revision, String day) =>
      !_cleared &&
      _revision == revision &&
      _context != null &&
      _context!.ownerId == ownerId &&
      _context!.confirmed &&
      activityDayString(clock()) == day;

  Future<void> _run() async {
    final uncertainty = service.uncertainty!;
    if (!uncertainty.tryAcquire()) {
      _status = AutomaticCheckInStatus.blocked;
      return;
    }
    final revision = _revision;
    final day = activityDayString(clock());
    _status = AutomaticCheckInStatus.busy;
    try {
      final phase = await storage.read(_key);
      if (!_current(revision, day)) return;
      if (await uncertainty.read()) {
        if (_current(revision, day)) _status = AutomaticCheckInStatus.uncertain;
        return;
      }
      if (!_current(revision, day) || !_context!.visible) return;
      // Unknown or malformed persisted data fails closed.
      if (phase != null &&
          !RegExp(r'^\d{4}-\d{2}-\d{2}:(pending|recorded|done)$')
              .hasMatch(phase)) {
        _status = AutomaticCheckInStatus.blocked;
        return;
      }
      final todayPhase = phase != null && phase.startsWith('$day:')
          ? phase.substring(day.length + 1)
          : null;
      if (todayPhase == 'pending') {
        _status = AutomaticCheckInStatus.uncertain;
        return;
      }
      if (todayPhase == 'done' ||
          (todayPhase == 'recorded' && _context!.modalOpen)) {
        _status = AutomaticCheckInStatus.recorded;
        return;
      }
      final claim = !_context!.modalOpen;
      await storage.write(_key, '$day:pending');
      await uncertainty.mark();
      if (!_current(revision, day) ||
          !_context!.visible ||
          claim != !_context!.modalOpen) {
        // No request has left the device. Restore the prior phase while the
        // owner lease is held so a later eligible update may proceed safely.
        if (phase == null) {
          await storage.delete(_key);
        } else {
          await storage.write(_key, phase);
        }
        await uncertainty.clear();
        if (_current(revision, day)) _status = AutomaticCheckInStatus.idle;
        return;
      }
      final result = await service.checkIn(claimCelebration: claim);
      if (!_current(revision, day)) return;
      if (result.date != day) {
        _status = AutomaticCheckInStatus.uncertain;
        return;
      }
      await storage.write(_key, '$day:${claim ? 'done' : 'recorded'}');
      if (!_current(revision, day)) return;
      await uncertainty.clear();
      if (!_current(revision, day)) {
        await uncertainty.mark();
        return;
      }
      _status = AutomaticCheckInStatus.recorded;
      if (result.showCelebration) {
        _celebration = result;
        _celebrationDay = day;
      }
      // A false claim may have completed while the modal closed. Release the
      // lease first; the follow-up acquires it and persists its own intent.
    } catch (_) {
      if (_current(revision, day)) _status = AutomaticCheckInStatus.uncertain;
    } finally {
      uncertainty.release();
    }
    if (_current(revision, day) &&
        _context!.visible &&
        !_context!.modalOpen &&
        _celebration == null) {
      // Only a confirmed false claim leaves this phase; all other phases stop.
      try {
        if (await storage.read(_key) == '$day:recorded' &&
            _current(revision, day)) {
          await _run();
        }
      } catch (_) {
        if (_current(revision, day)) _status = AutomaticCheckInStatus.failed;
      }
    }
  }

  /// Consumes a pending acknowledgment only while presenting it is safe.
  CheckInAcknowledgment? takeCelebration() {
    final context = _context;
    if (_cleared ||
        context == null ||
        !_eligible(context) ||
        context.modalOpen ||
        _celebrationDay != activityDayString(clock())) {
      return null;
    }
    final result = _celebration;
    _celebration = null;
    _celebrationDay = null;
    return result;
  }

  /// Invalidates in-flight results and drops presentation state permanently.
  /// Durable uncertainty is intentionally retained for the next instance.
  void clear() {
    _cleared = true;
    _revision++;
    _context = null;
    _celebration = null;
    _celebrationDay = null;
    _status = AutomaticCheckInStatus.idle;
  }
}
