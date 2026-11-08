import '../../polls/presentation/poll_card.dart';
import '../../moderation/presentation/report_dialog.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/api_client.dart';
import '../../../design_system/design_system.dart';
import '../../notifications/presentation/notifications_sheet.dart';
import '../../composer/presentation/composer_prompt.dart';
import '../../shared/presentation/post_interactions.dart';
import 'feed_notifier.dart';
import 'post_mapper.dart';
import '../../shared/presentation/post_share.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  FeedTab _tab = FeedTab.latest;

  @override
  Widget build(BuildContext context) {
    final english = Localizations.localeOf(context).languageCode == 'en';
    final feed = ref.watch(feedNotifierProvider(_tab));
    final notifier = ref.read(feedNotifierProvider(_tab).notifier);
    final session =
        ref.watch(sessionStateProvider) ??
        ref.watch(sessionProvider).valueOrNull;
    final tabs = english
        ? const ['Latest', 'Featured', 'Articles', 'Following']
        : const ['Mới nhất', 'Được chú ý', 'Article', 'Đang theo dõi'];

    final selectedIndex = _tab.index < tabs.length ? _tab.index : 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (VnlfViewportSize.fromWidth(MediaQuery.sizeOf(context).width) !=
            VnlfViewportSize.mobile)
          VnlfCenterPageHeader(
            title: english ? 'Feed' : 'Bảng tin',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: english ? 'Search' : 'Tìm kiếm',
                  icon: const Icon(Icons.search),
                  onPressed: () => context.push('/search'),
                ),
                IconButton(
                  tooltip: english ? 'Notifications' : 'Thông báo',
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => const NotificationsSheet(),
                  ),
                ),
                IconButton(
                  tooltip: english ? 'Profile' : 'Tài khoản cá nhân',
                  icon: const Icon(Icons.person_outline),
                  onPressed: () => context.push(
                    session == null
                        ? '/login'
                        : '/profile/${Uri.encodeComponent(session.username)}',
                  ),
                ),
              ],
            ),
          ),
        VnlfFeedTabBar(
          tabs: tabs,
          selectedIndex: selectedIndex,
          onTabSelected: (index) =>
              setState(() => _tab = FeedTab.values[index]),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification.depth == 0 &&
                  notification.metrics.axis == Axis.vertical &&
                  notification.metrics.extentAfter < 300 &&
                  feed.asData?.value.paginationError == null) {
                notifier.loadMore();
              }
              return false;
            },
            child: RefreshIndicator(
              onRefresh: notifier.refresh,
              child: CustomScrollView(
                key: ValueKey(_tab),
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: ComposerPrompt(
                      onPressed: () =>
                          GoRouter.maybeOf(context)
                              ?.push(session == null ? '/login' : '/compose'),
                    ),
                  ),
                  ...feed.when(
                    loading: () => const [
                      SliverToBoxAdapter(
                        child: VnlfLoadingShimmer(
                          child: VnlfPostCard.loading(
                            loadingSemanticLabel: 'Đang tải bài viết',
                          ),
                        ),
                      ),
                    ],
                    error: (error, stack) {
                      final isAuthRequired =
                          error is HttpFailure &&
                          (error.statusCode == 401 || error.statusCode == 403);
                      if (_tab == FeedTab.following &&
                          (isAuthRequired ||
                              ref.watch(sessionStateProvider) == null)) {
                        return [
                          SliverToBoxAdapter(
                            child: VnlfPostCard.empty(
                              emptyTitle: english
                                  ? 'Sign in required'
                                  : 'Yêu cầu đăng nhập',
                              emptyMessage: english
                                  ? 'Sign in to see posts from members you follow.'
                                  : 'Đăng nhập để xem bảng tin từ những người bạn theo dõi.',
                              emptyActionLabel: english
                                  ? 'Sign in'
                                  : 'Đăng nhập',
                              onEmptyAction: () => context.push('/login'),
                            ),
                          ),
                        ];
                      }
                      return [
                        SliverToBoxAdapter(
                          child: VnlfPostCard.error(
                            errorTitle: english
                                ? 'Unable to load feed'
                                : 'Không tải được bảng tin',
                            errorMessage: english
                                ? 'Please try again.'
                                : 'Vui lòng thử lại.',
                            retryLabel: english ? 'Retry' : 'Thử lại',
                            onRetry: notifier.refresh,
                          ),
                        ),
                      ];
                    },
                    data: (data) => [
                      if (data.posts.isEmpty)
                        SliverToBoxAdapter(
                          child: VnlfPostCard.empty(
                            emptyTitle: english
                                ? 'No posts yet'
                                : 'Chưa có bài viết',
                            emptyMessage: _tab == FeedTab.following
                                ? (english
                                      ? 'Follow members to see their posts here.'
                                      : 'Hãy theo dõi thành viên để xem bài viết ở đây.')
                                : (english
                                      ? 'Pull down to refresh.'
                                      : 'Kéo xuống để làm mới bảng tin.'),
                            emptyActionLabel: english ? 'Refresh' : 'Làm mới',
                            onEmptyAction: notifier.refresh,
                          ),
                        ),
                      SliverList.builder(
                        itemCount: data.posts.length,
                        itemBuilder: (context, index) => Consumer(
                          builder: (context, ref, child) {
                            final source = data.posts[index];
                            final interaction = ref.watch(
                              postInteractionProvider(source.id),
                            );
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: InkWell(
                                onTap: () => context.push(
                                  '/thread/${Uri.encodeComponent(data.posts[index].id)}',
                                ),
                                child: VnlfPostCard(
                                  poll: source.poll == null
                                      ? null
                                      : PollCard(
                                          poll: source.poll!,
                                          authorId: source.author.id,
                                        ),
                                  key: ValueKey(data.posts[index].id),
                                  post: interaction.apply(
                                    presentPost(source, english: english),
                                    english: english,
                                  ),
                                  onVoteChanged: (vote) => ref
                                      .read(postInteractionsProvider.notifier)
                                      .vote(source.id, vote),
                                  onBookmarkToggle: () => ref
                                      .read(postInteractionsProvider.notifier)
                                      .toggleBookmark(
                                        source.id,
                                        initialValue: source.viewerBookmarked,
                                      ),
                                  authorAvatarSemanticLabel:
                                      data.posts[index].author.displayName,
                                  onAuthorTap: () => context.push(
                                    '/profile/${Uri.encodeComponent(data.posts[index].author.username)}',
                                  ),
                                  onShareTap: () =>
                                      copyPostLink(context, source),
                                  onReportTap: () => showArticleReport(
                                    context,
                                    ref,
                                    source.id,
                                  ),
                                  onCommentTap: () => context.push(
                                    '/thread/${Uri.encodeComponent(data.posts[index].id)}',
                                  ),
                                  moreOptionsSemanticLabel: english
                                      ? 'More options'
                                      : 'Tùy chọn',
                                  upvoteSemanticLabel: english
                                      ? 'Upvote'
                                      : 'Ủng hộ',
                                  downvoteSemanticLabel: english
                                      ? 'Downvote'
                                      : 'Phản đối',
                                  commentSemanticLabel: english
                                      ? 'Comments'
                                      : 'Bình luận',
                                  shareSemanticLabel: english
                                      ? 'Share'
                                      : 'Chia sẻ',
                                  bookmarkSemanticLabel: english
                                      ? 'Bookmark'
                                      : 'Lưu bài viết',
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      if (data.isLoadingMore)
                        const SliverToBoxAdapter(
                          child: VnlfLoadingShimmer(
                            child: VnlfPostCard.loading(),
                          ),
                        ),
                      if (data.paginationError != null)
                        SliverToBoxAdapter(
                          child: VnlfPostCard.error(
                            errorTitle: english
                                ? 'Unable to load more posts'
                                : 'Không tải được bài viết tiếp theo',
                            errorMessage: english
                                ? 'Your posts are still here.'
                                : 'Các bài viết đã tải vẫn được giữ lại.',
                            retryLabel: english ? 'Retry' : 'Thử lại',
                            onRetry: notifier.loadMore,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
