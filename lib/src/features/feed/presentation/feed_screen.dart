import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/models.dart';
import '../../../i18n/vi.dart';
import '../../composer/presentation/composer_prompt.dart';
import '../../moderation/presentation/report_dialog.dart';
import '../../notifications/presentation/notifications_controller.dart';
import '../../notifications/presentation/notifications_sheet.dart';
import '../../polls/presentation/poll_card.dart';
import '../../shared/presentation/post_interactions.dart';
import '../../shared/presentation/post_share.dart';
import '../../shared/presentation/session_avatar.dart';
import 'feed_notifier.dart';
import 'post_mapper.dart';

/// The website's home feed (HomeFeed): tabs, composer bar and posts. Phones
/// show each post as a full-bleed band 6px apart; wider screens put every
/// post in one bordered box, separated by hairlines, at most 720px wide.
class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  FeedTab _tab = FeedTab.latest;

  static final _tabs = [
    vi.feedViews.moiNhat,
    vi.feedViews.duocChuY,
    vi.feedViews.article,
    vi.feedViews.dangTheoDoi,
  ];

  @override
  Widget build(BuildContext context) {
    final feed = ref.watch(feedNotifierProvider(_tab));
    final notifier = ref.read(feedNotifierProvider(_tab).notifier);
    final session =
        ref.watch(sessionStateProvider) ??
        ref.watch(sessionProvider).valueOrNull;
    final phone =
        VnlfViewportSize.fromWidth(MediaQuery.sizeOf(context).width) ==
        VnlfViewportSize.mobile;
    final colors = VnlfColors.of(context);

    final scroll = NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.depth == 0 &&
            notification.metrics.axis == Axis.vertical &&
            notification.metrics.extentAfter < 240 &&
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
              child: VnlfFeedTabBar(
                tabs: _tabs,
                selectedIndex: _tab.index,
                semanticLabel: vi.feedViews.locBangTin,
                onTabSelected: (index) =>
                    setState(() => _tab = FeedTab.values[index]),
              ),
            ),
            SliverToBoxAdapter(
              child: ComposerPrompt(
                avatar: sessionAvatar(session, size: 34),
                onPressed: () =>
                    GoRouter.maybeOf(context)
                        ?.push(session == null ? '/login' : '/compose'),
              ),
            ),
            ...feed.when(
              loading: () => [
                _band(
                  phone,
                  VnlfLoadingShimmer(
                    child: VnlfPostCard.loading(
                      loadingSemanticLabel: vi.app.feed.dangTaiBaiViet,
                    ),
                  ),
                ),
              ],
              error: (error, stack) {
                final authRequired =
                    error is HttpFailure &&
                    (error.statusCode == 401 || error.statusCode == 403);
                // Like the website, a tab that cannot load shows the empty
                // state; guests on "Đang theo dõi" are asked to sign in.
                if (_tab == FeedTab.following &&
                    (authRequired || ref.watch(sessionStateProvider) == null)) {
                  return [
                    _band(
                      phone,
                      VnlfPostCard.empty(
                        emptyTitle: vi.feedViews.chuaCoBaiViet,
                        emptyMessage: vi.feedViews.hayTheoDoiThanhVien,
                        emptyActionLabel: vi.common.dangNhap,
                        onEmptyAction: () => context.push('/login'),
                      ),
                    ),
                  ];
                }
                return [
                  _band(
                    phone,
                    VnlfPostCard.error(
                      errorTitle: vi.miscViews.chuaKetNoiDuocMayChu,
                      retryLabel: vi.common.thuLai,
                      onRetry: notifier.refresh,
                    ),
                  ),
                ];
              },
              data: (data) => [
                if (data.posts.isEmpty)
                  _band(
                    phone,
                    VnlfPostCard.empty(
                      emptyTitle: vi.feedViews.chuaCoBaiViet,
                      emptyMessage: vi.feedViews.hayTheoDoiThanhVien,
                      emptyActionLabel: vi.common.thuLai,
                      onEmptyAction: notifier.refresh,
                    ),
                  )
                else
                  _posts(context, data, phone, colors),
                SliverToBoxAdapter(
                  child: _FeedSentinel(
                    phone: phone,
                    text: data.isLoadingMore
                        ? vi.feedViews.dangTaiThem
                        : data.paginationError != null
                        ? null
                        : data.nextCursor == null
                        ? vi.feedViews.banDaXemHetFeed
                        : vi.feedViews.cuonDeXemBaiCu,
                  ),
                ),
                if (data.paginationError != null)
                  _band(
                    phone,
                    VnlfPostCard.error(
                      errorTitle: vi.miscViews.chuaKetNoiDuocMayChu,
                      retryLabel: vi.common.thuLai,
                      onRetry: notifier.loadMore,
                    ),
                  ),
              ],
            ),
            // Room for the floating phone bottom bar (56px + 12px).
            if (phone)
              SliverPadding(
                padding: EdgeInsets.only(
                  bottom: 68 + MediaQuery.viewPaddingOf(context).bottom,
                ),
              ),
          ],
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!phone)
          VnlfCenterPageHeader(
            title: vi.socialChrome.bangTin,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 10,
              children: [
                VnlfHeaderIconBox(
                  icon: VnlfLucide.search,
                  tooltip: vi.common.timKiem,
                  onPressed: () => context.push('/search'),
                ),
                VnlfHeaderIconBox(
                  icon: VnlfLucide.bell,
                  iconSize: 20,
                  muted: false,
                  tooltip: vi.common.thongBao,
                  badgeCount:
                      ref.watch(unreadNotificationsCountProvider).valueOrNull ??
                      0,
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => const NotificationsSheet(),
                  ),
                ),
                Semantics(
                  button: true,
                  label: session == null
                      ? vi.common.dangNhap
                      : session.displayName,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(
                      VnlfDimensions.radiusMd,
                    ),
                    onTap: () => context.push(
                      session == null
                          ? '/login'
                          : '/profile/${Uri.encodeComponent(session.username)}',
                    ),
                    child: sessionAvatar(
                      session,
                      size: 40,
                      cornerRadius: VnlfDimensions.radiusMd,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: phone
              ? scroll
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: scroll,
                  ),
                ),
        ),
      ],
    );
  }

  /// A state card placed like a post: a band on phones, a framed card on
  /// wider screens.
  Widget _band(bool phone, Widget child) => SliverToBoxAdapter(
    child: Padding(
      padding: EdgeInsets.only(top: phone ? 6 : 0),
      child: child,
    ),
  );

  Widget _posts(
    BuildContext context,
    FeedState data,
    bool phone,
    VnlfColors colors,
  ) {
    final list = SliverList.separated(
      itemCount: data.posts.length,
      separatorBuilder: (context, index) => phone
          ? const SizedBox(height: 6)
          : Divider(height: 1, thickness: 1, color: colors.line),
      itemBuilder: (context, index) =>
          _FeedPostTile(source: data.posts[index], key: ValueKey(index)),
    );
    if (phone) {
      return SliverPadding(
        padding: const EdgeInsets.only(top: 6),
        sliver: list,
      );
    }
    return DecoratedSliver(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(18),
      ),
      sliver: list,
    );
  }
}

