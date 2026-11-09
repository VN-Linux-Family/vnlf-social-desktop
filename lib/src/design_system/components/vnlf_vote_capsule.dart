import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/rendering.dart' show OverflowBoxFit;
import 'package:flutter/services.dart';

import '../models/vnlf_models.dart';
import '../tokens/vnlf_colors.dart';
import '../tokens/vnlf_dimensions.dart';
import '../tokens/vnlf_typography.dart';
import '../icons/vnlf_icon.dart';

/// The website's vote control (content-vote): up arrow, score, down arrow.
///
/// On wider screens it is a `--surface-soft` pill with 36px round buttons;
/// on phones it has no pill, and each 40px button keeps a 48px touch target.
/// An active arrow is filled: brand on brand-soft for up, red on a 12% red
/// tint for down. The score stays ink.
class VnlfVoteCapsule extends StatelessWidget {
  const VnlfVoteCapsule({
    super.key,
    required this.score,
    required this.voteState,
    this.onVoteChanged,
    this.compact = false,
    this.semanticLabel,
    this.upvoteSemanticLabel,
    this.downvoteSemanticLabel,
  });

  final int score;
  final VoteState voteState;
  final ValueChanged<VoteState>? onVoteChanged;

  /// Comments use the same control with tighter spacing around the score.
  final bool compact;
  final String? semanticLabel;
  final String? upvoteSemanticLabel;
  final String? downvoteSemanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final phone =
        VnlfViewportSize.fromWidth(MediaQuery.sizeOf(context).width) ==
        VnlfViewportSize.mobile;
    final visual = phone ? 40.0 : 36.0;
    final target = phone ? 48.0 : 36.0;

