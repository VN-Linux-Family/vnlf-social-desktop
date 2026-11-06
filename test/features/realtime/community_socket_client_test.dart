import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/core/api_client.dart';
import 'package:vnlfsocialapp/src/features/realtime/data/community_socket_client.dart';
import 'package:vnlfsocialapp/src/features/realtime/domain/community_connection.dart';
import 'package:vnlfsocialapp/src/features/realtime/domain/community_status.dart';
import 'package:vnlfsocialapp/src/features/realtime/domain/community_topic.dart';

void main() {
  testWidgets('revocation remains terminal across foreground changes', (
    tester,
  ) async {
    final socket = _Connection();
    var connects = 0;
    final client = CommunitySocketClient(
      connector: () async {
        connects++;
        return socket;
      },
    );
    await client.start();
    await socket.remoteClose(4401);
    await tester.pump();
    await client.setForeground(false);
    await client.setForeground(true);
    expect(connects, 1);
    expect(client.status.phase, CommunityConnectionPhase.revoked);
    await expectLater(client.retry(), throwsA(isA<HttpFailure>()));
    await client.dispose();
  });

  testWidgets(
    'periodic heartbeat failure reconnects without overlapping heartbeats',
    (tester) async {
      final first = _Connection(), second = _Connection();
      var connects = 0;
      final client = CommunitySocketClient(
        connector: () async => connects++ == 0 ? first : second,
        reconnectDelay: (_) => const Duration(milliseconds: 10),
      );
      addTearDown(client.dispose);
      await client.start();
      first.autoAck = false;
      await tester.pump(const Duration(seconds: 20));
      expect(first.sent.length, 2);
      await tester.pump(const Duration(seconds: 8));
      await tester.pump(const Duration(milliseconds: 10));
      await tester.pump();
      expect(connects, 2);
      expect(client.status.phase, CommunityConnectionPhase.connected);
      expect(second.types, ['presence:heartbeat']);
      await client.dispose();
    },
  );

  testWidgets(
    'disposing during a delayed connector closes its eventual socket',
    (tester) async {
      final connector = Completer<CommunityConnection>();
      final socket = _Connection();
      final client = CommunitySocketClient(connector: () => connector.future);
      final opening = client.start();
      await client.dispose();
      connector.complete(socket);
      await opening;
      expect(socket.closeCount, 1);
      expect(socket.sent, isEmpty);
    },
  );

  testWidgets(
    'resume waits for an obsolete upgrade before opening one replacement',
    (tester) async {
      final delayed = Completer<CommunityConnection>();
      final first = _Connection(), second = _Connection();
      var connects = 0;
      final client = CommunitySocketClient(
        connector: () {
          connects++;
          return connects == 1 ? delayed.future : Future.value(second);
        },
      );
      final opening = client.start();
      await client.setForeground(false);
      final resumed = client.setForeground(true);
      expect(connects, 1);
      delayed.complete(first);
      await opening;
      await resumed;
      expect(connects, 2);
      expect(first.closeCount, 1);
      expect(second.types, ['presence:heartbeat']);
      await client.dispose();
    },
  );

  testWidgets(
    'pending acknowledgment storage is bounded and released on disposal',
    (tester) async {
      final socket = _Connection();
      final client = CommunitySocketClient(connector: () async => socket);
      await client.start();
      socket.autoAck = false;
      final requests = <Future<void>>[];
      for (var i = 0; i < 32; i++) {
        requests.add(
          client
              .request('presence:heartbeat', {})
              .then<void>((_) {}, onError: (Object _) {}),
        );
      }
      await expectLater(
        client.request('presence:heartbeat', {}),
        throwsA(isA<TransportFailure>()),
      );
      expect(socket.sent.length, 33);
      await client.dispose();
      await Future.wait(requests);
    },
  );

  testWidgets(
    'one connection authenticates with a heartbeat and renews every twenty seconds',
    (tester) async {
      final socket = _Connection();
      var connects = 0;
      final client = CommunitySocketClient(
        connector: () async {
          connects++;
          return socket;
        },
      );
      await client.start();
      await client.start();
      expect(connects, 1);
      expect(client.status.phase, CommunityConnectionPhase.connected);
      expect(socket.types, ['presence:heartbeat']);
      await tester.pump(const Duration(seconds: 19));
      expect(socket.sent.length, 1);
      await tester.pump(const Duration(seconds: 1));
      expect(socket.sent.length, 2);
      await client.dispose();
      await tester.pump();
    },
  );

  testWidgets(
    'acknowledgments correlate independently and unknown ones are ignored',
    (tester) async {
      final socket = _Connection();
      final client = CommunitySocketClient(connector: () async => socket);
      await client.start();
      socket.autoAck = false;
      final first = client.request('dm:typing', {
        ..._topic.data,
        'isTyping': true,
      });
      final second = client.request('presence:heartbeat', {});
      socket.ack('unrelated');
      socket.ack(socket.sent.last['requestId'] as String, data: {'order': 2});
      socket.ack(socket.sent[1]['requestId'] as String, data: {'order': 1});
      expect((await first).data, {'order': 1});
      expect((await second).data, {'order': 2});
      await client.dispose();
    },
  );

  testWidgets('eight second timeout never replays the expired request', (
    tester,
  ) async {
    final socket = _Connection();
    final client = CommunitySocketClient(connector: () async => socket);
    await client.start();
    socket.autoAck = false;
    final assertion = expectLater(
      client.request('dm:typing', {'conversationId': _id, 'isTyping': true}),
      throwsA(isA<TransportFailure>()),
    );
    await tester.pump(const Duration(seconds: 8));
    await assertion;
    expect(socket.types, ['presence:heartbeat', 'dm:typing']);
    await client.dispose();
  });

  testWidgets(
    'subscription counts prevent duplicate joins and premature leaves',
    (tester) async {
      final socket = _Connection();
      final client = CommunitySocketClient(connector: () async => socket);
      await client.start();
      await client.join(_topic);
      await client.join(_topic);
      expect(socket.types, ['presence:heartbeat', 'conversation:join']);
      await client.leave(_topic);
      expect(socket.types.last, 'conversation:join');
      await client.leave(_topic);
      expect(socket.types.last, 'conversation:leave');
      await client.dispose();
    },
  );

  testWidgets(
    'topic removal during a slow join waits before sending one leave',
    (tester) async {
      final socket = _Connection();
      final client = CommunitySocketClient(connector: () async => socket);
      await client.start();
      socket.autoAck = false;
      final join = client.join(_topic);
      final joinId = socket.sent.last['requestId'] as String;
      final leave = client.leave(_topic);
      expect(socket.types.last, 'conversation:join');
      socket.autoAck = true;
      socket.ack(joinId);
      await join;
      await leave;
      expect(socket.types, [
        'presence:heartbeat',
        'conversation:join',
        'conversation:leave',
      ]);
      await client.dispose();
    },
  );

  testWidgets(
    'reconnect rejoins current topics but never resends old commands',
    (tester) async {
      final first = _Connection(), second = _Connection();
      var connects = 0;
      final client = CommunitySocketClient(
        connector: () async => connects++ == 0 ? first : second,
        reconnectDelay: (_) => const Duration(milliseconds: 10),
      );
      await client.start();
      await client.join(_topic);
      await client.request('dm:typing', {
        'conversationId': _id,
        'isTyping': true,
      });
      await first.remoteClose(1006);
      await tester.pump(const Duration(milliseconds: 10));
      await tester.pump();
      expect(connects, 2);
      expect(second.types, ['presence:heartbeat', 'conversation:join']);
      expect(client.status.phase, CommunityConnectionPhase.connected);
      await client.dispose();
    },
  );

  testWidgets(
    'session revocation stops reconnecting and rejects pending requests',
    (tester) async {
      final socket = _Connection();
      var connects = 0;
      final client = CommunitySocketClient(
        connector: () async {
          connects++;
          return socket;
        },
      );
      await client.start();
      socket.autoAck = false;
      final request = expectLater(
        client.request('presence:heartbeat', {}),
        throwsA(isA<HttpFailure>()),
      );
      await socket.remoteClose(4401);
      await tester.pump();
      await request;
      expect(client.status.phase, CommunityConnectionPhase.revoked);
      await tester.pump(const Duration(minutes: 1));
      expect(connects, 1);
      await client.dispose();
    },
  );

  testWidgets('backgrounding closes a late upgrade before it sends anything', (
    tester,
  ) async {
    final pending = Completer<CommunityConnection>();
    final socket = _Connection();
    final client = CommunitySocketClient(connector: () => pending.future);
    final opening = client.start();
    await client.setForeground(false);
    pending.complete(socket);
    await opening;
    await tester.pump();
    expect(socket.closeCount, 1);
    expect(socket.sent, isEmpty);
    expect(client.status.phase, CommunityConnectionPhase.suspended);
    await client.dispose();
  });

  testWidgets('six consecutive failures stop until an explicit retry', (
    tester,
  ) async {
    var connects = 0;
    final client = CommunitySocketClient(
      connector: () async {
        connects++;
        throw const TransportFailure();
      },
      reconnectDelay: (_) => const Duration(milliseconds: 1),
    );
    await client.start();
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 1));
    }
    expect(connects, 6);
    expect(client.status.phase, CommunityConnectionPhase.failed);
    await tester.pump(const Duration(minutes: 1));
    expect(connects, 6);
    await client.retry();
    expect(connects, 7);
    await client.dispose();
  });

  test(
    'malformed frames report a typed issue while duplicate events are bounded',
    () async {
      final socket = _Connection();
      final client = CommunitySocketClient(
        connector: () async => socket,
        recentEventLimit: 2,
      );
      final seen = <String>[], issues = <CommunitySocketIssue>[];
      final events = client.events.listen((e) => seen.add(e.eventId));
      final errors = client.issues.listen(issues.add);
      await client.start();
      socket.raw('not-json');
      socket.event('one');
      socket.event('one');
      socket.event('two');
      socket.event('three');
      socket.event('one');
      await Future<void>.delayed(Duration.zero);
      expect(seen, ['one', 'two', 'three', 'one']);
      expect(issues.single.failure, isA<ParseFailure>());
      await events.cancel();
      await errors.cancel();
      await client.dispose();
    },
  );

  test('negative topic acknowledgment preserves connection and emits its scoped failure', () async {
    final socket = _Connection()..failType = 'conversation:join';
    final client = CommunitySocketClient(connector: () async => socket);
    final issues = <CommunitySocketIssue>[];
    final listener = client.issues.listen(issues.add);
    await client.start();
    await expectLater(client.join(_topic), throwsA(isA<HttpFailure>()));
    await Future<void>.delayed(Duration.zero);
    expect(client.status.phase, CommunityConnectionPhase.connected);
    expect(issues.single.topic, _topic);
    await listener.cancel();
    await client.dispose();
  });

  test(
    'access revocation reconnects, keeps leases and rejects the old join ack',
    () async {
      final first = _Connection()..holdType = 'conversation:join';
      final second = _Connection()..holdType = 'conversation:join';
      var connects = 0;
      final client = CommunitySocketClient(
        connector: () async => connects++ == 0 ? first : second,
        reconnectDelay: (_) => const Duration(milliseconds: 10),
      );
      final seen = <String>[];
      final listener = client.events.listen((e) => seen.add(e.type));
      await client.start();
      final oldJoin = expectLater(
        client.join(_topic),
        throwsA(isA<TransportFailure>()),
      );
      final oldId = first.sent.last['requestId'] as String;
      first.event('revoked', type: 'conversation:access-revoked');
      await oldJoin;
      expect(seen, ['conversation:access-revoked']);
      expect(first.closeCount, 1);
      expect(client.status.phase, CommunityConnectionPhase.reconnecting);
      first.ack(oldId);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await Future<void>.delayed(Duration.zero);
      expect(connects, 2);
      expect(second.types, ['presence:heartbeat', 'conversation:join']);
      expect(client.status.joinedTopics, isEmpty);
      second.holdType = null;
      second.ack(second.sent.last['requestId'] as String);
      await Future<void>.delayed(Duration.zero);
      expect(client.status.joinedTopics, {_topic});
      await listener.cancel();
      await client.dispose();
    },
  );

  testWidgets('last leave after a timed-out join still sends a leave', (
    tester,
  ) async {
    final socket = _Connection()..holdType = 'conversation:join';
    final client = CommunitySocketClient(connector: () async => socket);
    await client.start();
    final join = expectLater(
      client.join(_topic),
      throwsA(isA<TransportFailure>()),
    );
    await tester.pump(const Duration(seconds: 8));
    await join;
    await client.leave(_topic);
    expect(socket.types, [
      'presence:heartbeat',
      'conversation:join',
      'conversation:leave',
    ]);
    await client.dispose();
  });

  test('last leave after a rejected join sends exactly one leave', () async {
    final socket = _Connection()..failType = 'conversation:join';
    final client = CommunitySocketClient(connector: () async => socket);
    await client.start();
    await expectLater(client.join(_topic), throwsA(isA<HttpFailure>()));
    await client.leave(_topic);
    await client.leave(_topic);
    expect(socket.types, [
      'presence:heartbeat',
      'conversation:join',
      'conversation:leave',
    ]);
    await client.dispose();
  });

  testWidgets(
    'retry reports reconnecting while it drops a joining connection',
    (tester) async {
      final first = _Connection(),
          second = _Connection(),
          third = _Connection();
      final sockets = [first, second, third];
      var connects = 0;
      final client = CommunitySocketClient(
        connector: () async => sockets[connects++],
        reconnectDelay: (_) => const Duration(milliseconds: 10),
      );
      await client.start();
      await client.join(_topic);
      second.holdType = 'conversation:join';
      await first.remoteClose(1006);
      await tester.pump(const Duration(milliseconds: 10));
      await tester.pump();
      expect(client.status.phase, CommunityConnectionPhase.connected);
      expect(second.types, ['presence:heartbeat', 'conversation:join']);
      final retry = client.retry();
      expect(client.status.phase, CommunityConnectionPhase.reconnecting);
      await retry;
      await tester.pump();
      expect(connects, 3);
      expect(second.closeCount, 1);
      expect(third.types, ['presence:heartbeat', 'conversation:join']);
      expect(client.status.phase, CommunityConnectionPhase.connected);
      await client.dispose();
    },
  );

  testWidgets('any authentication ack revokes terminally', (tester) async {
    final socket = _Connection();
    var connects = 0;
    final client = CommunitySocketClient(
      connector: () async {
        connects++;
        return socket;
      },
    );
    await client.start();
    socket.failType = 'message:typing';
    socket.failCode = 'SESSION_REVOKED';
    final unrelated = expectLater(
      (() {
        socket.autoAck = false;
        return client.request('dm:typing', {});
      })(),
      throwsA(isA<HttpFailure>()),
    );
    socket.autoAck = true;
    await expectLater(
      client.request('message:typing', {}),
      throwsA(isA<HttpFailure>().having((f) => f.statusCode, 'status', 401)),
    );
    await unrelated;
    expect(client.status.phase, CommunityConnectionPhase.revoked);
    await expectLater(client.join(_topic), throwsA(isA<HttpFailure>()));
    await tester.pump(const Duration(minutes: 1));
    expect(connects, 1);
    expect(socket.closeCount, 1);
    await client.dispose();
  });

  testWidgets(
    'outgoing content writes are never accepted by the realtime client',
    (tester) async {
      final socket = _Connection();
      final client = CommunitySocketClient(connector: () async => socket);
      await client.start();
      await expectLater(
        client.request('dm:send', {}),
        throwsA(isA<ParseFailure>()),
      );
      expect(socket.types, ['presence:heartbeat']);
      await client.dispose();
    },
  );
}

