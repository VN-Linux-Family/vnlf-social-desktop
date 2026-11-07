import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/app/providers.dart';
import 'package:vnlfsocialapp/src/domain/models.dart';
import 'package:vnlfsocialapp/src/design_system/tokens/vnlf_theme.dart';
import 'package:vnlfsocialapp/src/features/direct_messages/domain/direct_message_models.dart';
import 'package:vnlfsocialapp/src/features/direct_messages/presentation/direct_message_state.dart';
import 'package:vnlfsocialapp/src/features/direct_messages/presentation/direct_messages_screen.dart';
import 'package:vnlfsocialapp/src/features/realtime/data/community_socket_client.dart';
import 'package:vnlfsocialapp/src/features/realtime/presentation/community_realtime_providers.dart';

import '../direct_messages/direct_message_controller_test.dart'
    show ControlledDmRepository;
import 'community_provider_test.dart' show FakeConnection;

const conversation = '22222222-2222-4222-8222-222222222222';
void main() {
  testWidgets(
    'native DM route renders incoming edits/reactions/deletion without manual refresh',
    (t) async {
      final socket = FakeConnection();
      final client = CommunitySocketClient(connector: () async => socket);
      final repo = ControlledDmRepository()
        ..conversation = const DmConversation(
          id: conversation,
          canSend: true,
          peer: DmPeer(id: 'peer', username: 'peer', displayName: 'Peer'),
        );
      final container = ProviderContainer(
        overrides: [
          communitySocketProvider.overrideWithValue(client),
          directMessageRepositoryProvider.overrideWithValue(repo),
          sessionStateProvider.overrideWith(
            (_) => const Session(
              userId: 'owner',
              displayName: 'Owner',
              role: 'MEMBER',
            ),
          ),
        ],
      );
      await t.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            locale: const Locale('vi'),
            supportedLocales: const [Locale('vi'), Locale('en')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            theme: VnlfTheme.light(),
            home: const Scaffold(
              body: DirectMessagesScreen(conversationId: conversation),
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      void event(String type, String id, Map<String, Object?> data) =>
          socket.incoming.add(
            jsonEncode({
              'type': type,
              'eventId': id,
              'occurredAt': '2026-01-01T00:00:00Z',
              'data': data,
            }),
          );
      Map<String, Object?> message(String content) => {
        'id': 'm',
        'channelId': null,
        'conversationId': conversation,
        'authorId': 'peer',
        'author': {'id': 'peer', 'username': 'peer', 'displayName': 'Peer'},
        'content': content,
        'createdAt': '2026-01-01T00:00:00Z',
      };
      event('dm:message-created', 'e1', message('Tiếng Việt: ặ ữ ờ ẫ ệ'));
      await t.pumpAndSettle();
      expect(find.text('Tiếng Việt: ặ ữ ờ ẫ ệ'), findsOneWidget);
      event('dm:message-updated', 'e2', message('Đã cập nhật trực tiếp'));
      await t.pumpAndSettle();
      expect(find.text('Đã cập nhật trực tiếp'), findsOneWidget);
      expect(find.text('Tiếng Việt: ặ ữ ờ ẫ ệ'), findsNothing);
      event('reaction:changed', 'e3', {
        'messageId': 'm',
        'channelId': null,
        'conversationId': conversation,
        'reactions': [
          {'emoji': '👍', 'count': 2, 'viewerReacted': true},
        ],
      });
      await t.pumpAndSettle();
      final reaction = container
          .read(dmTimelineProvider(conversation))
          .messages
          .single
          .reactions
          .single;
      expect(reaction.count, 2);
      expect(reaction.viewerReacted, isFalse);
      expect(find.text('👍 2'), findsOneWidget);
      event('dm:message-deleted', 'e4', {
        'messageId': 'm',
        'channelId': null,
        'conversationId': conversation,
      });
      await t.pumpAndSettle();
      expect(find.text('Đã cập nhật trực tiếp'), findsNothing);
      await t.pumpWidget(const SizedBox());
      await t.pump();
      container.dispose();
      await client.dispose();
    },
  );
}
