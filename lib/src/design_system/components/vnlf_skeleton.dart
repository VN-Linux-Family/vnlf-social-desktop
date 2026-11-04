import 'package:flutter/material.dart';

import '../tokens/vnlf_colors.dart';
import '../tokens/vnlf_dimensions.dart';
import '../tokens/vnlf_typography.dart';

/// Owns one shared loading animation and stops it when reduced motion is set.
class VnlfLoadingShimmer extends StatefulWidget {
  const VnlfLoadingShimmer({super.key, required this.child});

  final Widget child;

  @override
  State<VnlfLoadingShimmer> createState() => _VnlfLoadingShimmerState();
}

class _VnlfLoadingShimmerState extends State<VnlfLoadingShimmer>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _controller.stop();
    } else {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      VnlfSkeletonShimmerScope(controller: _controller, child: widget.child);
}

/// Scope that shares a single list-level shimmer [Animation] across all
/// descendant [VnlfPostCardSkeleton], [VnlfLeaderboardRowSkeleton], and
/// [VnlfSkeletonBox] widgets without creating per-row [AnimationController]s.
class VnlfSkeletonShimmerScope extends InheritedWidget {
  const VnlfSkeletonShimmerScope({
    super.key,
    required this.controller,
    required super.child,
  });

  final Animation<double>? controller;

  static Animation<double>? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<VnlfSkeletonShimmerScope>()
        ?.controller;
  }

  @override
  bool updateShouldNotify(VnlfSkeletonShimmerScope oldWidget) {
    return oldWidget.controller != controller;
  }
}

/// Atomic placeholder bone for skeleton-loading states across feed posts and
/// the weekly leaderboard.
///
/// Driven by a single shared list [AnimationController] when provided and
/// animations are enabled. Respects reduce-motion (`MediaQuery.disableAnimations`)
/// by collapsing to the static bone shape with [Duration.zero].
class VnlfSkeletonBox extends StatelessWidget {
  const VnlfSkeletonBox({
    super.key,
    this.width,
    this.height = 12.0,
    this.borderRadius = VnlfDimensions.radiusSm,
    this.isCircle = false,
    this.semanticLabel,
    this.controller,
    this.shimmerController,
  });

  final double? width;
  final double height;
  final double borderRadius;
  final bool isCircle;
  final String? semanticLabel;
  final Animation<double>? controller;
  final Animation<double>? shimmerController;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final disableAnimations =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final duration = VnlfDimensions.resolveDuration(
      context,
      VnlfDimensions.motionNormal,
    );
    final activeController = disableAnimations
        ? null
        : (controller ??
              shimmerController ??
              VnlfSkeletonShimmerScope.maybeOf(context));

    Widget buildBone({LinearGradient? gradient}) {
      return AnimatedContainer(
        duration: duration,
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: colors.surfaceSoft,
          gradient: gradient,
          shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: isCircle ? null : BorderRadius.circular(borderRadius),
          border: Border.all(
            color: colors.line.withValues(alpha: colors.isDark ? 0.65 : 0.8),
          ),
        ),
      );
    }

    final Widget box;
    if (activeController == null) {
      box = buildBone();
    } else {
      final baseColor = colors.surfaceSoft;
      final highlightColor = Color.lerp(
        colors.surfaceSoft,
        colors.isDark ? colors.line : colors.paper,
        colors.isDark ? 0.65 : 0.75,
      )!;
      box = AnimatedBuilder(
        animation: activeController,
        builder: (context, _) {
          final progress = activeController.value.clamp(0.0, 1.0);
          final sweep = -1.5 + (progress * 3.0);
          return buildBone(
            gradient: LinearGradient(
              begin: Alignment(sweep - 0.8, -0.2),
              end: Alignment(sweep + 0.8, 0.2),
              colors: [baseColor, highlightColor, baseColor],
              stops: const [0.0, 0.5, 1.0],
            ),
          );
        },
      );
    }

    if (semanticLabel == null) {
      return box;
    }
    return Semantics(label: semanticLabel, child: box);
  }
}

typedef VnlfSkeletonBone = VnlfSkeletonBox;

/// Skeleton-loading placeholder matching [VnlfPostCard] geometry and spacing.
///
/// Consumes a shared [controller] from its parent list rather than creating a
/// per-row [AnimationController].
class VnlfPostCardSkeleton extends StatelessWidget {
  const VnlfPostCardSkeleton({
    super.key,
    this.showTitle = false,
    this.showAttachment = false,
    this.showBottomActions = true,
    this.semanticLabel,
    this.controller,
    this.shimmerController,
  });

  final bool showTitle;
  final bool showAttachment;
  final bool showBottomActions;
  final String? semanticLabel;
  final Animation<double>? controller;
  final Animation<double>? shimmerController;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final disableAnimations =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final activeController = disableAnimations
        ? null
        : (controller ??
              shimmerController ??
              VnlfSkeletonShimmerScope.maybeOf(context));

    return VnlfSkeletonShimmerScope(
      controller: activeController,
      child: Semantics(
        label: semanticLabel,
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
      ),
    );
  }
}

typedef VnlfFeedPostSkeleton = VnlfPostCardSkeleton;

