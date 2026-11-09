import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/design_system.dart';
import '../../../domain/models.dart';
import '../../../i18n/vi.dart';
import '../../shared/presentation/post_menu.dart';
import '../../shared/presentation/post_share.dart';

/// Phones and narrow windows use the website's ≤840px layout.
bool isPhoneLayout(BuildContext context) =>
    VnlfViewportSize.fromWidth(MediaQuery.sizeOf(context).width) ==
    VnlfViewportSize.mobile;

/// "← Quay lại bảng tin": back to the feed the reader came from.
class DetailBackButton extends StatelessWidget {
  const DetailBackButton({
    super.key,
    this.iconSize = 20,
    this.showLabel = true,
  });

  final double iconSize;
  final bool showLabel;

  void _back(BuildContext context) {
    final router = GoRouter.maybeOf(context);
    if (router == null) return;
    if (router.canPop()) {
      router.pop();
    } else {
      router.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final label = vi.miscViews.quayLaiBangTin;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Tooltip(
        message: showLabel ? '' : label,
        child: InkWell(
          onTap: () => _back(context),
          borderRadius: BorderRadius.circular(VnlfDimensions.radiusSm),
          child: ConstrainedBox(
            // Phones keep a 48dp-class target; desktop matches the website.
            constraints: isPhoneLayout(context)
                ? const BoxConstraints(minHeight: 44, minWidth: 44)
                : const BoxConstraints(),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 6,
                children: [
                  VnlfIcon(
                    VnlfLucide.arrowLeft,
                    size: iconSize,
                    color: colors.muted,
                  ),
                  if (showLabel)
                    Flexible(
                      child: Text(
                        label,
                        style: VnlfTypography.body(colors.muted),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The ghost "…" button that opens the post menu under itself.
class DetailMoreButton extends ConsumerWidget {
  const DetailMoreButton({
    super.key,
    required this.post,
    this.size = 37,
    this.iconSize = 19,
  });

  final FeedPost post;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = VnlfColors.of(context);
    return Semantics(
      button: true,
      label: vi.miscViews.moMenuBaiViet,
      excludeSemantics: true,
      child: Tooltip(
        message: vi.miscViews.moMenuBaiViet,
        child: SizedBox.square(
          dimension: size,
          child: InkWell(
            borderRadius: BorderRadius.circular(VnlfDimensions.radiusMd),
            onTap: () {
              final box = context.findRenderObject() as RenderBox?;
              if (box == null) return;
              final anchor = box.localToGlobal(Offset.zero) & box.size;
              showPostMenu(
                context,
                ref,
                post,
                anchor: anchor,
                onDetailPage: true,
              );
            },
            child: Center(
              child: VnlfIcon(
                VnlfLucide.ellipsis,
                size: iconSize,
                color: colors.muted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The vote pill wired to the post's interaction state; guests sign in first.
class DetailVote extends ConsumerWidget {
  const DetailVote({super.key, required this.post, required this.detail});

  final FeedPost post;
  final PostData detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final label = vi.contentVote.baiViet;
    return VnlfVoteCapsule(
      score: detail.voteScore,
      voteState: detail.viewerVote,
      semanticLabel: vi.contentVote.diemBinhChon,
      upvoteSemanticLabel: format(vi.contentVote.upvote, {'label': label}),
      downvoteSemanticLabel: format(vi.contentVote.downvote, {'label': label}),
      onVoteChanged: detail.actionPending
          ? null
          : (value) => votePost(context, ref, post, value),
    );
  }
}

/// The comment, share and save buttons of a detail page.
List<Widget> detailActionButtons(
  BuildContext context,
  WidgetRef ref, {
  required FeedPost post,
  required PostData detail,
  required VoidCallback onComment,
  required bool phone,
  required bool withLabels,
  required double commentIcon,
  required double shareIcon,
  required double bookmarkIcon,
}) {
  final padding = phone
      ? const EdgeInsets.all(4)
      : withLabels
      ? const EdgeInsets.symmetric(horizontal: 6, vertical: 4)
      : const EdgeInsets.all(5);
  final minSize = phone ? 48.0 : (withLabels ? 0.0 : 31.0);
  return [
    VnlfActionButton(
      icon: VnlfLucide.messageCircle,
      iconSize: commentIcon,
      label: '${detail.commentCount}',
      semanticLabel: vi.miscViews.moBinhLuan,
      padding: padding,
      minSize: minSize,
      onPressed: onComment,
    ),
    VnlfActionButton(
      icon: VnlfLucide.link2,
      iconSize: shareIcon,
      label: withLabels ? vi.miscViews.chiaSe : null,
      semanticLabel: vi.common.chiaSeBaiViet,
      padding: padding,
      minSize: minSize,
      onPressed: () => showPostShareDialog(context, post),
    ),
    VnlfActionButton(
      icon: VnlfLucide.bookmark,
      iconSize: bookmarkIcon,
      active: detail.isBookmarked,
      label: withLabels
          ? (detail.isBookmarked ? vi.common.daLuu : vi.common.luu)
          : null,
      semanticLabel: detail.isBookmarked
          ? vi.common.boLuuBaiViet
          : vi.common.luuBaiViet,
      padding: padding,
      minSize: minSize,
      onPressed: detail.actionPending
          ? null
          : () => togglePostBookmark(context, ref, post),
    ),
  ];
}

/// Avatar or name: opens the author's profile.
void openAuthorProfile(BuildContext context, FeedPost post) =>
    context.push('/profile/${Uri.encodeComponent(post.author.username)}');
