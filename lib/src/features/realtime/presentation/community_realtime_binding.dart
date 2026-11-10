import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../domain/models.dart';
import '../../channels/presentation/live_channel_state.dart';
import '../../notifications/data/local_notification_service.dart';
import '../../notifications/domain/community_sounds.dart';
import '../../notifications/presentation/background_notification_presenter.dart';
import '../../notifications/presentation/community_chimes.dart';
import '../../notifications/presentation/notifications_controller.dart';
import '../data/community_chat_update.dart';
import '../data/community_socket_client.dart';
import '../domain/community_event.dart';
import '../domain/community_status.dart';
import '../domain/community_topic.dart';
import 'community_connection_notice.dart';
import 'community_realtime_providers.dart';

/// One application lifecycle observer owns the shared authenticated connection.
class CommunityAppBinding extends ConsumerStatefulWidget {
  const CommunityAppBinding({required this.child, super.key});
  final Widget child;
  @override
  ConsumerState<CommunityAppBinding> createState() =>
      _CommunityAppBindingState();
}

class _CommunityAppBindingState extends ConsumerState<CommunityAppBinding>
    with WidgetsBindingObserver {
  CommunitySocketClient? _client;
  StreamSubscription<CommunitySocketStatus>? _status;
  StreamSubscription<CommunityEvent>? _eventsSub;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  bool get _foreground {
    final state = WidgetsBinding.instance.lifecycleState;
    return state == null ||
        state == AppLifecycleState.resumed ||
        state == AppLifecycleState.inactive;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final client = _client;
    if (client != null) unawaited(client.setForeground(_foreground));
  }

  void _bind(CommunitySocketClient? client) {
    if (identical(client, _client)) return;
    unawaited(_status?.cancel());
    unawaited(_eventsSub?.cancel());
    _client = client;
    _status = client?.statuses.listen((status) {
      if (mounted &&
          identical(_client, client) &&
          status.phase == CommunityConnectionPhase.revoked) {
        unawaited(ref.read(authControllerProvider.notifier).refreshSession());
      }
    });
    _eventsSub = client?.events.listen((event) {
      if (event.type == 'notification:created' ||
          event.type == 'notification:updated') {
        ref.invalidate(notificationBadgeCountProvider);
        // An open list shows the change, as the website refetches its lists.
        if (ref.exists(notificationsControllerProvider)) {
          unawaited(
            ref.read(notificationsControllerProvider.notifier).refresh(),
          );
        }
      }
      if (_foreground) {
        _ring(event);
      } else {
        _presentInBackground(event);
      }
    });
    if (client != null) {
      unawaited(() async {
        await client.setForeground(_foreground);
        await client.start();
      }());
    }
  }

  /// In front, a message rings the website's chime; in the background the
  /// system notification brings its own sound.
  void _ring(CommunityEvent event) {
    final sound = messageSound(
      event.type,
      event.data,
      ref.read(sessionStateProvider)?.userId ?? '',
    );
    if (sound == null) return;
    ref
        .read(communitySoundsProvider)
        .play(sound.kind, sound.id, enabled: ref.read(chimesEnabledProvider));
  }

  void _presentInBackground(CommunityEvent event) {
    final presenter = BackgroundNotificationPresenter(
      show: ref.read(localNotificationServiceProvider).showNotification,
      loadLatestNotices: () => ref.read(notificationsRepositoryProvider).load(),
      currentUserId: ref.read(sessionStateProvider)?.userId,
      channelSlug: (channelId) => ref.exists(liveChannelsProvider)
          ? ref
                .read(liveChannelsProvider)
                .valueOrNull
                ?.where((channel) => channel.id == channelId)
                .firstOrNull
                ?.slug
          : null,
    );
    unawaited(
      presenter
          .present(event)
          .then<void>(
            (_) {},
            onError: (Object error) => debugPrint(
              'Background notification failed: ${error.runtimeType}',
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _bind(ref.watch(communitySocketProvider));
    return widget.child;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_status?.cancel());
    unawaited(_eventsSub?.cancel());
    super.dispose();
  }
}

/// A visible route owns a lease, while its controller owns cached history/draft.
class CommunityTimelineBinding extends ConsumerStatefulWidget {
  const CommunityTimelineBinding({
    required this.topic,
    required this.onUpdate,
    required this.onCatchUp,
    required this.onFailure,
    required this.child,
    this.onEvent,
    super.key,
  });
  final CommunityTopic topic;
  final void Function(CommunityChatUpdate) onUpdate;
  final Future<void> Function() onCatchUp;
  final void Function(AppFailure) onFailure;
  final void Function(CommunityEvent)? onEvent;
  final Widget child;
  @override
  ConsumerState<CommunityTimelineBinding> createState() =>
      _CommunityTimelineBindingState();
}

class _CommunityTimelineBindingState
    extends ConsumerState<CommunityTimelineBinding> {
  CommunitySocketClient? _client;
  CommunityTopic? _leased;
  StreamSubscription<CommunityEvent>? _events;
  StreamSubscription<CommunitySocketStatus>? _statuses;
  StreamSubscription<CommunitySocketIssue>? _issues;
  CommunitySocketStatus _status = CommunitySocketStatus(
    CommunityConnectionPhase.idle,
  );
  bool _joined = false;
  Timer? _catchUp;
  int _generation = 0;
  bool _current(int generation) =>
      mounted && generation == _generation && _leased != null;
  void _unbind() {
    _generation++;
    _catchUp?.cancel();
    _catchUp = null;
    unawaited(_events?.cancel());
    unawaited(_statuses?.cancel());
    unawaited(_issues?.cancel());
    _events = null;
    _statuses = null;
    _issues = null;
    final old = _client, topic = _leased;
    _leased = null;
    _joined = false;
    if (old != null && topic != null) {
      unawaited(old.leave(topic).catchError((Object _) {}));
    }
  }

  void _bind(CommunitySocketClient? client, bool visible) {
    if (identical(_client, client) &&
        _leased == (visible ? widget.topic : null)) {
      return;
    }
    _unbind();
    _client = client;
    _status =
        client?.status ?? CommunitySocketStatus(CommunityConnectionPhase.idle);
    if (!visible || client == null) return;
    final generation = _generation;
    final topic = widget.topic;
    _leased = topic;
    _events = client.events.listen((event) {
      if (!_current(generation)) return;
      try {
        final update = CommunityChatUpdate.decode(event);
        if (update?.topic == topic) widget.onUpdate(update!);
        widget.onEvent?.call(event);
      } catch (error) {
        widget.onFailure(
          error is AppFailure ? error : const ParseFailure('realtime.chat'),
        );
      }
    });
    _statuses = client.statuses.listen((status) {
      if (!_current(generation)) return;
      final joined = status.joinedTopics.contains(topic);
      if (joined && !_joined) {
        _catchUp?.cancel();
        _catchUp = Timer(const Duration(milliseconds: 150), () {
          if (_current(generation)) {
            unawaited(
              widget.onCatchUp().catchError((Object error) {
                if (_current(generation)) {
                  widget.onFailure(
                    error is AppFailure ? error : const TransportFailure(),
                  );
                }
              }),
            );
          }
        });
      }
      _joined = joined;
      setState(() => _status = status);
    });
    _issues = client.issues.listen((issue) {
      if (_current(generation) &&
          (issue.topic == null || issue.topic == topic)) {
        widget.onFailure(issue.failure);
      }
    });
    unawaited(
      client.join(topic).catchError((Object error) {
        if (_current(generation)) {
          widget.onFailure(
            error is AppFailure ? error : const TransportFailure(),
          );
        }
      }),
    );
    // Idempotent: also supports this view in isolation from the application shell.
    unawaited(client.start());
  }

  @override
  Widget build(BuildContext context) {
    final visible = ModalRoute.of(context)?.isCurrent ?? true;
    _bind(ref.watch(communitySocketProvider), visible);
    return Column(
      children: [
        if (visible)
          CommunityConnectionNotice(
            status: _status,
            onRetry: () {
              final client = _client;
              if (client != null) {
                unawaited(
                  client.retry().catchError((Object error) {
                    widget.onFailure(
                      error is AppFailure ? error : const TransportFailure(),
                    );
                  }),
                );
              }
            },
          ),
        Expanded(child: widget.child),
      ],
    );
  }

  @override
  void dispose() {
    _unbind();
    super.dispose();
  }
}
