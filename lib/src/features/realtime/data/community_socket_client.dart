import 'dart:async';
import 'dart:convert';
import 'dart:math';

import '../../../domain/models.dart';
import '../domain/community_connection.dart';
import '../domain/community_event.dart';
import '../domain/community_status.dart';
import '../domain/community_topic.dart';
import 'community_requests.dart';

final class CommunitySocketClient {
  CommunitySocketClient({
    required this._connector,
    Duration ackTimeout = const Duration(seconds: 8),
    this.heartbeatInterval = const Duration(seconds: 20),
    Duration Function(int)? reconnectDelay,
    this.maxFailures = 6,
    this.recentEventLimit = 256,
    this.keepAliveInBackground = false,
  }) : _requests = CommunityRequests(ackTimeout),
       _reconnectDelay = reconnectDelay ?? _defaultDelay,
       assert(maxFailures > 0),
       assert(recentEventLimit > 0);

  final CommunityConnector _connector;
  final CommunityRequests _requests;
  final Duration heartbeatInterval;
  final Duration Function(int) _reconnectDelay;
  final int maxFailures, recentEventLimit;
  final bool keepAliveInBackground;
  final _events = StreamController<CommunityEvent>.broadcast();
  final _statuses = StreamController<CommunitySocketStatus>.broadcast();
  final _issues = StreamController<CommunitySocketIssue>.broadcast();
  final _topics = <CommunityTopic, int>{};
  final _joining = <CommunityTopic, Future<void>>{};
  final _joined = <CommunityTopic>{};
  // Topics whose join was sent on the current connection, even if never acked.
  final _attempted = <CommunityTopic>{};
  final _recent = <String>{};
  CommunitySocketStatus _status = CommunitySocketStatus(
    CommunityConnectionPhase.idle,
  );
  CommunitySocketStatus get status => _status;
  Stream<CommunityEvent> get events => _events.stream;
  Stream<CommunitySocketStatus> get statuses => _statuses.stream;
  Stream<CommunitySocketIssue> get issues => _issues.stream;
  CommunityConnection? _connection;
  StreamSubscription<Object?>? _incoming;
  Future<void>? _opening;
  Timer? _heartbeat, _reconnect;
  bool _started = false,
      _disposed = false,
      _foreground = true,
      _heartbeatBusy = false,
      _sessionRevoked = false;
  int _generation = 0, _failures = 0;

  bool _current(int generation) =>
      !_disposed &&
      !_sessionRevoked &&
      _started &&
      (_foreground || keepAliveInBackground) &&
      generation == _generation;

  Future<void> start() async {
    if (_disposed || _started || _sessionRevoked) return;
    _started = true;
    if (!_foreground && !keepAliveInBackground) {
      _set(CommunityConnectionPhase.suspended);
      return;
    }
    await _connect();
  }

  Future<void> _connect() async {
    final previous = _opening;
    if (previous != null) {
      await previous;
      if (!_disposed &&
          _started &&
          (_foreground || keepAliveInBackground) &&
          _connection == null &&
          _reconnect == null &&
          _status.phase != CommunityConnectionPhase.failed &&
          !_sessionRevoked) {
        await _connect();
      }
      return;
    }
    if (_disposed ||
        _sessionRevoked ||
        !_started ||
        (!_foreground && !keepAliveInBackground) ||
        _connection != null) {
      return;
    }
    final future = _open();
    _opening = future;
    try {
      await future;
    } finally {
      if (identical(_opening, future)) _opening = null;
    }
  }

  Future<void> _open() async {
    final generation = ++_generation;
    _set(
      _failures == 0
          ? CommunityConnectionPhase.connecting
          : CommunityConnectionPhase.reconnecting,
    );
    CommunityConnection? connection;
    try {
      connection = await _connector();
      final active = connection;
      if (!_current(generation)) {
        await connection.close();
        return;
      }
      _connection = connection;
      _incoming = active.frames.listen(
        (frame) => _receive(frame, active, generation),
        onError: (Object _) =>
            _lost(active, generation, const TransportFailure()),
        onDone: () => _lost(
          active,
          generation,
          active.closeCode == 4401
              ? const HttpFailure(401)
              : const TransportFailure(),
        ),
      );
      await request('presence:heartbeat', const {});
      if (!_current(generation) || !identical(_connection, connection)) return;
      _failures = 0;
      _set(CommunityConnectionPhase.connected);
      _heartbeat = Timer.periodic(
        heartbeatInterval,
        (_) => unawaited(_beat(active, generation)),
      );
      for (final topic in _topics.keys.toList()) {
        if (!_current(generation)) break;
        try {
          await _activate(topic);
        } catch (_) {
          /* Scoped failures are emitted by _activate. */
        }
      }
    } catch (error) {
      if (!_current(generation)) return;
      final failure = _failure(error);
      if (connection != null && identical(_connection, connection)) {
        _lost(connection, generation, failure);
      } else if (failure is HttpFailure && failure.statusCode == 401) {
        _revoke();
      } else {
        _schedule(failure);
      }
    }
  }

