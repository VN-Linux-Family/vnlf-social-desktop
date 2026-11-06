import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vnlfsocialapp/l10n/app_localizations.dart';
import 'package:vnlfsocialapp/src/app/providers.dart';
import 'package:vnlfsocialapp/src/design_system/design_system.dart';
import 'package:vnlfsocialapp/src/domain/models.dart';
import 'package:vnlfsocialapp/src/features/polls/data/poll_dto.dart';
import 'package:vnlfsocialapp/src/features/polls/domain/poll_models.dart';
import 'package:vnlfsocialapp/src/features/polls/presentation/poll_card.dart';
import 'package:vnlfsocialapp/src/features/polls/presentation/poll_state.dart';

import 'poll_repository_test.dart' show pollJson, pollId, optionA;
import 'poll_state_test.dart' show ControlledPollRepository;

void main() {
  testWidgets(
    'counts appear only after acknowledgment and clicking the selected choice unvotes',
    (tester) async {
      final repo = _Repository();
      await _pump(tester, repo);
      expect(find.text('67%'), findsNothing);
      await tester.tap(find.byKey(const Key('poll-choice-$pollId-$optionA')));
      await tester.pump();
      expect(repo.choices, [optionA]);
      expect(find.text('67%'), findsNothing);
      repo.pending.complete(PollDto(pollJson).toDomain());
      await tester.pumpAndSettle();
      expect(find.text('67%'), findsOneWidget);
      expect(find.text('33%'), findsOneWidget);
      repo.pending = Completer<Poll>();
      await tester.tap(find.byKey(const Key('poll-choice-$pollId-$optionA')));
      await tester.pump();
      expect(repo.choices, [optionA, null]);
      repo.pending.completeError(const TransportFailure());
      await tester.pumpAndSettle();
      expect(find.text('67%'), findsOneWidget);
      expect(find.byKey(const Key('poll-error-$pollId')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('guest choice opens sign-in without submitting a vote', (
    tester,
  ) async {
    final repo = _Repository();
    final (_, router) = await _pump(tester, repo, owner: null);
    await tester.tap(find.byKey(const Key('poll-choice-$pollId-$optionA')));
    await tester.pumpAndSettle();
    expect(find.text('Đăng nhập'), findsOneWidget);
    expect(router.canPop(), isTrue);
    expect(repo.votes, 0);
  });
  testWidgets(
    'author poll editing keeps invalid input local and updates only after server acknowledgment',
    (tester) async {
      final repo = _Repository();
      await _pump(tester, repo, source: _zeroPoll, authorId: 'one');
      await tester.tap(find.byKey(const Key('poll-edit-$pollId')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('poll-edit-question')),
        'Câu hỏi mới',
      );
      await tester.enterText(
        find.byKey(const Key('poll-edit-option-1')),
        'Arch',
      );
      await tester.tap(find.byKey(const Key('poll-edit-save')));
      await tester.pumpAndSettle();
      expect(repo.edits, 0);
      expect(find.byKey(const Key('poll-edit-validation')), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('poll-edit-option-1')),
        'Fedora',
      );
      await tester.tap(find.byKey(const Key('poll-edit-save')));
      await tester.pump();
      expect(repo.edits, 1);
      repo.pending.complete(
        Poll(
          id: pollId,
          question: 'Câu hỏi mới',
          options: [
            PollOption(id: optionA, label: 'Arch', votes: 0),
            const PollOption(id: 'new-option', label: 'Fedora', votes: 0),
          ],
          totalVotes: 0,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('poll-edit-question')), findsNothing);
      expect(find.text('Câu hỏi mới'), findsOneWidget);
      expect(find.text('Fedora'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'native poll input uses UTF-16 limits without breaking emoji or hiding the actual count',
    (tester) async {
      final repo = _Repository();
      await _pump(tester, repo, source: _zeroPoll, authorId: 'one');
      await tester.tap(find.byKey(const Key('poll-edit-$pollId')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('poll-edit-question')),
        '😀' * 101,
      );
      await tester.pump();
      final text = tester
          .widget<TextField>(find.byKey(const Key('poll-edit-question')))
          .controller!
          .text;
      expect(text.length, 200);
      expect(text.runes.length, 100);
      expect(find.text('200/200'), findsOneWidget);
      expect(repo.edits, 0);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'account changes close an author edit and never expose that control to another account',
    (tester) async {
      final repo = _Repository();
      final (container, _) = await _pump(
        tester,
        repo,
        source: _zeroPoll,
        authorId: 'one',
      );
      await tester.tap(find.byKey(const Key('poll-edit-$pollId')));
      await tester.pumpAndSettle();
      container.read(sessionStateProvider.notifier).state = const Session(
        userId: 'two',
        displayName: 'Hai',
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('poll-edit-question')), findsNothing);
      expect(find.byKey(const Key('poll-edit-$pollId')), findsNothing);
      expect(repo.edits, 0);
      expect(tester.takeException(), isNull);
    },
  );
}

Poll get _zeroPoll => PollDto({
  ...pollJson,
  'totalVotes': 0,
  'viewerOptionId': null,
  'options': [
    (pollJson['options'] as List<dynamic>)[0] as Map<String, dynamic>,
    (pollJson['options'] as List<dynamic>)[1] as Map<String, dynamic>,
  ].map((option) => {...option, 'votes': 0}).toList(),
}).toDomain();

class _Repository extends ControlledPollRepository {
  final choices = <String?>[];
  @override
  Future<Poll> vote(String id, String? option) {
    choices.add(option);
    return super.vote(id, option);
  }
}

Future<(ProviderContainer, GoRouter)> _pump(
  WidgetTester tester,
  _Repository repo, {
  String? owner = 'one',
  Poll? source,
  String authorId = 'other',
}) async {
  tester.view.physicalSize = const Size(390, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final container = ProviderContainer(
    overrides: [
      pollRepositoryProvider.overrideWithValue(repo),
      sessionStateProvider.overrideWith(
        (ref) =>
            owner == null ? null : Session(userId: owner, displayName: 'Một'),
      ),
    ],
  );
  addTearDown(container.dispose);
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: SingleChildScrollView(
            child: PollCard(
              poll:
                  source ??
                  PollDto(pollJson).toDomain().withViewerSelection(null),
              authorId: authorId,
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const Scaffold(body: Text('Đăng nhập')),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
        theme: VnlfTheme.light(),
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (container, router);
}
