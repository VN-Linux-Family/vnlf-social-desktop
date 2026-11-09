import '../../../i18n/vi.dart';
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
                    message: vi.app.common.quayLai,
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
                      label: Text(vi.miscViews.quayLaiBangTin),
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (!article && !mobile) FeatureHeader(title: vi.common.baiViet),
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
                  title: vi.app.thread.khongTimThayBai,
                  message: vi.app.thread.khongTimThayNoi,
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
    final source = widget.post;
    final summary = presentPost(source, fullContent: true);
    final interaction = ref.watch(postInteractionProvider(source.id));
    final detail = interaction.apply(summary);
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
            framed: true,
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
            shareSemanticLabel: vi.miscViews.chiaSe,
            onVoteChanged: (value) => ref
                .read(postInteractionsProvider.notifier)
                .vote(source.id, value),
            onBookmarkToggle: () => ref
                .read(postInteractionsProvider.notifier)
                .toggleBookmark(
                  source.id,
                  initialValue: source.viewerBookmarked,
                ),
            upvoteSemanticLabel: vi.app.common.ungHo,
            downvoteSemanticLabel: vi.app.common.phanDoi,
            commentSemanticLabel: vi.common.binhLuan,
            bookmarkSemanticLabel: vi.app.common.luuBaiViet,
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
