import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../design_system/design_system.dart';
import 'feature_samples.dart';

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

  Future<void> vote(String postId, VoteState value) async {
    final previous = state[postId];
    final previousVote = previous?.vote;

    // Optimistic local state update
    state = {
      ...state,
      postId: PostInteraction(vote: value, bookmarked: previous?.bookmarked),
    };

    if (offlineFeatures ||
        postId.isEmpty ||
        postId.startsWith('local-') ||
        postId.startsWith('fixture-')) {
      return;
    }

    try {
      final client = ref.read(apiClientProvider);
      await client.request<Map<String, dynamic>>(
        'PUT',
        '/api/v1/articles/$postId/vote',
        body: jsonEncode({'value': value.value}),
        decode: (json) => json,
      );
    } catch (_) {
      // Rollback to previous vote if server request fails
      state = {
        ...state,
        postId: PostInteraction(
          vote: previousVote,
          bookmarked: state[postId]?.bookmarked,
        ),
      };
    }
  }

  Future<void> toggleBookmark(
    String postId, {
    required bool initialValue,
  }) async {
    final current = state[postId];
    final currentBookmarked = current?.bookmarked ?? initialValue;
    final nextBookmarked = !currentBookmarked;

    // Optimistic local state update
    state = {
      ...state,
      postId: PostInteraction(vote: current?.vote, bookmarked: nextBookmarked),
    };

    if (offlineFeatures ||
        postId.isEmpty ||
        postId.startsWith('local-') ||
        postId.startsWith('fixture-')) {
      return;
    }

    try {
      final client = ref.read(apiClientProvider);
      await client.request<Map<String, dynamic>>(
        'POST',
        '/api/v1/articles/$postId/bookmark',
        decode: (json) => json,
      );
    } catch (_) {
      // Rollback to previous bookmark state if server request fails
      state = {
        ...state,
        postId: PostInteraction(
          vote: state[postId]?.vote,
          bookmarked: currentBookmarked,
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
