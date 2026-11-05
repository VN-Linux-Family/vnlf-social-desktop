import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/models.dart';
import '../../feed/presentation/post_mapper.dart';
import '../../shared/presentation/post_share.dart';
import '../../shared/presentation/feature_samples.dart';
import '../../shared/presentation/feature_widgets.dart';
import '../../shared/presentation/post_interactions.dart';
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
      padding: const EdgeInsets.only(bottom: 20),
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

class ThreadContent extends ConsumerStatefulWidget {
  const ThreadContent({super.key, required this.post});

  final FeedPost post;

  @override
  ConsumerState<ThreadContent> createState() => _ThreadContentState();
}

class _ThreadContentState extends ConsumerState<ThreadContent> {
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
    final summary = presentPost(source, english: english, fullContent: true);
    final interaction = ref.watch(postInteractionProvider(source.id));
    final detail = interaction.apply(summary);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VnlfPostCard(
          post: detail,
          onAuthorTap: () => context.push(
            '/profile/${Uri.encodeComponent(source.author.username)}',
          ),
          onCommentTap: _commentFocus.requestFocus,
          onShareTap: () => copyPostLink(context, source),
          shareSemanticLabel: english ? 'Share' : 'Chia sẻ',
          onVoteChanged: (value) => ref
              .read(postInteractionsProvider.notifier)
              .vote(source.id, value),
          onBookmarkToggle: () => ref
              .read(postInteractionsProvider.notifier)
              .toggleBookmark(source.id, initialValue: source.viewerBookmarked),
          upvoteSemanticLabel: english ? 'Upvote' : 'Ủng hộ',
          downvoteSemanticLabel: english ? 'Downvote' : 'Phản đối',
          commentSemanticLabel: english ? 'Comments' : 'Bình luận',
          bookmarkSemanticLabel: english ? 'Bookmark' : 'Lưu bài viết',
        ),
        const SizedBox(height: 12),
        ThreadComments(postId: source.id, focusNode: _commentFocus),
      ],
    );
  }
}