    Widget arrow({required bool up}) {
      final state = up ? VoteState.upvoted : VoteState.downvoted;
      final active = voteState == state;
      final tint = up
          ? colors.brandSoft
          : Color.alphaBlend(
              colors.red.withValues(alpha: 0.12),
              colors.surface,
            );
      return Semantics(
        button: true,
        enabled: onVoteChanged != null,
        toggled: active,
        label: up ? upvoteSemanticLabel : downvoteSemanticLabel,
        child: SizedBox(
          width: target,
          height: target,
          child: Center(
            child: Material(
              color: active ? tint : Colors.transparent,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                customBorder: const CircleBorder(),
                hoverColor: colors.brandSoft,
                onTap: onVoteChanged == null
                    ? null
                    : () {
                        HapticFeedback.lightImpact();
                        onVoteChanged!(active ? VoteState.neutral : state);
                      },
                child: SizedBox.square(
                  dimension: visual,
                  child: Center(
                    child: VnlfIcon(
                      up ? VnlfLucide.arrowBigUp : VnlfLucide.arrowBigDown,
                      size: 20,
                      filled: active,
                      color: active
                          ? (up ? colors.brand : colors.red)
                          : colors.muted,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    final row = Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 2,
      children: [
        arrow(up: true),
        ConstrainedBox(
          constraints: BoxConstraints(minWidth: compact ? 16 : 20),
          child: Text(
            '$score',
            textAlign: TextAlign.center,
            style: VnlfTypography.number(colors.ink)
                .copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        arrow(up: false),
      ],
    );
    return Semantics(
      label: semanticLabel,
      container: true,
      // Posts on phones drop the pill; comments keep it, as on the website.
      child: phone && !compact
          ? row
          : DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surfaceSoft,
                borderRadius: BorderRadius.circular(VnlfDimensions.radiusFull),
              ),
              child: row,
            ),
    );
  }
}

/// The website's post action row: vote, comments, copy link, bookmark.
///
/// Wider screens keep every action left-aligned 13px apart. Phones bleed
/// the row 10px into the card padding so the vote arrow and the bookmark
/// line up with the text, and push the bookmark to the far right.
class VnlfPostInteractionBar extends StatelessWidget {
  const VnlfPostInteractionBar({
    super.key,
    required this.voteScore,
    required this.voteState,
    required this.commentCount,
    required this.isBookmarked,
    this.onVoteChanged,
    this.onCommentTap,
    this.onShareTap,
    this.onBookmarkToggle,
    this.semanticLabel,
    this.voteSemanticLabel,
    this.upvoteSemanticLabel,
    this.downvoteSemanticLabel,
    this.commentSemanticLabel,
    this.shareSemanticLabel,
    this.bookmarkSemanticLabel,
    this.viewCount,
    this.viewsLabel,
    this.viewsTooltip,
  });

  final int voteScore;
  final VoteState voteState;
  final int commentCount;
  final bool isBookmarked;
  final ValueChanged<VoteState>? onVoteChanged;
  final VoidCallback? onCommentTap;
  final VoidCallback? onShareTap;
  final VoidCallback? onBookmarkToggle;
  final String? semanticLabel;
  final String? voteSemanticLabel;
  final String? upvoteSemanticLabel;
  final String? downvoteSemanticLabel;
  final String? commentSemanticLabel;
  final String? shareSemanticLabel;
  final String? bookmarkSemanticLabel;

  /// The author's view count, shown between share and save.
  final int? viewCount;
  final String? viewsLabel;
  final String? viewsTooltip;

  static const _phoneBleed = 10.0;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final phone =
        VnlfViewportSize.fromWidth(MediaQuery.sizeOf(context).width) ==
        VnlfViewportSize.mobile;

    Widget action({
      required VnlfLucide icon,
      required VoidCallback? onTap,
      required String? label,
      String? count,
      bool? toggled,
      bool active = false,
      bool haptic = false,
    }) {
      final color = active ? colors.brand : colors.muted;
      return Semantics(
        button: true,
        enabled: onTap != null,
        toggled: toggled,
        label: label,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(VnlfDimensions.radiusSm),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            hoverColor: colors.brandSoft,
            onTap: onTap == null
                ? null
                : () {
                    haptic
                        ? HapticFeedback.lightImpact()
                        : HapticFeedback.selectionClick();
                    onTap();
                  },
            child: ConstrainedBox(
              constraints: phone
                  ? const BoxConstraints(minWidth: 48, minHeight: 48)
                  : const BoxConstraints(minHeight: 31),
              child: Padding(
                padding: EdgeInsets.all(phone ? 4 : 5),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 5,
                  children: [
                    VnlfIcon(
                      icon,
                      size: 19,
                      color: color,
                      filled: active && icon == VnlfLucide.bookmark,
                    ),
                    if (count != null)
                      Text(count, style: VnlfTypography.meta(color)),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final vote = VnlfVoteCapsule(
      score: voteScore,
      voteState: voteState,
      onVoteChanged: onVoteChanged,
      semanticLabel: voteSemanticLabel,
      upvoteSemanticLabel: upvoteSemanticLabel,
      downvoteSemanticLabel: downvoteSemanticLabel,
    );
    final comment = action(
      icon: VnlfLucide.messageCircle,
      count: '$commentCount',
      onTap: onCommentTap,
      label: commentSemanticLabel,
    );
    final share = action(
      icon: VnlfLucide.link2,
      onTap: onShareTap,
      label: shareSemanticLabel,
    );
    final views = viewCount == null
        ? null
        : Tooltip(
            message: viewsTooltip ?? '',
            child: Semantics(
              label: viewsLabel,
              excludeSemantics: true,
              child: ConstrainedBox(
                constraints: phone
                    ? const BoxConstraints(minWidth: 48, minHeight: 48)
                    : const BoxConstraints(minHeight: 31),
                child: Padding(
                  padding: EdgeInsets.all(phone ? 4 : 5),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 5,
                    children: [
                      VnlfIcon(VnlfLucide.eye, size: 19, color: colors.muted),
                      Text(
                        NumberFormat.decimalPattern('vi').format(viewCount),
                        style: VnlfTypography.meta(colors.muted),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
    final bookmark = action(
      icon: VnlfLucide.bookmark,
      onTap: onBookmarkToggle,
      label: bookmarkSemanticLabel,
      toggled: isBookmarked,
      active: isBookmarked,
      haptic: true,
    );

    final Widget bar;
    if (phone) {
      bar = LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth + _phoneBleed * 2;
          return Transform.translate(
            offset: const Offset(-_phoneBleed, 0),
            child: OverflowBox(
              alignment: Alignment.centerLeft,
              minWidth: width,
              maxWidth: width,
              fit: OverflowBoxFit.deferToChild,
              child: Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [vote, comment, share, ?views],
                    ),
                  ),
                  bookmark,
                ],
              ),
            ),
          );
        },
      );
    } else {
      bar = Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 13,
        runSpacing: 8,
        children: [vote, comment, share, ?views, bookmark],
      );
    }

    if (semanticLabel == null) {
      return bar;
    }
    return Semantics(label: semanticLabel, container: true, child: bar);
  }
}