  Future<CommunityAck> request(String type, Map<String, Object?> data) async {
    if (_sessionRevoked) throw const HttpFailure(401);
    if (!_commands.contains(type)) throw const ParseFailure('realtime.command');
    final connection = _connection;
    if (_disposed ||
        !_started ||
        (!_foreground && !keepAliveInBackground) ||
        connection == null) {
      throw const TransportFailure();
    }
    final pending = _requests.register();
    try {
      connection.send(
        jsonEncode({'type': type, 'requestId': pending.id, 'data': data}),
      );
    } catch (error) {
      _requests.fail(pending.id, _failure(error));
    }
    return pending.future;
  }

  void _receive(Object? raw, CommunityConnection connection, int generation) {
    if (!_current(generation) || !identical(_connection, connection)) return;
    try {
      final frame = CommunityFrame.decode(raw);
      if (frame is CommunityAck) {
        _requests.complete(frame);
        if (!frame.ok && _authCodes.contains(frame.errorCode)) _revoke();
        return;
      }
      final event = frame as CommunityEvent;
      if (!_recent.add(event.eventId)) return;
      while (_recent.length > recentEventLimit) {
        _recent.remove(_recent.first);
      }
      _events.add(event);
      if (event.type == 'session:revoked' ||
          event.type == 'moderation:session-revoked') {
        _revoke();
      } else if (event.type == 'conversation:access-revoked') {
        // The server drops every subscription of this socket, not only the
        // affected conversation. Reconnect so each leased topic is authorized
        // again by its own guarded join.
        _lost(connection, generation, const TransportFailure());
      }
    } catch (error) {
      _issues.add(CommunitySocketIssue(_failure(error)));
    }
  }

  Future<void> _beat(CommunityConnection connection, int generation) async {
    if (!_current(generation) ||
        !identical(_connection, connection) ||
        _heartbeatBusy) {
      return;
    }
    _heartbeatBusy = true;
    try {
      await request('presence:heartbeat', const {});
    } catch (error) {
      _lost(connection, generation, _failure(error));
    } finally {
      if (_current(generation)) _heartbeatBusy = false;
    }
  }

  Future<void> join(CommunityTopic topic) async {
    if (_sessionRevoked) throw const HttpFailure(401);
    if (_disposed) throw const TransportFailure();
    if (!_topics.containsKey(topic) && _topics.length >= 32) {
      throw const TransportFailure();
    }
    _topics[topic] = (_topics[topic] ?? 0) + 1;
    if (_status.phase == CommunityConnectionPhase.connected) {
      await _activate(topic);
    }
  }

  Future<void> _activate(CommunityTopic topic) {
    if (!_topics.containsKey(topic) || _joined.contains(topic)) {
      return Future.value();
    }
    final existing = _joining[topic];
    if (existing != null) return existing;
    final generation = _generation;
    late final Future<void> future;
    future = () async {
      try {
        _attempted.add(topic);
        await request(topic.joinType, topic.data);
        if (_current(generation)) {
          _joined.add(topic);
          _set(_status.phase);
        }
      } catch (error) {
        if (_current(generation)) {
          final failure = _failure(error);
          _issues.add(CommunitySocketIssue(failure, topic: topic));
          if (failure is HttpFailure && failure.statusCode == 401) _revoke();
        }
        rethrow;
      } finally {
        if (identical(_joining[topic], future)) _joining.remove(topic);
      }
    }();
    _joining[topic] = future;
    future.ignore();
    return future;
  }

