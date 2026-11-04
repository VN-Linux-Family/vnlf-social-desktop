import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/models.dart';
import '../../feed/presentation/post_mapper.dart';
import '../../shared/presentation/feature_samples.dart';
import '../../shared/presentation/feature_widgets.dart';
import 'thread_comments.dart';

final threadPostProvider = FutureProvider.autoDispose.family<FeedPost?, String>(
  (ref, id) async =>
      await ref.watch(postRepositoryProvider).getPost(id) ??
      (offlineFeatures ? samplePost : null),
);

class ThreadScreen extends ConsumerWidget {
  const ThreadScreen({super.key, required this.postId});

  final String postId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final english = Localizations.localeOf(context).languageCode == 'en';
    final post = ref.watch(threadPostProvider(postId));
    return ListView(
      children: [
        FeatureHeader(title: english ? 'Thread' : 'Bài viết'),
        const SizedBox(height: 12),
        post.when(
          loading: () =>
              const VnlfLoadingShimmer(child: VnlfPostCard.loading()),
          error: (error, stack) => FeatureLoadError(
            onRetry: () => ref.invalidate(threadPostProvider(postId)),
          ),
          data: (value) => value == null
              ? VnlfStateCard(
                  icon: Icons.article_outlined,
                  title: english
                      ? 'Post unavailable'
                      : 'Không tìm thấy bài viết',
                  message: english
                      ? 'This post is not in the loaded feed.'
                      : 'Bài viết không có trong bảng tin đã tải.',
                )
              : ThreadContent(
                  key: ValueKey('$postId/${value.id}'),
                  post: value,
                ),
        ),
      ],
    );
  }
}

class ThreadContent extends StatefulWidget {
  const ThreadContent({super.key, required this.post});

  final FeedPost post;

  @override
  State<ThreadContent> createState() => _ThreadContentState();
}

class _ThreadContentState extends State<ThreadContent> {
  VoteState? _vote;
  bool? _bookmarked;
  final _commentFocus = FocusNode();

  @override
  void dispose() {
    _commentFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final english = Localizations.localeOf(context).languageCode == 'en';
    final source = widget.post;
    final summary = presentPost(source, english: english);
    final vote = _vote ?? summary.viewerVote;
    final detail = PostData(
      id: source.id,
      author: summary.author,
      relativeTime: summary.relativeTime,
      title: source.title,
      paragraphs:
          (source.contentText.isEmpty ? source.excerpt : source.contentText)
              .split('\n\n'),
      tags: source.tags,
      voteScore: source.voteScore + vote.value - summary.viewerVote.value,
      viewerVote: vote,
      isBookmarked: _bookmarked ?? source.viewerBookmarked,
      commentCount: source.commentCount,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (source.id == samplePost.id) ...[
          Text(english ? 'Sample article' : 'Bài viết mẫu'),
          const SizedBox(height: 8),
        ],
        if (source.publishedAt case final date?) ...[
          Text(date.toLocal().toIso8601String().split('T').first),
          const SizedBox(height: 8),
        ],
        VnlfPostCard(
          post: detail,
          onAuthorTap: () => context.push(
            '/profile/${Uri.encodeComponent(source.author.username)}',
          ),
          onCommentTap: _commentFocus.requestFocus,
          onVoteChanged: offlineFeatures
              ? (value) => setState(() => _vote = value)
              : null,
          onBookmarkToggle: offlineFeatures
              ? () => setState(() => _bookmarked = !detail.isBookmarked)
              : null,
          upvoteSemanticLabel: english ? 'Upvote' : 'Ủng hộ',
          downvoteSemanticLabel: english ? 'Downvote' : 'Phản đối',
          commentSemanticLabel: english ? 'Comments' : 'Bình luận',
          bookmarkSemanticLabel: english ? 'Bookmark' : 'Lưu bài viết',
        ),
        const SizedBox(height: 12),
        ThreadComments(focusNode: _commentFocus),
      ],
    );
  }
}
