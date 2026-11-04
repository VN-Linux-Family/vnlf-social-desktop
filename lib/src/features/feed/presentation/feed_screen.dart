import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/design_system.dart';
import 'feed_notifier.dart';
import 'post_mapper.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VnlfCenterPageHeader(title: english ? 'Feed' : 'Bảng tin'),
        VnlfFeedTabBar(
          tabs: english
              ? const ['Latest', 'Featured', 'Article']
              : const ['Mới nhất', 'Được chú ý', 'Article'],
          selectedIndex: _tab.index,
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
                slivers: feed.when(
                  loading: () => const [
                    SliverToBoxAdapter(
                      child: VnlfLoadingShimmer(
                        child: VnlfPostCard.loading(
                          loadingSemanticLabel: 'Đang tải bài viết',
                        ),
                      ),
                    ),
                  ],
                  error: (error, stack) => [
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
                  ],
                  data: (data) => [
                    if (data.posts.isEmpty)
                      SliverToBoxAdapter(
                        child: VnlfPostCard.empty(
                          emptyTitle: english
                              ? 'No posts yet'
                              : 'Chưa có bài viết',
                          emptyMessage: english
                              ? 'Pull down to refresh.'
                              : 'Kéo xuống để làm mới bảng tin.',
                          emptyActionLabel: english ? 'Refresh' : 'Làm mới',
                          onEmptyAction: notifier.refresh,
                        ),
                      ),
                    SliverList.builder(
                      itemCount: data.posts.length,
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: VnlfPostCard(
                          key: ValueKey(data.posts[index].id),
                          post: presentPost(
                            data.posts[index],
                            english: english,
                          ),
                          authorAvatarSemanticLabel:
                              data.posts[index].author.displayName,
                          moreOptionsSemanticLabel: english
                              ? 'More options'
                              : 'Tùy chọn',
                          upvoteSemanticLabel: english ? 'Upvote' : 'Ủng hộ',
                          downvoteSemanticLabel: english
                              ? 'Downvote'
                              : 'Phản đối',
                          commentSemanticLabel: english
                              ? 'Comments'
                              : 'Bình luận',
                          shareSemanticLabel: english ? 'Share' : 'Chia sẻ',
                          bookmarkSemanticLabel: english
                              ? 'Bookmark'
                              : 'Lưu bài viết',
                        ),
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
              ),
            ),
          ),
        ),
      ],
    );
  }
}
