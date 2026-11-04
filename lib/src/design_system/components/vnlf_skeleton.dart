import 'package:flutter/material.dart';

import '../tokens/vnlf_colors.dart';
import '../tokens/vnlf_dimensions.dart';
import '../tokens/vnlf_typography.dart';

/// Atomic placeholder bone for skeleton-loading states across feed posts and
/// the weekly leaderboard.
///
/// Respects reduce-motion via [VnlfDimensions.resolveDuration] and avoids
/// unbounded background tickers so widget tests settle deterministically.
class VnlfSkeletonBox extends StatelessWidget {
  const VnlfSkeletonBox({
    super.key,
    this.width,
    this.height = 12.0,
    this.borderRadius = VnlfDimensions.radiusSm,
    this.isCircle = false,
    this.semanticLabel,
  });

  final double? width;
  final double height;
  final double borderRadius;
  final bool isCircle;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final duration = VnlfDimensions.resolveDuration(
      context,
      VnlfDimensions.motionNormal,
    );

    final box = AnimatedContainer(
      duration: duration,
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: colors.surfaceSoft,
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircle ? null : BorderRadius.circular(borderRadius),
        border: Border.all(
          color: colors.line.withValues(alpha: colors.isDark ? 0.65 : 0.8),
        ),
      ),
    );

    if (semanticLabel == null) {
      return box;
    }
    return Semantics(label: semanticLabel, child: box);
  }
}

typedef VnlfSkeletonBone = VnlfSkeletonBox;

/// Skeleton-loading placeholder matching [VnlfPostCard] geometry and spacing.
class VnlfPostCardSkeleton extends StatelessWidget {
  const VnlfPostCardSkeleton({
    super.key,
    this.showTitle = false,
    this.showAttachment = false,
    this.showBottomActions = true,
  });

  final bool showTitle;
  final bool showAttachment;
  final bool showBottomActions;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);

    return Semantics(
      label: 'Đang tải bài viết',
      container: true,
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(VnlfDimensions.radiusLg),
          border: Border.all(color: colors.line),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const VnlfSkeletonBox(width: 40, height: 40, isCircle: true),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Flexible(
                        flex: 3,
                        child: VnlfSkeletonBox(
                          width: 124,
                          height: 14,
                          borderRadius: VnlfDimensions.radiusSm,
                        ),
                      ),
                      SizedBox(width: 6),
                      VnlfSkeletonBox(width: 15, height: 15, isCircle: true),
                      SizedBox(width: 8),
                      Flexible(
                        flex: 2,
                        child: VnlfSkeletonBox(
                          width: 78,
                          height: 12,
                          borderRadius: VnlfDimensions.radiusSm,
                        ),
                      ),
                      Spacer(),
                      VnlfSkeletonBox(
                        width: 36,
                        height: 12,
                        borderRadius: VnlfDimensions.radiusSm,
                      ),
                    ],
                  ),
                  if (showTitle) ...[
                    const SizedBox(height: 10),
                    const FractionallySizedBox(
                      widthFactor: 0.78,
                      child: VnlfSkeletonBox(
                        height: 18,
                        borderRadius: VnlfDimensions.radiusSm,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  const FractionallySizedBox(
                    widthFactor: 0.96,
                    child: VnlfSkeletonBox(height: 13),
                  ),
                  const SizedBox(height: 7),
                  const FractionallySizedBox(
                    widthFactor: 0.88,
                    child: VnlfSkeletonBox(height: 13),
                  ),
                  const SizedBox(height: 7),
                  const FractionallySizedBox(
                    widthFactor: 0.62,
                    child: VnlfSkeletonBox(height: 13),
                  ),
                  if (showAttachment) ...[
                    const SizedBox(height: 12),
                    const VnlfSkeletonBox(
                      width: double.infinity,
                      height: 148,
                      borderRadius: VnlfDimensions.radiusMd,
                    ),
                  ],
                  if (showBottomActions) ...[
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: const [
                        VnlfSkeletonBox(
                          width: 82,
                          height: 30,
                          borderRadius: VnlfDimensions.radiusFull,
                        ),
                        VnlfSkeletonBox(
                          width: 44,
                          height: 22,
                          borderRadius: VnlfDimensions.radiusSm,
                        ),
                        VnlfSkeletonBox(
                          width: 24,
                          height: 22,
                          borderRadius: VnlfDimensions.radiusSm,
                        ),
                        VnlfSkeletonBox(
                          width: 24,
                          height: 22,
                          borderRadius: VnlfDimensions.radiusSm,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

typedef VnlfFeedPostSkeleton = VnlfPostCardSkeleton;

/// List of [VnlfPostCardSkeleton] items for initial feed loading states.
class VnlfFeedSkeletonList extends StatelessWidget {
  const VnlfFeedSkeletonList({
    super.key,
    this.itemCount = 3,
    this.spacing = 12.0,
  });

  final int itemCount;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Đang tải danh sách bài viết bảng tin',
      container: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < itemCount; i++) ...[
            if (i > 0) SizedBox(height: spacing),
            VnlfPostCardSkeleton(showTitle: i.isOdd, showAttachment: i == 0),
          ],
        ],
      ),
    );
  }
}

typedef VnlfFeedPostsSkeleton = VnlfFeedSkeletonList;

/// Single row skeleton matching a ranked row in [VnlfLeaderboardCard].
class VnlfLeaderboardRowSkeleton extends StatelessWidget {
  const VnlfLeaderboardRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(
          width: 20,
          child: Align(
            alignment: Alignment.centerLeft,
            child: VnlfSkeletonBox(width: 12, height: 12),
          ),
        ),
        const SizedBox(width: 4),
        const VnlfSkeletonBox(width: 34, height: 34, isCircle: true),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              FractionallySizedBox(
                widthFactor: 0.72,
                child: VnlfSkeletonBox(height: 13),
              ),
              SizedBox(height: 5),
              FractionallySizedBox(
                widthFactor: 0.52,
                child: VnlfSkeletonBox(height: 11),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        const VnlfSkeletonBox(width: 24, height: 14),
      ],
    );
  }
}

