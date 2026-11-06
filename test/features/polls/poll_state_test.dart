import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/app/providers.dart';
import 'package:vnlfsocialapp/src/domain/models.dart';
import 'package:vnlfsocialapp/src/features/polls/data/poll_dto.dart';
import 'package:vnlfsocialapp/src/features/polls/domain/poll_models.dart';
import 'package:vnlfsocialapp/src/features/polls/domain/poll_repository.dart';
import 'package:vnlfsocialapp/src/features/polls/presentation/poll_state.dart';

import 'poll_repository_test.dart' show pollJson, pollId, optionA, optionB;

Poll get original => PollDto(pollJson).toDomain();
Poll get acknowledged =>
    PollDto({...pollJson, 'viewerOptionId': optionB}).toDomain();
void main() {
  test('votes are single-flight and failed confirmation preserves selection and counts', () async {
    final repo = ControlledPollRepository();
    final store = PollStore(repo, ownerId: 'one', activeOwnerId: () => 'one');
    addTearDown(store.dispose);
    final attempt = store.vote(original, optionB);
    expect(await store.vote(original, null), isFalse);
    expect(repo.votes, 1);
    expect(store.state[pollId]!.poll.viewerOptionId, optionA);
    repo.pending.completeError(const TransportFailure());
    expect(await attempt, isFalse);
    expect(store.state[pollId]!.poll.totalVotes, 3);
    expect(store.state[pollId]!.poll.viewerOptionId, optionA);
    expect(store.state[pollId]!.failure, isA<TransportFailure>());
    repo.pending = Completer<Poll>();
    final retry = store.vote(original, optionB);
    repo.pending.complete(acknowledged);
    expect(await retry, isTrue);
    expect(store.state[pollId]!.poll.viewerOptionId, optionB);
    expect(store.state[pollId]!.failure, isNull);
  });
  test('reads captured before or during a vote cannot overwrite its acknowledgment', () async {
    final repo = ControlledPollRepository();
    final store = PollStore(repo, ownerId: 'one', activeOwnerId: () => 'one');
    addTearDown(store.dispose);
    final old = store.beginRead();
    final attempt = store.vote(original, optionB);
    final during = store.beginRead();
    repo.pending.complete(acknowledged);
    await attempt;
    old.accept(original);
    during.accept(original);
    expect(store.state[pollId]!.poll.viewerOptionId, optionB);
    final fresh = store.beginRead();
    fresh.accept(original);
    expect(store.state[pollId]!.poll.viewerOptionId, optionA);
  });
  test('an older history response cannot replace a newer read snapshot', () {
    final store = PollStore(
      ControlledPollRepository(),
      ownerId: 'one',
      activeOwnerId: () => 'one',
    );
    addTearDown(store.dispose);
    final older = store.beginRead();
    final newer = store.beginRead();
    newer.accept(acknowledged);
    older.accept(original);
    expect(store.state[pollId]!.poll.viewerOptionId, optionB);
  });
  test('changing account resets poll state and ignores the old pending acknowledgment', () async {
    final repo = ControlledPollRepository();
    final container = ProviderContainer(
      overrides: [
        pollRepositoryProvider.overrideWithValue(repo),
        sessionStateProvider.overrideWith(
          (ref) => const Session(userId: 'one', displayName: 'Một'),
        ),
      ],
    );
    addTearDown(container.dispose);
    final sub = container.listen(pollStoreProvider, (_, _) {});
    addTearDown(sub.close);
    final attempt = container
        .read(pollStoreProvider.notifier)
        .vote(original, optionB);
    container.read(sessionStateProvider.notifier).state = const Session(
      userId: 'two',
      displayName: 'Hai',
    );
    expect(container.read(pollStoreProvider), isEmpty);
    repo.pending.complete(acknowledged);
    expect(await attempt, isFalse);
    expect(container.read(pollStoreProvider), isEmpty);
  });
  test('peer poll updates preserve this viewer selection and never inherit a peer choice on a cold cache', () {
    final store = PollStore(
      ControlledPollRepository(),
      ownerId: 'one',
      activeOwnerId: () => 'one',
    );
    addTearDown(store.dispose);
    store.ingestRealtime(acknowledged);
    expect(store.state[pollId]!.poll.viewerOptionId, isNull);
    store.beginRead().accept(original);
    store.ingestRealtime(acknowledged);
    expect(store.state[pollId]!.poll.viewerOptionId, optionA);
  });
}

class ControlledPollRepository implements PollRepository {
  Completer<Poll> pending = Completer<Poll>();
  int votes = 0, edits = 0;
  @override
  Future<Poll> vote(String pollId, String? optionId) {
    votes++;
    return pending.future;
  }

  @override
  Future<Poll> edit(String pollId, PollInput input) {
    edits++;
    return pending.future;
  }

  @override
  Future<Poll?> setDraftPoll(String articleId, PollInput? input) =>
      throw StateError('Draft poll writes are outside this test');
}
