import 'package:flutter/material.dart';

import '../tokens/vnlf_colors.dart';
import '../tokens/vnlf_dimensions.dart';
import '../tokens/vnlf_typography.dart';

/// Shared empty and error state card primitive adhering to `DESIGN_REFERENCE.md`.
///
/// Renders Vietnamese copy with full diacritic support, AA contrast, semantic
/// labels, and clean text wrapping at all text-scaling factors.
class VnlfStateCard extends StatelessWidget {
  const VnlfStateCard({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.isError = false,
    this.compact = false,
    this.embedded = false,
    this.semanticLabel,
    this.actionSemanticLabel,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool isError;
  final bool compact;
  final bool embedded;
  final String? semanticLabel;
  final String? actionSemanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final accentColor = isError ? colors.red : colors.brand;
    final badgeBg = isError
        ? colors.red.withValues(alpha: colors.isDark ? 0.16 : 0.1)
        : colors.brandSoft;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: compact
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Container(
          width: compact ? 36 : 44,
          height: compact ? 36 : 44,
          decoration: BoxDecoration(
            color: badgeBg,
            shape: BoxShape.circle,
            border: Border.all(color: accentColor.withValues(alpha: 0.28)),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: compact ? 18 : 22, color: accentColor),
        ),
        if (title.isNotEmpty) ...[
          SizedBox(height: compact ? 10 : 12),
          Text(
            title,
            softWrap: true,
            textAlign: compact ? TextAlign.start : TextAlign.center,
            style: compact
                ? VnlfTypography.h3(colors.ink)
                : VnlfTypography.h2(colors.ink),
          ),
        ],
        if (message.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            message,
            softWrap: true,
            textAlign: compact ? TextAlign.start : TextAlign.center,
            style: VnlfTypography.body(colors.muted),
          ),
        ],
        if (onAction != null &&
            actionLabel != null &&
            actionLabel!.isNotEmpty) ...[
          SizedBox(height: compact ? 12 : 16),
          Semantics(
            button: true,
            label: actionSemanticLabel ?? actionLabel,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(VnlfDimensions.radiusMd),
                onTap: onAction,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 12 : 16,
                    vertical: compact ? 7 : 9,
                  ),
                  decoration: BoxDecoration(
                    color: isError ? colors.surfaceSoft : colors.brandSoft,
                    borderRadius: BorderRadius.circular(
                      VnlfDimensions.radiusMd,
                    ),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh_rounded, size: 16, color: accentColor),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          actionLabel!,
                          softWrap: true,
                          style: VnlfTypography.control(
                            accentColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );

    final body = embedded
        ? Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: content,
          )
        : Container(
            width: double.infinity,
            padding: EdgeInsets.all(compact ? 16 : 24),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(VnlfDimensions.radiusLg),
              border: Border.all(color: colors.line),
            ),
            child: content,
          );

    final combinedLabel = [
      if (title.isNotEmpty) title,
      if (message.isNotEmpty) message,
    ].join('. ');
    final effectiveSemantics =
        semanticLabel ?? (combinedLabel.isNotEmpty ? combinedLabel : null);

    return Semantics(label: effectiveSemantics, container: true, child: body);
  }
}

/// Empty state component for the community feed.
class VnlfFeedEmptyState extends StatelessWidget {
  const VnlfFeedEmptyState({
    super.key,
    this.title = '',
    this.message = '',
    this.actionLabel,
    this.onRetry,
    this.semanticLabel,
    this.actionSemanticLabel,
  });

  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onRetry;
  final String? semanticLabel;
  final String? actionSemanticLabel;

  @override
  Widget build(BuildContext context) {
    return VnlfStateCard(
      icon: Icons.article_outlined,
      title: title,
      message: message,
      actionLabel: actionLabel,
      onAction: onRetry,
      isError: false,
      semanticLabel: semanticLabel,
      actionSemanticLabel: actionSemanticLabel,
    );
  }
}

