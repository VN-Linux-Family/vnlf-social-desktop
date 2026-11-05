import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/app/providers.dart';
import 'package:vnlfsocialapp/src/design_system/design_system.dart';
import 'package:vnlfsocialapp/src/domain/models.dart';
import 'package:vnlfsocialapp/src/features/shared/domain/post_actions.dart';
import 'package:vnlfsocialapp/src/features/shared/presentation/post_interactions.dart';

void main() {
  test('overlapping bookmark clicks cannot toggle the server twice', () async {
    final actions = ControlledActions();
    final container = ProviderContainer(
      overrides: [postActionsRepositoryProvider.overrideWithValue(actions)],
    );
    addTearDown(container.dispose);
    final notifier = container.read(postInteractionsProvider.notifier);
    final first = notifier.toggleBookmark('post', initialValue: false);
    final second = notifier.toggleBookmark('post', initialValue: false);
    expect(actions.bookmarkCalls, 1);
    actions.bookmark.complete();
    await Future.wait([first, second]);
    expect(container.read(postInteractionProvider('post')).bookmarked, isTrue);
  });
  test('failed vote restores the prior vote and exposes the failure', () async {
    final actions = ControlledActions();
    final container = ProviderContainer(
      overrides: [postActionsRepositoryProvider.overrideWithValue(actions)],
    );
    addTearDown(container.dispose);
    final pending = container
        .read(postInteractionsProvider.notifier)
        .vote('post', VoteState.upvoted);
    actions.vote.completeError(const HttpFailure(401));
    await pending;
    final state = container.read(postInteractionProvider('post'));
    expect(state.vote, isNull);
    expect(state.failure, isA<HttpFailure>());
  });
  test('a pending mutation cannot restore a previous account state', () async {
    final actions = ControlledActions();
    final container = ProviderContainer(
      overrides: [postActionsRepositoryProvider.overrideWithValue(actions)],
    );
    addTearDown(container.dispose);
    final pending = container
        .read(postInteractionsProvider.notifier)
        .vote('post', VoteState.upvoted);
    container.read(sessionStateProvider.notifier).state = const Session(
      userId: 'next',
      displayName: 'Next',
    );
    expect(container.read(postInteractionProvider('post')).vote, isNull);
    actions.vote.complete(1);
    await pending;
    expect(container.read(postInteractionProvider('post')).vote, isNull);
  });
}

class ControlledActions implements PostActionsRepository {
  final vote = Completer<int>();
  final bookmark = Completer<void>();
  int bookmarkCalls = 0;
  @override
  Future<int> setVote(String id, int value) => vote.future;
  @override
  Future<void> toggleBookmark(String id) {
    bookmarkCalls++;
    return bookmark.future;
  }
}