/// List of [VnlfPostCardSkeleton] items for initial feed loading states.
///
/// Shares a single [controller] passed from the parent/list controller across
/// all rows, collapsing to static bones when reduce-motion is enabled.
class VnlfFeedSkeletonList extends StatelessWidget {
  const VnlfFeedSkeletonList({
    super.key,
    this.itemCount = 3,
    this.spacing = 12.0,
    this.semanticLabel,
    this.itemSemanticLabel,
    this.controller,
    this.shimmerController,
  });

  final int itemCount;
  final double spacing;
  final String? semanticLabel;
  final String? itemSemanticLabel;
  final Animation<double>? controller;
  final Animation<double>? shimmerController;

  @override
  Widget build(BuildContext context) {
    final disableAnimations =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final activeController = disableAnimations
        ? null
        : (controller ??
              shimmerController ??
              VnlfSkeletonShimmerScope.maybeOf(context));

    return VnlfSkeletonShimmerScope(
      controller: activeController,
      child: Semantics(
        label: semanticLabel,
        container: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < itemCount; i++) ...[
              if (i > 0) SizedBox(height: spacing),
              VnlfPostCardSkeleton(
                controller: activeController,
                showTitle: i.isOdd,
                showAttachment: i == 0,
                semanticLabel: itemSemanticLabel,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

typedef VnlfFeedPostsSkeleton = VnlfFeedSkeletonList;

/// Single row skeleton matching a ranked row in [VnlfLeaderboardCard].
class VnlfLeaderboardRowSkeleton extends StatelessWidget {
  const VnlfLeaderboardRowSkeleton({
    super.key,
    this.semanticLabel,
    this.controller,
    this.shimmerController,
  });

  final String? semanticLabel;
  final Animation<double>? controller;
  final Animation<double>? shimmerController;

  @override
  Widget build(BuildContext context) {
    final disableAnimations =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final activeController = disableAnimations
        ? null
        : (controller ??
              shimmerController ??
              VnlfSkeletonShimmerScope.maybeOf(context));

    final row = VnlfSkeletonShimmerScope(
      controller: activeController,
      child: Row(
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
      ),
    );

    if (semanticLabel == null) {
      return row;
    }
    return Semantics(label: semanticLabel, container: true, child: row);
  }
}

/// Skeleton-loading component for the `304px` right-sidebar weekly leaderboard.
class VnlfLeaderboardCardSkeleton extends StatelessWidget {
  const VnlfLeaderboardCardSkeleton({
    super.key,
    this.itemCount = 3,
    this.width = VnlfDimensions.rightSidebarWidth,
    this.showFooter = true,
    this.title = '',
    this.footerCopyright = '',
    this.communityRulesLabel = '',
    this.privacyLabel = '',
    this.semanticLabel,
    this.rowSemanticLabel,
    this.controller,
    this.shimmerController,
  });

  final int itemCount;
  final double width;
  final bool showFooter;
  final String title;
  final String footerCopyright;
  final String communityRulesLabel;
  final String privacyLabel;
  final String? semanticLabel;
  final String? rowSemanticLabel;
  final Animation<double>? controller;
  final Animation<double>? shimmerController;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final disableAnimations =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final activeController = disableAnimations
        ? null
        : (controller ??
              shimmerController ??
              VnlfSkeletonShimmerScope.maybeOf(context));

    return VnlfSkeletonShimmerScope(
      controller: activeController,
      child: Semantics(
        label: semanticLabel,
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
                    borderRadius: BorderRadius.circular(
                      VnlfDimensions.radiusLg,
                    ),
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
                                if (title.isNotEmpty)
                                  Text(
                                    title,
                                    softWrap: true,
                                    style: VnlfTypography.h3(colors.ink)
                                        .copyWith(fontWeight: FontWeight.w700),
                                  )
                                else
                                  const VnlfSkeletonBox(width: 96, height: 14),
                                const VnlfSkeletonBox(width: 68, height: 12),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      for (var i = 0; i < itemCount; i++) ...[
                        if (i > 0) const SizedBox(height: 12),
                        VnlfLeaderboardRowSkeleton(
                          controller: activeController,
                          semanticLabel: rowSemanticLabel,
                        ),
                      ],
                    ],
                  ),
                ),
                if (showFooter &&
                    (footerCopyright.isNotEmpty ||
                        communityRulesLabel.isNotEmpty ||
                        privacyLabel.isNotEmpty)) ...[
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (footerCopyright.isNotEmpty)
                          Text(
                            footerCopyright,
                            softWrap: true,
                            style: VnlfTypography.meta(colors.muted),
                          ),
                        if (communityRulesLabel.isNotEmpty ||
                            privacyLabel.isNotEmpty) ...[
                          if (footerCopyright.isNotEmpty)
                            const SizedBox(height: 4),
                          Wrap(
                            spacing: 10,
                            runSpacing: 4,
                            children: [
                              if (communityRulesLabel.isNotEmpty)
                                Text(
                                  communityRulesLabel,
                                  softWrap: true,
                                  style: VnlfTypography.meta(colors.muted),
                                ),
                              if (privacyLabel.isNotEmpty)
                                Text(
                                  privacyLabel,
                                  softWrap: true,
                                  style: VnlfTypography.meta(colors.muted),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

typedef VnlfLeaderboardSkeleton = VnlfLeaderboardCardSkeleton;
