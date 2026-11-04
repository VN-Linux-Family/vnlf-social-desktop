import 'package:flutter/material.dart';

import '../../../design_system/design_system.dart';

/// Top profile header card presenting user identity, bio, badges, and stats.
class VnlfProfileHeaderCard extends StatelessWidget {
  const VnlfProfileHeaderCard({super.key, required this.author});

  final AuthorData author;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(VnlfDimensions.radiusLg),
        border: Border.all(color: colors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner
          Container(
            height: 96,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [colors.brandStrong, colors.brand],
              ),
            ),
            padding: const EdgeInsets.all(12),
            alignment: Alignment.topRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: colors.surface.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(VnlfDimensions.radiusFull),
              ),
              child: Text(
                'Hạng #1 Tuần · 88 Điểm',
                style: VnlfTypography.caption(
                  colors.surface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar + Action Buttons Row
                Row(
                  children: [
                    VnlfAvatar(author: author, size: 64),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          VnlfAuthorNameRow(
                            author: author,
                            showHandleInline: false,
                            fontSize: 16,
                          ),
                          const SizedBox(height: 3),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                '@${author.username}',
                                style: VnlfTypography.meta(colors.muted),
                              ),
                              const VnlfDistroBadgePill(
                                badge: DistroBadgeType.nixos,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: colors.brand,
                        borderRadius: BorderRadius.circular(
                          VnlfDimensions.radiusMd,
                        ),
                      ),
                      child: Text(
                        'Theo dõi',
                        style: VnlfTypography.control(
                          colors.isDark ? colors.bg : colors.surface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Kỹ sư hệ thống & yêu thích mã nguồn mở. Đang xây dựng công cụ quản lý âm thanh và giao diện dòng lệnh cho cộng đồng Linux Việt Nam (Tiếng Việt: ặ ữ ờ ẫ ệ).',
                  style: VnlfTypography.body(colors.ink),
                ),
                const SizedBox(height: 10),

                // Meta Info Pills
                Wrap(
                  spacing: 14,
                  runSpacing: 6,
                  children: [
                    VnlfProfileMetaItem(
                      icon: Icons.location_on_outlined,
                      label: 'Đà Nẵng, Việt Nam',
                      color: colors.muted,
                    ),
                    VnlfProfileMetaItem(
                      icon: Icons.link_rounded,
                      label: 'community.vn/@lethimai',
                      color: colors.blue,
                    ),
                    VnlfProfileMetaItem(
                      icon: Icons.calendar_today_outlined,
                      label: 'Tham gia Tháng 3, 2025',
                      color: colors.muted,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Divider(color: colors.line, height: 1),
                const SizedBox(height: 12),

                // Stats Row
                Wrap(
                  alignment: WrapAlignment.spaceAround,
                  spacing: 12,
                  runSpacing: 10,
                  children: const [
                    VnlfProfileStatCell(value: '1,450', label: 'Điểm Karma'),
                    VnlfProfileStatCell(value: '28', label: 'Bài viết'),
                    VnlfProfileStatCell(value: '184', label: 'Người theo dõi'),
                    VnlfProfileStatCell(value: '4', label: 'Dự án mã nguồn'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class VnlfProfileMetaItem extends StatelessWidget {
  const VnlfProfileMetaItem({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Flexible(child: Text(label, style: VnlfTypography.meta(color))),
      ],
    );
  }
}

class VnlfProfileStatCell extends StatelessWidget {
  const VnlfProfileStatCell({
    super.key,
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);

    return Column(
      children: [
        Text(
          value,
          style: VnlfTypography.h2(colors.ink).copyWith(fontSize: 16),
        ),
        const SizedBox(height: 2),
        Text(label, style: VnlfTypography.caption(colors.muted)),
      ],
    );
  }
}
