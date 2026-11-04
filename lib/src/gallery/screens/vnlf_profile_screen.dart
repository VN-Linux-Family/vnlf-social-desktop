import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../fixtures/vnlf_gallery_fixtures.dart';

/// Key Screen 3: User Profile & Wardrobe Customization (`Hồ sơ thành viên`)
/// with hero banner, framed avatar, stylized name effects, karma stats,
/// authored posts, and open-source project showcases.
class VnlfProfileScreen extends StatefulWidget {
  const VnlfProfileScreen({
    super.key,
    this.themeMode = ThemeMode.light,
    this.onThemeModeChanged,
    this.onOpenThread,
    this.onBackToFeed,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode>? onThemeModeChanged;
  final VoidCallback? onOpenThread;
  final VoidCallback? onBackToFeed;

  @override
  State<VnlfProfileScreen> createState() => _VnlfProfileScreenState();
}

class _VnlfProfileScreenState extends State<VnlfProfileScreen> {
  static const List<String> _profileTabs = [
    'Bài viết (28)',
    'Dự án (2)',
    'Tủ đồ & Huy hiệu',
  ];

  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    const profileAuthor = VnlfGalleryFixtures.authorHoangDung;

    return VnlfAdaptiveShell(
      activeDestination: VnlfNavDestination.feed,
      themeMode: widget.themeMode,
      onThemeModeChanged: widget.onThemeModeChanged,
      rightSidebarChild: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _WardrobeSummaryCard(author: profileAuthor),
          const SizedBox(height: 16),
          const VnlfLeaderboardCard(
            entries: VnlfGalleryFixtures.weeklyLeaderboard,
          ),
        ],
      ),
      centerChild: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VnlfCenterPageHeader(
            title: 'Hồ sơ thành viên',
            leading: widget.onBackToFeed == null
                ? null
                : InkWell(
                    borderRadius: BorderRadius.circular(
                      VnlfDimensions.radiusMd,
                    ),
                    onTap: widget.onBackToFeed,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(
                          VnlfDimensions.radiusMd,
                        ),
                        border: Border.all(color: colors.line),
                      ),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        size: 17,
                        color: colors.ink,
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 14),

          // Hero Profile Card
          Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(VnlfDimensions.radiusLg),
              border: Border.all(color: colors.line),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Terminal Matrix Hero Banner
                Container(
                  height: 112,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF0E3A24),
                        Color(0xFF155E3B),
                        Color(0xFF0F766E),
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.all(14),
                  alignment: Alignment.topRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(
                        VnlfDimensions.radiusFull,
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      'Hạng #1 Tuần · 75 Điểm',
                      style: VnlfTypography.caption(
                        Colors.white,
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
                          const VnlfAvatar(author: profileAuthor, size: 64),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const VnlfAuthorNameRow(
                                  author: profileAuthor,
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
                                      '@${profileAuthor.username}',
                                      style: VnlfTypography.meta(colors.muted),
                                    ),
                                    const VnlfDistroBadgePill(
                                      badge: DistroBadgeType.arch,
                                    ),
                                    const VnlfDistroBadgePill(
                                      badge: DistroBadgeType.caramos,
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
                                colors.isDark ? colors.bg : Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Bảo trì gói phần mềm CaramOS & đóng góp bộ gõ Tiếng Việt: ặ ữ ờ ẫ ệ trên Wayland. Yêu thích nhân Linux tối giản, Rust và tự động hóa hệ thống.',
                        style: VnlfTypography.body(colors.ink),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 16,
                        runSpacing: 6,
                        children: [
                          _ProfileMetaItem(
                            icon: Icons.location_on_outlined,
                            label: 'Hà Nội, Việt Nam',
                            color: colors.muted,
                          ),
                          _ProfileMetaItem(
                            icon: Icons.link_rounded,
                            label: 'vietnamlinuxfamily.net/@hoangdung_vn',
                            color: colors.blue,
                          ),
                          _ProfileMetaItem(
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
                          _ProfileStatCell(value: '1,450', label: 'Điểm Karma'),
                          _ProfileStatCell(value: '28', label: 'Bài viết'),
                          _ProfileStatCell(
                            value: '184',
                            label: 'Người theo dõi',
                          ),
                          _ProfileStatCell(value: '4', label: 'Dự án mã nguồn'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Profile Content Tabs
          VnlfFeedTabBar(
            tabs: _profileTabs,
            selectedIndex: _selectedTabIndex,
            onTabSelected: (index) => setState(() => _selectedTabIndex = index),
          ),
          const SizedBox(height: 12),

          if (_selectedTabIndex == 1) ...[
            for (
              var i = 0;
              i < VnlfGalleryFixtures.featuredProjects.length;
              i++
            ) ...[
              if (i > 0) const SizedBox(height: 12),
              VnlfProjectPreviewCard(
                project: VnlfGalleryFixtures.featuredProjects[i],
              ),
            ],
          ] else ...[
            for (var i = 0; i < VnlfGalleryFixtures.feedPosts.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              VnlfPostCard(
                post: VnlfGalleryFixtures.feedPosts[i],
                onCommentTap: widget.onOpenThread,
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _ProfileMetaItem extends StatelessWidget {
  const _ProfileMetaItem({
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

class _ProfileStatCell extends StatelessWidget {
  const _ProfileStatCell({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    return Column(
      children: [
        Text(
          value,
          style: VnlfTypography.h3(colors.ink)
              .copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Text(label, style: VnlfTypography.caption(colors.muted)),
      ],
    );
  }
}

class _WardrobeSummaryCard extends StatelessWidget {
  const _WardrobeSummaryCard({required this.author});
  final AuthorData author;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(VnlfDimensions.radiusLg),
        border: Border.all(color: colors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_outlined, size: 16, color: colors.brand),
              const SizedBox(width: 6),
              Text(
                'Tủ đồ & Trang trí hồ sơ',
                style: VnlfTypography.h3(colors.ink),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _WardrobeAttrRow(label: 'Khung đại diện', value: 'Matrix Emerald'),
          const SizedBox(height: 8),
          _WardrobeAttrRow(
            label: 'Hiệu ứng tên',
            value: 'Con trỏ Terminal (█)',
          ),
          const SizedBox(height: 8),
          _WardrobeAttrRow(label: 'Huy hiệu Distro', value: 'Arch Linux'),
          const SizedBox(height: 8),
          _WardrobeAttrRow(label: 'Danh hiệu', value: 'Partner / Top #1 Tuần'),
        ],
      ),
    );
  }
}

class _WardrobeAttrRow extends StatelessWidget {
  const _WardrobeAttrRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: VnlfTypography.meta(colors.muted)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
          decoration: BoxDecoration(
            color: colors.surfaceSoft,
            borderRadius: BorderRadius.circular(VnlfDimensions.radiusSm),
            border: Border.all(color: colors.line),
          ),
          child: Text(
            value,
            style: VnlfTypography.caption(
              colors.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
