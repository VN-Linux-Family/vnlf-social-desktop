import 'package:flutter/material.dart';

import '../models/vnlf_models.dart';
import '../tokens/vnlf_colors.dart';
import '../tokens/vnlf_dimensions.dart';
import '../tokens/vnlf_typography.dart';
import 'vnlf_author_identity.dart';
import 'vnlf_avatar.dart';

/// Weekly Leaderboard widget ("Xếp hạng tuần") displayed in the right sidebar
/// on Desktop (`>= 1181px`) and in the component gallery.
class VnlfLeaderboardCard extends StatelessWidget {
  const VnlfLeaderboardCard({
    super.key,
    required this.entries,
    this.onAuthorTap,
  });

  final List<LeaderboardEntryData> entries;
  final ValueChanged<AuthorData>? onAuthorTap;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
                children: [
                  Icon(
                    Icons.emoji_events_outlined,
                    size: 17,
                    color: colors.ink,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      'Xếp hạng tuần',
                      style: VnlfTypography.h3(colors.ink)
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text(
                    'Xem tất cả ↗',
                    style: VnlfTypography.meta(
                      colors.brand,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
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
                style: VnlfTypography.meta(colors.muted),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    'Quy chuẩn cộng đồng',
                    style: VnlfTypography.meta(colors.muted),
                  ),
                  const SizedBox(width: 10),
                  Text('Riêng tư', style: VnlfTypography.meta(colors.muted)),
                ],
              ),
            ],
          ),
        ),
      ],
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
        children: [
          SizedBox(
            width: 16,
            child: Text(
              '${entry.rank}',
              style: VnlfTypography.meta(
                colors.muted,
                fontWeight: FontWeight.w600,
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
                ),
                const SizedBox(height: 1),
                Text(
                  '@${entry.author.username}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: VnlfTypography.meta(colors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${entry.points}',
            style: VnlfTypography.control(
              colors.brand,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
