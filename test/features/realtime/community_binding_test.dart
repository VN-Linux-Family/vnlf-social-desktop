import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/app/providers.dart';
import 'package:vnlfsocialapp/src/domain/models.dart';
import 'package:vnlfsocialapp/src/features/notifications/domain/community_sounds.dart';
import 'package:vnlfsocialapp/src/features/notifications/presentation/community_chimes.dart';
import 'package:vnlfsocialapp/src/features/realtime/data/community_socket_client.dart';
import 'package:vnlfsocialapp/src/features/realtime/domain/community_topic.dart';
import 'package:vnlfsocialapp/src/features/realtime/presentation/community_realtime_binding.dart';
import 'package:vnlfsocialapp/src/features/realtime/presentation/community_realtime_providers.dart';

import 'community_provider_test.dart' show FakeConnection;

const id = '11111111-1111-4111-8111-111111111111';
void main() {
  testWidgets(
    'visible routes lease one topic, apply routed events, and leave when covered',
    (t) async {
      final socket = FakeConnection();
      final client = CommunitySocketClient(connector: () async => socket);
      final navigator = GlobalKey<NavigatorState>();
      var updates = 0, caughtUp = 0;
      await t.pumpWidget(
        ProviderScope(
          overrides: [communitySocketProvider.overrideWithValue(client)],
          child: MaterialApp(
            navigatorKey: navigator,
            home: CommunityAppBinding(
              child: CommunityTimelineBinding(
                topic: CommunityTopic.channel(id),
                onUpdate: (_) => updates++,
                onCatchUp: () async {
                  caughtUp++;
                },
                onFailure: (_) {},
                child: const Text('timeline'),
              ),
            ),
          ),
        ),
      );
      await t.pump();
      await t.pump(const Duration(milliseconds: 250));
      expect(
        socket.sent.where((d) => d['type'] == 'channel:join'),
        hasLength(1),
      );
      expect(caughtUp, 1);
      void event(String e, String topic) => socket.incoming.add(
        jsonEncode({
          'type': 'message:created',
          'eventId': e,
          'occurredAt': '2026-01-01T00:00:00Z',
          'data': {
            'id': 'm',
            'channelId': topic,
            'conversationId': null,
            'author': {'id': 'peer', 'username': 'peer', 'displayName': 'Peer'},
            'content': 'Hi',
          },
        }),
      );
      event('e1', id);
      event('e1', id);
      event('e2', '22222222-2222-4222-8222-222222222222');
      await t.pump();
      expect(updates, 1);
      navigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('covered')),
        ),
      );
      await t.pumpAndSettle();
      expect(
        socket.sent.where((d) => d['type'] == 'channel:leave'),
        hasLength(1),
      );
      event('e3', id);
      await t.pump();
      expect(updates, 1);
      navigator.currentState!.pop();
      await t.pumpAndSettle();
      expect(
        socket.sent.where((d) => d['type'] == 'channel:join'),
        hasLength(2),
      );
      await t.pumpWidget(const SizedBox());
      await t.pump();
      await client.dispose();
    },
  );
  testWidgets('a message from someone else rings while the app is in front', (
    t,
  ) async {
    final socket = FakeConnection();
    final client = CommunitySocketClient(connector: () async => socket);
    final rung = <CommunityChime>[];
    final enabled = StateProvider<bool>((ref) => false);
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          communitySocketProvider.overrideWithValue(client),
          sessionStateProvider.overrideWith(
            (ref) => const Session(userId: 'member-1', displayName: 'Lan'),
          ),
          chimeOutputProvider.overrideWithValue((chime) async {
            rung.add(chime);
          }),
          chimesEnabledProvider.overrideWith((ref) => ref.watch(enabled)),
        ],
        child: const MaterialApp(home: CommunityAppBinding(child: Text('app'))),
      ),
    );
    await t.pump();
    void message(String id, {String author = 'peer-1'}) => socket.incoming.add(
      jsonEncode({
        'type': 'dm:message-created',
        'eventId': 'event-$id',
        'occurredAt': '2026-11-10T08:00:00Z',
        'data': {
          'id': id,
          'conversationId': 'conversation-1',
          'authorId': author,
          'content': 'Tiếng Việt: ặ ữ ờ ẫ ệ',
        },
      }),
    );

    message('muted');
    await t.pump();
    ProviderScope.containerOf(t.element(find.text('app')))
            .read(enabled.notifier)
            .state =
        true;
    message('own', author: 'member-1');
    message('peer');
    await t.pump();

    expect(rung, [CommunityChime.message]);
    await t.pumpWidget(const SizedBox());
    await t.pump();
    await client.dispose();
  });
  testWidgets('inactive desktop focus keeps socket; background closes it', (
    t,
  ) async {
    final sockets = <FakeConnection>[];
    final client = CommunitySocketClient(
      connector: () async {
        final s = FakeConnection();
        sockets.add(s);
        return s;
      },
    );
    await t.pumpWidget(
      ProviderScope(
        overrides: [communitySocketProvider.overrideWithValue(client)],
        child: const MaterialApp(home: CommunityAppBinding(child: Text('app'))),
      ),
    );
    await t.pump();
    expect(sockets, hasLength(1));
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await t.pump();
    expect(sockets.single.closed, isFalse);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await t.pump();
    expect(sockets.single.closed, isTrue);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await t.pump();
    expect(sockets, hasLength(2));
    await t.pumpWidget(const SizedBox());
    await t.pump();
    await client.dispose();
  });
}