class _FeedPostTile extends ConsumerWidget {
  const _FeedPostTile({super.key, required this.source});

  final FeedPost source;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final interaction = ref.watch(postInteractionProvider(source.id));
    final path = '/thread/${Uri.encodeComponent(source.id)}';
    return InkWell(
      onTap: () => context.push(path),
      child: VnlfPostCard(
        key: ValueKey(source.id),
        poll: source.poll == null
            ? null
            : PollCard(poll: source.poll!, authorId: source.author.id),
        post: interaction.apply(presentPost(source)),
        onVoteChanged: (vote) =>
            ref.read(postInteractionsProvider.notifier).vote(source.id, vote),
        onBookmarkToggle: () => ref
            .read(postInteractionsProvider.notifier)
            .toggleBookmark(source.id, initialValue: source.viewerBookmarked),
        authorAvatarSemanticLabel: source.author.displayName,
        onAuthorTap: () => context.push(
          '/profile/${Uri.encodeComponent(source.author.username)}',
        ),
        onShareTap: () => copyPostLink(context, source),
        onReportTap: () => showArticleReport(context, ref, source.id),
        onCommentTap: () => context.push(path),
        moreOptionsSemanticLabel: vi.feedViews.moMenuBaiViet,
        upvoteSemanticLabel: vi.app.common.ungHo,
        downvoteSemanticLabel: vi.app.common.phanDoi,
        commentSemanticLabel: vi.common.binhLuan,
        shareSemanticLabel: vi.socialOverlays.saoChepLienKet,
        bookmarkSemanticLabel: vi.common.luuBaiViet,
      ),
    );
  }
}

/// The website's feed sentinel line below the posts.
class _FeedSentinel extends StatelessWidget {
  const _FeedSentinel({required this.phone, required this.text});

  final bool phone;
  final String? text;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final text = this.text;
    if (text == null) return const SizedBox(height: 12);
    return Container(
      alignment: Alignment.center,
      constraints: const BoxConstraints(minHeight: 42),
      padding: phone
          ? const EdgeInsets.fromLTRB(16, 18, 16, 8)
          : EdgeInsets.zero,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: VnlfTypography.meta(phone ? colors.textSubtle : colors.muted),
      ),
    );
  }
}