/// Error state component for the community feed.
class VnlfFeedErrorState extends StatelessWidget {
  const VnlfFeedErrorState({
    super.key,
    this.title = '',
    this.message = '',
    this.retryLabel = '',
    this.onRetry,
    this.semanticLabel,
    this.actionSemanticLabel,
  });

  final String title;
  final String message;
  final String retryLabel;
  final VoidCallback? onRetry;
  final String? semanticLabel;
  final String? actionSemanticLabel;

  @override
  Widget build(BuildContext context) {
    return VnlfStateCard(
      icon: Icons.error_outline_rounded,
      title: title,
      message: message,
      actionLabel: retryLabel,
      onAction: onRetry,
      isError: true,
      semanticLabel: semanticLabel,
      actionSemanticLabel: actionSemanticLabel,
    );
  }
}

/// Empty state component for the `304px` right-sidebar weekly leaderboard.
class VnlfLeaderboardEmptyState extends StatelessWidget {
  const VnlfLeaderboardEmptyState({
    super.key,
    this.headerTitle = '',
    this.title = '',
    this.message = '',
    this.actionLabel,
    this.onRetry,
    this.width = VnlfDimensions.rightSidebarWidth,
    this.embedded = false,
    this.semanticLabel,
    this.actionSemanticLabel,
  });

  final String headerTitle;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onRetry;
  final double width;
  final bool embedded;
  final String? semanticLabel;
  final String? actionSemanticLabel;

  @override
  Widget build(BuildContext context) {
    final inner = VnlfStateCard(
      icon: Icons.emoji_events_outlined,
      title: title,
      message: message,
      actionLabel: actionLabel,
      onAction: onRetry,
      isError: false,
      compact: true,
      embedded: true,
      semanticLabel: semanticLabel,
      actionSemanticLabel: actionSemanticLabel,
    );

    if (embedded) {
      return inner;
    }

    return _LeaderboardStateShell(
      width: width,
      headerTitle: headerTitle,
      child: inner,
    );
  }
}

/// Error state component for the `304px` right-sidebar weekly leaderboard.
class VnlfLeaderboardErrorState extends StatelessWidget {
  const VnlfLeaderboardErrorState({
    super.key,
    this.headerTitle = '',
    this.title = '',
    this.message = '',
    this.retryLabel = '',
    this.onRetry,
    this.width = VnlfDimensions.rightSidebarWidth,
    this.embedded = false,
    this.semanticLabel,
    this.actionSemanticLabel,
  });

  final String headerTitle;
  final String title;
  final String message;
  final String retryLabel;
  final VoidCallback? onRetry;
  final double width;
  final bool embedded;
  final String? semanticLabel;
  final String? actionSemanticLabel;

  @override
  Widget build(BuildContext context) {
    final inner = VnlfStateCard(
      icon: Icons.warning_amber_rounded,
      title: title,
      message: message,
      actionLabel: retryLabel,
      onAction: onRetry,
      isError: true,
      compact: true,
      embedded: true,
      semanticLabel: semanticLabel,
      actionSemanticLabel: actionSemanticLabel,
    );

    if (embedded) {
      return inner;
    }

    return _LeaderboardStateShell(
      width: width,
      headerTitle: headerTitle,
      child: inner,
    );
  }
}

class _LeaderboardStateShell extends StatelessWidget {
  const _LeaderboardStateShell({
    required this.width,
    required this.headerTitle,
    required this.child,
  });

  final double width;
  final String headerTitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: width),
      child: SizedBox(
        width: width,
        child: Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(VnlfDimensions.radiusLg),
            border: Border.all(color: colors.line),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (headerTitle.isNotEmpty) ...[
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
                      child: Text(
                        headerTitle,
                        softWrap: true,
                        style: VnlfTypography.h3(colors.ink)
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              child,
            ],
          ),
        ),
      ),
    );
  }
}