  Future<void> leave(CommunityTopic topic) async {
    final count = _topics[topic] ?? 0;
    if (count == 0) return;
    if (count > 1) {
      _topics[topic] = count - 1;
      return;
    }
    _topics.remove(topic);
    final generation = _generation;
    final joining = _joining[topic];
    final attempted = _attempted.contains(topic);
    if (joining != null) {
      try {
        await joining;
      } catch (_) {
        /* A leave also cleans up an unacknowledged join. */
      }
    }
    if (!_current(generation) || _topics.containsKey(topic)) return;
    final wasJoined = _joined.remove(topic);
    _set(_status.phase);
    _attempted.remove(topic);
    if (_connection != null && (wasJoined || joining != null || attempted)) {
      await request(topic.leaveType, topic.data);
    }
  }

  void _lost(
    CommunityConnection connection,
    int generation,
    AppFailure failure,
  ) {
    if (!_current(generation) || !identical(_connection, connection)) return;
    if (failure is HttpFailure && failure.statusCode == 401) {
      _revoke();
      return;
    }
    _release(failure);
    _schedule(failure);
  }

  void _revoke() {
    _sessionRevoked = true;
    _release(const HttpFailure(401));
    _set(CommunityConnectionPhase.revoked, failure: const HttpFailure(401));
  }

  void _schedule(AppFailure failure) {
    if (_disposed ||
        _sessionRevoked ||
        !_started ||
        (!_foreground && !keepAliveInBackground)) {
      return;
    }
    _failures++;
    if (_failures >= maxFailures) {
      _set(CommunityConnectionPhase.failed, failure: failure);
      return;
    }
    _set(CommunityConnectionPhase.reconnecting, failure: failure);
    _reconnect?.cancel();
    _reconnect = Timer(_reconnectDelay(_failures), () {
      _reconnect = null;
      unawaited(_connect());
    });
  }

  void _release(AppFailure failure) {
    _generation++;
    _heartbeat?.cancel();
    _heartbeat = null;
    _heartbeatBusy = false;
    _reconnect?.cancel();
    _reconnect = null;
    _requests.failAll(failure);
    _joined.clear();
    _joining.clear();
    _attempted.clear();
    final incoming = _incoming;
    _incoming = null;
    final connection = _connection;
    _connection = null;
    if (incoming != null) {
      unawaited(incoming.cancel().catchError((Object _) {}));
    }
    if (connection != null) {
      unawaited(connection.close().catchError((Object _) {}));
    }
  }

  Future<void> setForeground(bool foreground) async {
    if (_disposed || foreground == _foreground) return;
    _foreground = foreground;
    if (_sessionRevoked) {
      _set(CommunityConnectionPhase.revoked, failure: const HttpFailure(401));
      return;
    }
    if (!foreground) {
      if (!keepAliveInBackground) {
        _release(const TransportFailure());
        _set(CommunityConnectionPhase.suspended);
      }
    } else if (_started) {
      if (_connection == null) {
        _failures = 0;
        await _connect();
      }
    }
  }

  Future<void> retry() async {
    if (_disposed) return;
    if (_sessionRevoked) throw const HttpFailure(401);
    _release(const TransportFailure());
    _failures = 0;
    if (_started && (_foreground || keepAliveInBackground)) {
      _set(CommunityConnectionPhase.reconnecting);
      await _connect();
    }
  }

  void _set(CommunityConnectionPhase phase, {AppFailure? failure}) {
    if (_disposed) return;
    _status = CommunitySocketStatus(
      phase,
      failure: failure,
      failureCount: _failures,
      joinedTopics: _joined,
    );
    _statuses.add(_status);
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _started = false;
    _disposed = true;
    _release(const TransportFailure());
    _topics.clear();
    _recent.clear();
    _status = CommunitySocketStatus(CommunityConnectionPhase.disposed);
    await Future.wait([_events.close(), _statuses.close(), _issues.close()]);
  }
}

AppFailure _failure(Object error) =>
    error is AppFailure ? error : const TransportFailure();
Duration _defaultDelay(int failures) => Duration(
  milliseconds:
      min(15000, 1000 * (1 << min(max(failures - 1, 0), 4))) +
      Random().nextInt(350),
);
const _authCodes = {'AUTH_REQUIRED', 'SESSION_REVOKED'};
const _commands = {
  'presence:heartbeat',
  'channel:join',
  'channel:leave',
  'conversation:join',
  'conversation:leave',
  'message:typing',
  'dm:typing',
};
