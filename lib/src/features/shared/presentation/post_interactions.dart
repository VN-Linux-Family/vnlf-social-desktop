import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/models.dart';
import '../../feed/presentation/feed_notifier.dart';
import '../../thread/presentation/thread_post_provider.dart';
import '../data/post_actions_repository.dart';
import '../domain/post_actions.dart';
import 'feature_samples.dart';

final postActionsRepositoryProvider = Provider<PostActionsRepository>(
  (ref) => offlineFeatures
      ? FixturePostActionsRepository()
      : LivePostActionsRepository(
          ref.watch(apiClientProvider),
          hasSession: () => ref.read(sessionStateProvider) != null,
        ),
);

final postInteractionsProvider =
    NotifierProvider<PostInteractions, Map<String, PostInteraction>>(
      PostInteractions.new,
    );

class PostInteraction {
  const PostInteraction({
    this.vote,
    this.bookmarked,
    this.pending = false,
    this.failure,
  });
  final VoteState? vote;
  final bool? bookmarked;
  final bool pending;
  final AppFailure? failure;

  PostData apply(PostData source, {bool english = false}) => source.copyWith(
    viewerVote: vote,
    voteScore:
        source.voteScore +
        (vote ?? source.viewerVote).value -
        source.viewerVote.value,
    isBookmarked: bookmarked,
    actionPending: pending,
    actionError: failure == null
        ? null
        : failure is HttpFailure &&
              [401, 403].contains((failure as HttpFailure).statusCode)
        ? (english
              ? 'Sign in to save this change.'
              : 'Vui lòng đăng nhập để lưu thay đổi.')
        : (english
              ? 'Change could not be saved. Please try again.'
              : 'Không lưu được thay đổi. Vui lòng thử lại.'),
  );
}

class PostInteractions extends Notifier<Map<String, PostInteraction>> {
  int _generation = 0;
  @override
  Map<String, PostInteraction> build() {
    ref.watch(sessionStateProvider.select((session) => session?.userId));
    _generation++;
    ref.onDispose(() => _generation++);
    return const {};
  }

  bool _current(int generation) => generation == _generation;
  void _refresh(String id) {
    ref.invalidate(feedNotifierProvider);
    ref.invalidate(feedProvider);
    ref.invalidate(threadPostProvider(id));
  }

  Future<void> vote(String id, VoteState value) async {
    final previous = state[id] ?? const PostInteraction();
    if (previous.pending || id.isEmpty) return;
    final generation = _generation;
    state = {
      ...state,
      id: PostInteraction(
        vote: value,
        bookmarked: previous.bookmarked,
        pending: true,
      ),
    };
    try {
      final result = await ref
          .read(postActionsRepositoryProvider)
          .setVote(id, value.value);
      if (!_current(generation)) return;
      state = {
        ...state,
        id: PostInteraction(
          vote: switch (result) {
            1 => VoteState.upvoted,
            -1 => VoteState.downvoted,
            _ => VoteState.neutral,
          },
          bookmarked: previous.bookmarked,
        ),
      };
      _refresh(id);
    } catch (error) {
      if (!_current(generation)) return;
      state = {
        ...state,
        id: PostInteraction(
          vote: previous.vote,
          bookmarked: previous.bookmarked,
          failure: error is AppFailure ? error : const TransportFailure(),
        ),
      };
    }
  }

  Future<void> toggleBookmark(String id, {required bool initialValue}) async {
    final previous = state[id] ?? const PostInteraction();
    if (previous.pending || id.isEmpty) return;
    final generation = _generation;
    final next = !(previous.bookmarked ?? initialValue);
    state = {
      ...state,
      id: PostInteraction(vote: previous.vote, bookmarked: next, pending: true),
    };
    try {
      await ref.read(postActionsRepositoryProvider).toggleBookmark(id);
      if (!_current(generation)) return;
      state = {
        ...state,
        id: PostInteraction(vote: previous.vote, bookmarked: next),
      };
      _refresh(id);
    } catch (error) {
      if (!_current(generation)) return;
      state = {
        ...state,
        id: PostInteraction(
          vote: previous.vote,
          bookmarked: previous.bookmarked,
          failure: error is AppFailure ? error : const TransportFailure(),
        ),
      };
    }
  }
}

final postInteractionProvider = Provider.family<PostInteraction, String>(
  (ref, id) =>
      ref.watch(postInteractionsProvider.select((state) => state[id])) ??
      const PostInteraction(),
);
