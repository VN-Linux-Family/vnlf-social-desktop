import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../fixtures/vnlf_gallery_fixtures.dart';
import 'profile/vnlf_profile_header.dart';

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
    const profileAuthor = VnlfGalleryFixtures.authorNam;

    return VnlfAdaptiveShell(
      activeDestination: VnlfNavDestination.feed,
      themeMode: widget.themeMode,
      onThemeModeChanged: widget.onThemeModeChanged,
      destinationLabels: VnlfGalleryFixtures.destinationLabels,
      brandTitlePrefix: VnlfGalleryFixtures.brandTitlePrefix,
      brandTitleAccent: VnlfGalleryFixtures.brandTitleAccent,
      brandLogoSemanticLabel: VnlfGalleryFixtures.brandLogoSemanticLabel,
      loginLabel: VnlfGalleryFixtures.loginLabel,
      loginSubtitleLabel: VnlfGalleryFixtures.loginSubtitleLabel,
      supportLabel: VnlfGalleryFixtures.supportLabel,
      supportBadgeText: VnlfGalleryFixtures.supportBadgeText,
      feedbackLabel: VnlfGalleryFixtures.feedbackLabel,
      socialSectionLabel: VnlfGalleryFixtures.socialSectionLabel,
      facebookBadgeLabel: VnlfGalleryFixtures.facebookBadgeLabel,
      facebookSemanticLabel: VnlfGalleryFixtures.facebookSemanticLabel,
      telegramSemanticLabel: VnlfGalleryFixtures.telegramSemanticLabel,
      discordSemanticLabel: VnlfGalleryFixtures.discordSemanticLabel,
      settingsLabel: VnlfGalleryFixtures.settingsLabel,
      helpLabel: VnlfGalleryFixtures.helpLabel,
      lightThemeTooltip: VnlfGalleryFixtures.lightThemeTooltip,
      darkThemeTooltip: VnlfGalleryFixtures.darkThemeTooltip,
      systemThemeTooltip: VnlfGalleryFixtures.systemThemeTooltip,
      themePickerSemanticLabel: VnlfGalleryFixtures.themePickerSemanticLabel,
      railThemeToggleTooltip: VnlfGalleryFixtures.railThemeToggleTooltip,
      openDrawerTooltip: VnlfGalleryFixtures.openDrawerTooltip,
      searchSemanticLabel: VnlfGalleryFixtures.searchSemanticLabel,
      notificationsSemanticLabel:
          VnlfGalleryFixtures.notificationsSemanticLabel,
      profileSemanticLabel: VnlfGalleryFixtures.profileSemanticLabel,
      rightSidebarChild: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _WardrobeSummaryCard(author: profileAuthor),
          const SizedBox(height: 16),
          const VnlfLeaderboardCard(
            entries: VnlfGalleryFixtures.weeklyLeaderboard,
            title: VnlfGalleryFixtures.leaderboardTitle,
            viewAllLabel: VnlfGalleryFixtures.leaderboardViewAllLabel,
            footerCopyright: VnlfGalleryFixtures.footerCopyright,
            communityRulesLabel: VnlfGalleryFixtures.communityRulesLabel,
            privacyLabel: VnlfGalleryFixtures.privacyLabel,
            emptyTitle: VnlfGalleryFixtures.leaderboardEmptyTitle,
            emptyMessage: VnlfGalleryFixtures.leaderboardEmptyMessage,
            emptyActionLabel: VnlfGalleryFixtures.refreshActionLabel,
            errorTitle: VnlfGalleryFixtures.leaderboardErrorTitle,
            retryLabel: VnlfGalleryFixtures.retryActionLabel,
            loadingSemanticLabel:
                VnlfGalleryFixtures.leaderboardLoadingSemanticLabel,
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
          const VnlfProfileHeaderCard(author: profileAuthor),
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
                codeCopyLabel: VnlfGalleryFixtures.codeCopyLabel,
                codeCopiedLabel: VnlfGalleryFixtures.codeCopiedLabel,
                moreOptionsSemanticLabel:
                    VnlfGalleryFixtures.moreOptionsSemanticLabel,
                voteSemanticLabel: VnlfGalleryFixtures.voteCapsuleSemanticLabel(
                  VnlfGalleryFixtures.feedPosts[i].voteScore,
                ),
                upvoteSemanticLabel: VnlfGalleryFixtures.upvoteSemanticLabel,
                downvoteSemanticLabel:
                    VnlfGalleryFixtures.downvoteSemanticLabel,
                commentSemanticLabel:
                    VnlfGalleryFixtures.commentActionSemanticLabel,
                shareSemanticLabel:
                    VnlfGalleryFixtures.shareActionSemanticLabel,
                bookmarkSemanticLabel:
                    VnlfGalleryFixtures.bookmarkActionSemanticLabel,
                onCommentTap: widget.onOpenThread,
              ),
            ],
          ],
        ],
      ),
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
          _WardrobeAttrRow(
            label: 'Khung đại diện',
            value: 'Vòng tròn viền (Ring)',
          ),
          const SizedBox(height: 8),
          _WardrobeAttrRow(label: 'Hiệu ứng tên', value: 'Tiêu chuẩn'),
          const SizedBox(height: 8),
          _WardrobeAttrRow(label: 'Huy hiệu Distro', value: 'Fedora Linux'),
          const SizedBox(height: 8),
          _WardrobeAttrRow(label: 'Danh hiệu', value: 'Thành viên đóng góp'),
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
