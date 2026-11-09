import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/vnlf_models.dart';
import '../tokens/vnlf_colors.dart';
import '../tokens/vnlf_dimensions.dart';
import '../tokens/vnlf_typography.dart';

/// Capsule containing Upvote Arrow, Score Counter, and Downvote Arrow.
///
/// Matches the exact interaction bar capsule in `reference_feed_desktop.png`:
/// - Upvoted state: Upvote arrow colored `--brand`, score colored `--brand`.
/// - Downvoted state: Downvote arrow colored `--red`, score colored `--red`.
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
  final bool compact;
  final String? semanticLabel;
  final String? upvoteSemanticLabel;
  final String? downvoteSemanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);

    final Color upColor = voteState == VoteState.upvoted
        ? colors.brand
        : colors.muted;
    final Color downColor = voteState == VoteState.downvoted
        ? colors.red
        : colors.muted;
    final Color scoreColor = switch (voteState) {
      VoteState.upvoted => colors.brand,
      VoteState.downvoted => colors.red,
      VoteState.neutral => colors.ink,
    };
    final Color bgColor = switch (voteState) {
      VoteState.upvoted => colors.brandSoft,
      VoteState.downvoted => colors.red.withValues(alpha: 0.12),
      VoteState.neutral => colors.surfaceSoft,
    };
    final Color borderColor = switch (voteState) {
      VoteState.upvoted => colors.brand.withValues(alpha: 0.35),
      VoteState.downvoted => colors.red.withValues(alpha: 0.35),
      VoteState.neutral => colors.line,
    };

    return Semantics(
      label: semanticLabel,
      container: true,
      child: AnimatedContainer(
        duration: VnlfDimensions.resolveDuration(
          context,
          VnlfDimensions.motionFast,
        ),
        constraints: const BoxConstraints(minHeight: 48),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(VnlfDimensions.radiusFull),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              button: true,
              enabled: onVoteChanged != null,
              toggled: voteState == VoteState.upvoted,
              label: upvoteSemanticLabel,
              child: InkWell(
                borderRadius: BorderRadius.circular(VnlfDimensions.radiusFull),
                onTap: onVoteChanged == null
                    ? null
                    : () {
                        HapticFeedback.lightImpact();
                        final next = voteState == VoteState.upvoted
                            ? VoteState.neutral
                            : VoteState.upvoted;
                        onVoteChanged!(next);
                      },
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: Center(
                    child: CustomPaint(
                      size: const Size(13, 13),
                      painter: _HollowVoteArrowPainter(
                        color: upColor,
                        isUp: true,
                        filled: voteState == VoteState.upvoted,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: compact ? 4 : 6),
              child: Text('$score', style: VnlfTypography.number(scoreColor)),
            ),
            Semantics(
              button: true,
              enabled: onVoteChanged != null,
              toggled: voteState == VoteState.downvoted,
              label: downvoteSemanticLabel,
              child: InkWell(
                borderRadius: BorderRadius.circular(VnlfDimensions.radiusFull),
                onTap: onVoteChanged == null
                    ? null
                    : () {
                        HapticFeedback.lightImpact();
                        final next = voteState == VoteState.downvoted
                            ? VoteState.neutral
                            : VoteState.downvoted;
                        onVoteChanged!(next);
                      },
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: Center(
                    child: CustomPaint(
                      size: const Size(13, 13),
                      painter: _HollowVoteArrowPainter(
                        color: downColor,
                        isUp: false,
                        filled: voteState == VoteState.downvoted,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full post footer bar with Vote Capsule, Comment count, Copy link, and Bookmark toggle.
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

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);

    final bar = Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        VnlfVoteCapsule(
          score: voteScore,
          voteState: voteState,
          onVoteChanged: onVoteChanged,
          semanticLabel: voteSemanticLabel,
          upvoteSemanticLabel: upvoteSemanticLabel,
          downvoteSemanticLabel: downvoteSemanticLabel,
        ),
        Semantics(
          button: true,
          enabled: onCommentTap != null,
          label: commentSemanticLabel,
          child: InkWell(
            borderRadius: BorderRadius.circular(VnlfDimensions.radiusSm),
            onTap: onCommentTap == null
                ? null
                : () {
                    HapticFeedback.selectionClick();
                    onCommentTap!();
                  },
            child: Container(
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.mode_comment_outlined,
                    size: 15,
                    color: colors.muted,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '$commentCount',
                    style: VnlfTypography.meta(colors.muted),
                  ),
                ],
              ),
            ),
          ),
        ),
        Semantics(
          button: true,
          enabled: onShareTap != null,
          label: shareSemanticLabel,
          child: InkWell(
            borderRadius: BorderRadius.circular(VnlfDimensions.radiusSm),
            onTap: onShareTap == null
                ? null
                : () {
                    HapticFeedback.selectionClick();
                    onShareTap!();
                  },
            child: Container(
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              width: 48,
              height: 48,
              alignment: Alignment.center,
              padding: const EdgeInsets.all(6),
              child: Icon(Icons.link_rounded, size: 17, color: colors.muted),
            ),
          ),
        ),
        Semantics(
          button: true,
          enabled: onBookmarkToggle != null,
          toggled: isBookmarked,
          label: bookmarkSemanticLabel,
          child: InkWell(
            borderRadius: BorderRadius.circular(VnlfDimensions.radiusSm),
            onTap: onBookmarkToggle == null
                ? null
                : () {
                    HapticFeedback.lightImpact();
                    onBookmarkToggle!();
                  },
            child: Container(
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              width: 48,
              height: 48,
              alignment: Alignment.center,
              padding: const EdgeInsets.all(6),
              child: Icon(
                isBookmarked
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                size: 16,
                color: isBookmarked ? colors.brand : colors.muted,
              ),
            ),
          ),
        ),
      ],
    );

    if (semanticLabel == null) {
      return bar;
    }
    return Semantics(label: semanticLabel, container: true, child: bar);
  }
}

class _HollowVoteArrowPainter extends CustomPainter {
  const _HollowVoteArrowPainter({
    required this.color,
    required this.isUp,
    required this.filled,
  });

  final Color color;
  final bool isUp;
  final bool filled;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path();

    if (isUp) {
      path.moveTo(w * 0.5, h * 0.12);
      path.lineTo(w * 0.9, h * 0.52);
      path.lineTo(w * 0.66, h * 0.52);
      path.lineTo(w * 0.66, h * 0.88);
      path.lineTo(w * 0.34, h * 0.88);
      path.lineTo(w * 0.34, h * 0.52);
      path.lineTo(w * 0.1, h * 0.52);
      path.close();
    } else {
      path.moveTo(w * 0.5, h * 0.88);
      path.lineTo(w * 0.9, h * 0.48);
      path.lineTo(w * 0.66, h * 0.48);
      path.lineTo(w * 0.66, h * 0.12);
      path.lineTo(w * 0.34, h * 0.12);
      path.lineTo(w * 0.34, h * 0.48);
      path.lineTo(w * 0.1, h * 0.48);
      path.close();
    }

    if (filled) {
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.fill,
      );
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 1.35
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _HollowVoteArrowPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.isUp != isUp ||
      oldDelegate.filled != filled;
}
