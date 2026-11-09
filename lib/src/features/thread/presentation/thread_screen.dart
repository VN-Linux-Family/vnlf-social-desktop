import '../../polls/presentation/poll_card.dart';
import '../../moderation/presentation/report_dialog.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/design_system.dart';
import '../../../app/providers.dart';
import '../../../domain/models.dart';
import '../../feed/presentation/post_mapper.dart';
import '../../shared/presentation/post_share.dart';
import '../../shared/presentation/feature_widgets.dart';
import '../../shared/presentation/post_interactions.dart';
import 'thread_comments.dart';
import 'thread_post_provider.dart';
import 'article_detail_card.dart';

export 'thread_post_provider.dart' show threadPostProvider;

class ThreadScreen extends ConsumerWidget {
  const ThreadScreen({super.key, required this.postId});

  final String postId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final english = Localizations.localeOf(context).languageCode == 'en';
    final post = ref.watch(threadPostProvider(postId));
    final article = post.valueOrNull?.format == 'ARTICLE';
    final mobile =
        VnlfViewportSize.fromWidth(MediaQuery.sizeOf(context).width) ==
        VnlfViewportSize.mobile;
    return ListView(
      padding: const EdgeInsets.only(bottom: 20),
      children: [
        if (!mobile && article)
          Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: article ? 780 : double.infinity,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  alignment: Alignment.centerLeft,
                  child: Tooltip(
                    message: english ? 'Back' : 'Quay lại',
                    child: TextButton.icon(
                      onPressed: () {
                        final router = GoRouter.maybeOf(context);
                        if (router?.canPop() == true) {
                          router!.pop();
                        } else {
                          router?.go('/');
                        }
                      },
                      icon: const Icon(Icons.arrow_back, size: 16),
                      label: Text(
                        english ? 'Back to feed' : 'Quay lại bảng tin',
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (!article && !mobile)
          FeatureHeader(title: english ? 'Thread' : 'Bài viết'),
        SizedBox(height: mobile ? 12 : 10),
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
                      ? 'This content is no longer available; it may have been deleted.'
                      : 'Không tìm thấy nội dung này nữa, có thể đã bị xóa.',
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
    final detail = interaction.apply(summary, english: english);
    final session =
        ref.watch(sessionStateProvider) ??
        ref.watch(sessionProvider).valueOrNull;
    final article = source.format == 'ARTICLE';
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (article)
          ArticleDetailCard(
            poll: source.poll == null
                ? null
                : PollCard(poll: source.poll!, authorId: source.author.id),
            source: source,
            post: detail,
            onAuthor: () => context.push(
              '/profile/${Uri.encodeComponent(source.author.username)}',
            ),
            onComment: _commentFocus.requestFocus,
            onShare: () => copyPostLink(context, source),
            onReport: session?.userId == source.author.id
                ? null
                : () => showArticleReport(context, ref, source.id),
            onEdit: source.canEdit
                ? () =>
                      context.push('/compose/${Uri.encodeComponent(source.id)}')
                : null,
            onVote: (value) => ref
                .read(postInteractionsProvider.notifier)
                .vote(source.id, value),
            onBookmark: () => ref
                .read(postInteractionsProvider.notifier)
                .toggleBookmark(
                  source.id,
                  initialValue: source.viewerBookmarked,
                ),
          )
        else
          VnlfPostCard(
            poll: source.poll == null
                ? null
                : PollCard(poll: source.poll!, authorId: source.author.id),
            post: detail,
            onAuthorTap: () => context.push(
              '/profile/${Uri.encodeComponent(source.author.username)}',
            ),
            onCommentTap: _commentFocus.requestFocus,
            onShareTap: () => copyPostLink(context, source),
            onReportTap: () => showArticleReport(context, ref, source.id),
            shareSemanticLabel: english ? 'Share' : 'Chia sẻ',
            onVoteChanged: (value) => ref
                .read(postInteractionsProvider.notifier)
                .vote(source.id, value),
            onBookmarkToggle: () => ref
                .read(postInteractionsProvider.notifier)
                .toggleBookmark(
                  source.id,
                  initialValue: source.viewerBookmarked,
                ),
            upvoteSemanticLabel: english ? 'Upvote' : 'Ủng hộ',
            downvoteSemanticLabel: english ? 'Downvote' : 'Phản đối',
            commentSemanticLabel: english ? 'Comments' : 'Bình luận',
            bookmarkSemanticLabel: english ? 'Bookmark' : 'Lưu bài viết',
          ),
        const SizedBox(height: 12),
        ThreadComments(postId: source.id, focusNode: _commentFocus),
      ],
    );
    return article
        ? Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 780),
              child: content,
            ),
          )
        : content;
  }
}
