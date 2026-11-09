import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/app/app_router.dart';
import 'package:vnlfsocialapp/src/app/providers.dart';
import 'package:vnlfsocialapp/src/data/feed_dto.dart';
import 'package:vnlfsocialapp/src/design_system/design_system.dart';
import 'package:vnlfsocialapp/src/domain/models.dart';
import 'package:vnlfsocialapp/src/domain/repositories.dart';
import 'package:vnlfsocialapp/src/features/channels/data/channel_dto.dart';
import 'package:vnlfsocialapp/src/features/channels/presentation/live_message_tile.dart';
import 'package:vnlfsocialapp/src/features/direct_messages/data/direct_message_dto.dart';
import 'package:vnlfsocialapp/src/features/direct_messages/presentation/direct_message_tile.dart';
import 'package:vnlfsocialapp/src/features/polls/data/poll_dto.dart';
import 'package:vnlfsocialapp/src/features/polls/presentation/poll_card.dart';
import 'package:vnlfsocialapp/src/features/polls/presentation/poll_state.dart';

import 'poll_repository_test.dart' show pollJson, pollId, optionA;
import 'poll_state_test.dart' show ControlledPollRepository;

void main() {
  testWidgets(
    'channel and DM messages render shared choices and reconcile one acknowledged vote',
    (tester) async {
      final repo = ControlledPollRepository();
      final raw = <String, dynamic>{
        'id': 'message-1',
        'authorId': 'peer',
        'author': {'id': 'peer', 'username': 'ban', 'displayName': 'Bạn'},
        'content': 'Thảo luận',
        'poll': pollJson,
      };
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sessionStateProvider.overrideWith(
              (ref) => const Session(userId: 'one', displayName: 'Một'),
            ),
            pollRepositoryProvider.overrideWithValue(repo),
          ],
          child: MaterialApp(
            theme: VnlfTheme.light(),
            home: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    LiveMessageTile(
                      message: ChannelMessageDto(raw).toDomain(),
                      own: false,
                      canAct: true,
                      busy: false,
                      onReply: () {},
                      onEdit: () {},
                      onDelete: () {},
                      onReact: (_) {},
                    ),
                    DirectMessageTile(
                      message: DmMessageDto(raw).toDomain(),
                      own: false,
                      canAct: true,
                      busy: false,
                      onReply: () {},
                      onEdit: () {},
                      onDelete: () {},
                      onReact: (_) {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(PollCard), findsNWidgets(2));
      expect(find.text('Bạn dùng Linux nào?'), findsNWidgets(2));
      expect(find.text('Message contains a poll'), findsNothing);
      await tester.tap(
        find.byKey(const Key('poll-choice-$pollId-$optionA')).first,
      );
      await tester.pump();
      expect(repo.votes, 1);
      for (final button in tester.widgetList<TextButton>(
        find.byKey(const Key('poll-choice-$pollId-$optionA')),
      )) {
        expect(button.onPressed, isNull);
      }
      repo.pending.complete(
        PollDto({...pollJson, 'viewerOptionId': null}).toDomain(),
      );
      await tester.pumpAndSettle();
      expect(find.text('67%'), findsNothing);
      expect(find.text('33%'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'feed and article detail show actual polls from the same typed source contract',
    (tester) async {
      final content = _Content();
      final repo = ControlledPollRepository();
      const owner = Session(userId: 'one', displayName: 'Một');
      final router = createMainRouter();
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sessionStateProvider.overrideWith((ref) => owner),
            sessionProvider.overrideWithValue(const AsyncData(owner)),
            feedRepositoryProvider.overrideWithValue(content),
            postRepositoryProvider.overrideWithValue(content),
            pollRepositoryProvider.overrideWithValue(repo),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            theme: VnlfTheme.light(),
            locale: const Locale('vi'),
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            supportedLocales: const [Locale('vi')],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(PollCard), findsOneWidget);
      await tester.tap(find.byKey(const Key('poll-choice-$pollId-$optionA')));
      await tester.pump();
      content.post = FeedPostDto.fromJson({..._rawPost, 'poll': pollJson})
          .toDomain();
      repo.pending.complete(PollDto(pollJson).toDomain());
      await tester.pumpAndSettle();
      expect(find.text('67%'), findsOneWidget);
      content.post = FeedPostDto.fromJson({
        ..._rawPost,
        'poll': {
          ...pollJson,
          'totalVotes': 4,
          'options': [
            {
              ...(pollJson['options'] as List<dynamic>)[0]
                  as Map<String, dynamic>,
              'votes': 3,
            },
            {
              ...(pollJson['options'] as List<dynamic>)[1]
                  as Map<String, dynamic>,
              'votes': 1,
            },
          ],
        },
      }).toDomain();
      router.go('/thread/post-with-poll');
      await tester.pumpAndSettle();
      expect(find.byType(PollCard), findsOneWidget);
      expect(find.text('75%'), findsOneWidget);
      expect(find.text('Bạn dùng Linux nào?'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

final _rawPost = <String, dynamic>{
  'id': 'post-with-poll',
  'author': {'id': 'peer', 'username': 'ban', 'displayName': 'Bạn'},
  'excerpt': 'Cuộc trao đổi kiểm thử',
  'contentText': 'Cuộc trao đổi kiểm thử',
  'format': 'POST',
  'status': 'PUBLISHED',
  'poll': {...pollJson, 'viewerOptionId': null},
};

class _Content implements FeedRepository, PostRepository {
  FeedPost post = FeedPostDto.fromJson(_rawPost).toDomain();
  @override
  Future<FeedPage> getFeed({
    String? type,
    String? cursor,
    bool refresh = false,
  }) async => FeedPage(items: [post]);
  @override
  Future<FeedPost?> getPost(String id) async => post;
}
