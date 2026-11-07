import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/app/providers.dart';
import 'package:vnlfsocialapp/src/features/realtime/domain/community_connection.dart';
import 'package:vnlfsocialapp/src/features/realtime/domain/community_status.dart';
import 'package:vnlfsocialapp/src/features/realtime/presentation/community_realtime_providers.dart';
import 'package:vnlfsocialapp/src/domain/models.dart';

void main() {
  test('guests and offline fixtures do not create a socket', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    expect(c.read(communitySocketProvider), isNull);
    c.read(sessionStateProvider.notifier).state = const Session(
      userId: 'a',
      displayName: 'A',
      role: 'MEMBER',
    );
    expect(c.read(communitySocketProvider), isNull);
  });
  test('account changes replace the socket and session invalidation stops it immediately', () async {
    final sockets = <FakeConnection>[];
    final c = ProviderContainer(
      overrides: [
        communityConnectorProvider.overrideWithValue(() async {
          final s = FakeConnection();
          sockets.add(s);
          return s;
        }),
      ],
    );
    addTearDown(c.dispose);
    c.read(sessionStateProvider.notifier).state = const Session(
      userId: 'a',
      displayName: 'A',
      role: 'MEMBER',
    );
    final a = c.read(communitySocketProvider)!;
    await a.start();
    c.read(apiClientProvider).invalidateSession();
    expect(a.status.phase, CommunityConnectionPhase.disposed);
    c.read(sessionStateProvider.notifier).state = const Session(
      userId: 'b',
      displayName: 'B',
      role: 'MEMBER',
    );
    final b = c.read(communitySocketProvider)!;
    await b.start();
    expect(identical(a, b), isFalse);
    expect(sockets, hasLength(2));
    expect(sockets.first.closed, isTrue);
    c.read(sessionStateProvider.notifier).state = null;
    expect(c.read(communitySocketProvider), isNull);
    expect(b.status.phase, CommunityConnectionPhase.disposed);
  });
}

class FakeConnection implements CommunityConnection {
  final incoming = StreamController<Object?>.broadcast(sync: true);
  final sent = <Map<String, dynamic>>[];
  bool closed = false;
  @override
  Stream<Object?> get frames => incoming.stream;
  @override
  int? get closeCode => null;
  @override
  void send(String frame) {
    final d = jsonDecode(frame) as Map<String, dynamic>;
    sent.add(d);
    incoming.add(jsonEncode({'ok': true, 'requestId': d['requestId']}));
  }

  @override
  Future<void> close() async {
    closed = true;
    await incoming.close();
  }
}
