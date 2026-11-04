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

/// Weekly Leaderboard widget ("Xếp hạng tuần") displayed in the `304px` right
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
  });

  final List<LeaderboardEntryData> entries;
  final ValueChanged<AuthorData>? onAuthorTap;
  final double width;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return VnlfLeaderboardCardSkeleton(width: width);
    }

    final colors = VnlfColors.of(context);

    return ConstrainedBox(
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
                            Text(
                              'Xem tất cả ↗',
                              softWrap: true,
                              style: VnlfTypography.meta(
                                colors.brand,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (errorMessage != null)
                    VnlfLeaderboardErrorState(
                      embedded: true,
                      message: errorMessage!,
                      onRetry: onRetry,
                    )
                  else if (entries.isEmpty)
                    VnlfLeaderboardEmptyState(embedded: true, onRetry: onRetry)
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
        ),
      ),
    );
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