const _id = '00000000-0000-4000-8000-000000000111';
final _topic = CommunityTopic.conversation(_id);

class _Connection implements CommunityConnection {
  final _incoming = StreamController<Object?>.broadcast(sync: true);
  final sent = <Map<String, dynamic>>[];
  bool autoAck = true;
  String? failType, failCode, holdType;
  int closeCount = 0;
  @override
  int? closeCode;
  List<String> get types => sent.map((e) => e['type'] as String).toList();
  @override
  Stream<Object?> get frames => _incoming.stream;
  @override
  void send(String frame) {
    final data = jsonDecode(frame) as Map<String, dynamic>;
    sent.add(data);
    if (autoAck && data['type'] != holdType) {
      ack(data['requestId'] as String, ok: data['type'] != failType);
    }
  }

  void ack(
    String id, {
    bool ok = true,
    Map<String, Object?>? data,
    String? code,
  }) => raw(
    jsonEncode({
      'ok': ok,
      'requestId': id,
      'data': data,
      if (!ok)
        'error': {
          'code': code ?? failCode ?? 'CONVERSATION_FORBIDDEN',
          'message': 'Synthetic permission error',
        },
    }),
  );
  void raw(String frame) {
    if (!_incoming.isClosed) _incoming.add(frame);
  }

  void event(String id, {String type = 'future:event'}) => raw(
    jsonEncode({
      'type': type,
      'eventId': id,
      'occurredAt': '2026-11-06T00:00:00Z',
      'data': <String, Object?>{},
    }),
  );
  Future<void> remoteClose(int code) async {
    closeCode = code;
    await _incoming.close();
  }

  @override
  Future<void> close() async {
    closeCount++;
    if (!_incoming.isClosed) {
      closeCode = 1000;
      await _incoming.close();
    }
  }
}
