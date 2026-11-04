import 'package:flutter/material.dart';

import '../models/vnlf_models.dart';
import '../tokens/vnlf_colors.dart';
import '../tokens/vnlf_dimensions.dart';
import '../tokens/vnlf_typography.dart';
import 'vnlf_author_identity.dart';
import 'vnlf_avatar.dart';
import 'vnlf_skeleton.dart';
import 'vnlf_state_cards.dart';

export 'vnlf_skeleton.dart'
    show
        VnlfLeaderboardCardSkeleton,
        VnlfLeaderboardRowSkeleton,
        VnlfLeaderboardSkeleton;
export 'vnlf_state_cards.dart'
    show VnlfLeaderboardEmptyState, VnlfLeaderboardErrorState;

/// Weekly Leaderboard widget displayed in the `304px` right
/// sidebar on Desktop (`>= 1181px`) and in the component gallery.
class VnlfLeaderboardCard extends StatelessWidget {
  const VnlfLeaderboardCard({
    super.key,
    required this.entries,
    this.onAuthorTap,
    this.width = VnlfDimensions.rightSidebarWidth,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
    this.title = '',
    this.viewAllLabel = '',
    this.onViewAll,
    this.footerCopyright = '',
    this.communityRulesLabel = '',
    this.privacyLabel = '',
    this.emptyTitle = '',
    this.emptyMessage = '',
    this.emptyActionLabel,
    this.errorTitle = '',
    this.retryLabel = '',
    this.semanticLabel,
    this.viewAllSemanticLabel,
    this.loadingSemanticLabel,
    this.emptySemanticLabel,
    this.errorSemanticLabel,
  });

  final List<LeaderboardEntryData> entries;
  final ValueChanged<AuthorData>? onAuthorTap;
  final double width;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final String title;
  final String viewAllLabel;
  final VoidCallback? onViewAll;
  final String footerCopyright;
  final String communityRulesLabel;
  final String privacyLabel;
  final String emptyTitle;
  final String emptyMessage;
  final String? emptyActionLabel;
  final String errorTitle;
  final String retryLabel;
  final String? semanticLabel;
  final String? viewAllSemanticLabel;
  final String? loadingSemanticLabel;
  final String? emptySemanticLabel;
  final String? errorSemanticLabel;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return VnlfLeaderboardCardSkeleton(
        width: width,
        title: title,
        footerCopyright: footerCopyright,
        communityRulesLabel: communityRulesLabel,
        privacyLabel: privacyLabel,
        semanticLabel: loadingSemanticLabel,
      );
    }

    final colors = VnlfColors.of(context);

    final card = ConstrainedBox(
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
                  if (title.isNotEmpty || viewAllLabel.isNotEmpty) ...[
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
                                ),
                              if (viewAllLabel.isNotEmpty)
                                Semantics(
                                  button: true,
                                  label: viewAllSemanticLabel ?? viewAllLabel,
                                  child: InkWell(
                                    onTap: onViewAll,
                                    child: Text(
                                      viewAllLabel,
                                      softWrap: true,
                                      style: VnlfTypography.meta(
                                        colors.brand,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                  ],
                  if (errorMessage != null)
                    VnlfLeaderboardErrorState(
                      embedded: true,
                      title: errorTitle,
                      message: errorMessage!,
                      retryLabel: retryLabel,
                      onRetry: onRetry,
                      semanticLabel: errorSemanticLabel,
                    )
                  else if (entries.isEmpty)
                    VnlfLeaderboardEmptyState(
                      embedded: true,
                      title: emptyTitle,
                      message: emptyMessage,
                      actionLabel: emptyActionLabel,
                      onRetry: onRetry,
                      semanticLabel: emptySemanticLabel,
                    )
                  else
                    for (var i = 0; i < entries.length; i++) ...[
                      if (i > 0) const SizedBox(height: 12),
                      _LeaderboardRow(
                        entry: entries[i],
                        onTap: onAuthorTap == null
                            ? null
                            : () => onAuthorTap!(entries[i].author),
                      ),
                    ],
                ],
              ),
            ),
            if (footerCopyright.isNotEmpty ||
                communityRulesLabel.isNotEmpty ||
                privacyLabel.isNotEmpty) ...[
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
                      if (footerCopyright.isNotEmpty) const SizedBox(height: 4),
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
    );

    if (semanticLabel == null) {
      return card;
    }
    return Semantics(label: semanticLabel, container: true, child: card);
  }
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({required this.entry, this.onTap});

  final LeaderboardEntryData entry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(VnlfDimensions.radiusSm),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 20,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '${entry.rank}',
                softWrap: true,
                style: VnlfTypography.meta(
                  colors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          VnlfAvatar(author: entry.author, size: 34),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VnlfAuthorNameRow(
                  author: entry.author,
                  showHandleInline: false,
                  fontSize: 13,
                  allowWrap: true,
                ),
                const SizedBox(height: 1),
                Text(
                  '@${entry.author.username}',
                  softWrap: true,
                  style: VnlfTypography.meta(colors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '${entry.points}',
              softWrap: true,
              style: VnlfTypography.control(
                colors.brand,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
