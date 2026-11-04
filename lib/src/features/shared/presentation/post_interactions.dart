import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/design_system.dart';

/// Session-local reactions shared by every presentation of a post.
final postInteractionsProvider =
    NotifierProvider<PostInteractions, Map<String, PostInteraction>>(
      PostInteractions.new,
    );

class PostInteraction {
  const PostInteraction({this.vote, this.bookmarked});

  final VoteState? vote;
  final bool? bookmarked;

  PostData apply(PostData source) => source.copyWith(
    viewerVote: vote,
    voteScore:
        source.voteScore +
        (vote ?? source.viewerVote).value -
        source.viewerVote.value,
    isBookmarked: bookmarked,
  );
}

class PostInteractions extends Notifier<Map<String, PostInteraction>> {
  @override
  Map<String, PostInteraction> build() => const {};

  void vote(String postId, VoteState value) {
    state = {
      ...state,
      postId: PostInteraction(
        vote: value,
        bookmarked: state[postId]?.bookmarked,
      ),
    };
  }

  void toggleBookmark(String postId, {required bool initialValue}) {
    final current = state[postId];
    state = {
      ...state,
      postId: PostInteraction(
        vote: current?.vote,
        bookmarked: !(current?.bookmarked ?? initialValue),
      ),
    };
  }
}

final postInteractionProvider = Provider.family<PostInteraction, String>(
  (ref, id) =>
      ref.watch(postInteractionsProvider.select((state) => state[id])) ??
      const PostInteraction(),
);