/// Skeleton-loading component for the `304px` right-sidebar weekly leaderboard
/// (`Xếp hạng tuần`).
class VnlfLeaderboardCardSkeleton extends StatelessWidget {
  const VnlfLeaderboardCardSkeleton({
    super.key,
    this.itemCount = 3,
    this.width = VnlfDimensions.rightSidebarWidth,
    this.showFooter = true,
  });

  final int itemCount;
  final double width;
  final bool showFooter;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);

    return Semantics(
      label: 'Đang tải bảng xếp hạng tuần',
      container: true,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width),
        child: SizedBox(
          width: width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(VnlfDimensions.radiusLg),
                  border: Border.all(color: colors.line),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 1.5),
                          child: Icon(
                            Icons.emoji_events_outlined,
                            size: 17,
                            color: colors.ink,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              Text(
                                'Xếp hạng tuần',
                                softWrap: true,
                                style: VnlfTypography.h3(colors.ink)
                                    .copyWith(fontWeight: FontWeight.w700),
                              ),
                              const VnlfSkeletonBox(width: 68, height: 12),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    for (var i = 0; i < itemCount; i++) ...[
                      if (i > 0) const SizedBox(height: 12),
                      const VnlfLeaderboardRowSkeleton(),
                    ],
                  ],
                ),
              ),
              if (showFooter) ...[
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'VNLF Social · 2026',
                        softWrap: true,
                        style: VnlfTypography.meta(colors.muted),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 10,
                        runSpacing: 4,
                        children: [
                          Text(
                            'Quy chuẩn cộng đồng',
                            softWrap: true,
                            style: VnlfTypography.meta(colors.muted),
                          ),
                          Text(
                            'Riêng tư',
                            softWrap: true,
                            style: VnlfTypography.meta(colors.muted),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

typedef VnlfLeaderboardSkeleton = VnlfLeaderboardCardSkeleton;
