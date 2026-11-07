import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../domain/models.dart';
import '../data/live_poll_repository.dart';
import '../domain/poll_models.dart';
import '../domain/poll_repository.dart';

final pollRepositoryProvider = Provider<PollRepository>(
  (ref) => LivePollRepository(ref.watch(apiClientProvider)),
);
final pollStoreProvider =
    StateNotifierProvider<PollStore, Map<String, PollState>>((ref) {
      final owner = ref.watch(
        sessionStateProvider.select((session) => session?.userId),
      );
      return PollStore(
        ref.watch(pollRepositoryProvider),
        ownerId: owner,
        activeOwnerId: () => ref.read(sessionStateProvider)?.userId,
      );
    });

final class PollState {
  const PollState({required this.poll, this.pending = false, this.failure});
  final Poll poll;
  final bool pending;
  final AppFailure? failure;
}

/// Capture before a parent history request and apply only that request's polls.
final class PollReadTicket {
  const PollReadTicket._(this._store, this._serial);
  final PollStore _store;
  final int _serial;
  void accept(Poll? poll) => acceptAll([poll]);
  void acceptAll(Iterable<Poll?> polls) => _store._ingest(polls, _serial);
}

class PollStore extends StateNotifier<Map<String, PollState>> {
  PollStore(
    this._repository, {
    required this._ownerId,
    required this._activeOwnerId,
  }) : super(const {});
  final PollRepository _repository;
  final String? _ownerId;
  final String? Function() _activeOwnerId;
  final _versions = <String, int>{};
  int _clock = 0;
  bool get _current => mounted && _activeOwnerId() == _ownerId;

  PollReadTicket beginRead() => PollReadTicket._(this, ++_clock);

  void _ingest(Iterable<Poll?> polls, int serial) {
    if (!_current) return;
    final next = {...state};
    var changed = false;
    for (final poll in polls) {
      if (poll == null ||
          next[poll.id]?.pending == true ||
          serial < (_versions[poll.id] ?? 0)) {
        continue;
      }
      _versions[poll.id] = serial;
      next[poll.id] = PollState(poll: poll);
      changed = true;
    }
    if (changed) state = Map.unmodifiable(next);
  }

  Future<bool> vote(Poll source, String? optionId) =>
      _mutate(source, () => _repository.vote(source.id, optionId));
  Future<bool> edit(Poll source, PollInput input) =>
      _mutate(source, () => _repository.edit(source.id, input));

  Future<bool> _mutate(Poll source, Future<Poll> Function() operation) async {
    if (!_current ||
        _ownerId == null ||
        _ownerId.isEmpty ||
        state[source.id]?.pending == true) {
      return false;
    }
    final before = state[source.id]?.poll ?? source;
    _versions[source.id] = ++_clock;
    state = Map.unmodifiable({
      ...state,
      source.id: PollState(poll: before, pending: true),
    });
    try {
      final confirmed = await operation();
      if (!_current) return false;
      _versions[source.id] = ++_clock;
      state = Map.unmodifiable({
        ...state,
        source.id: PollState(poll: confirmed),
      });
      return true;
    } catch (error) {
      if (_current) {
        _versions[source.id] = ++_clock;
        state = Map.unmodifiable({
          ...state,
          source.id: PollState(
            poll: before,
            failure: error is AppFailure ? error : const TransportFailure(),
          ),
        });
      }
      return false;
    }
  }

  void ingestRealtime(Poll incoming, {bool preserveViewerSelection = true}) {
    if (!_current || state[incoming.id]?.pending == true) return;
    final ownSelection = state[incoming.id]?.poll.viewerOptionId;
    final next = preserveViewerSelection
        ? incoming.withViewerSelection(ownSelection)
        : incoming;
    _versions[incoming.id] = ++_clock;
    state = Map.unmodifiable({...state, incoming.id: PollState(poll: next)});
  }
}
