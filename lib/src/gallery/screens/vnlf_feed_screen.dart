import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../fixtures/vnlf_gallery_fixtures.dart';

/// Key Screen 1: Community Feed (`Bảng tin`) matching `reference_feed_desktop.png`
/// across Phone (`<= 840px`), Tablet (`841px - 1180px`), and Desktop (`>= 1181px`).
class VnlfFeedScreen extends StatefulWidget {
  const VnlfFeedScreen({
    super.key,
    this.themeMode = ThemeMode.light,
    this.onThemeModeChanged,
    this.onOpenThread,
    this.onOpenProfile,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode>? onThemeModeChanged;
  final VoidCallback? onOpenThread;
  final VoidCallback? onOpenProfile;

  @override
  State<VnlfFeedScreen> createState() => _VnlfFeedScreenState();
}

class _VnlfFeedScreenState extends State<VnlfFeedScreen> {
  static const List<String> _feedTabs = [
    'Mới nhất',
    'Được chú ý',
    'Article',
    'Đang theo dõi',
  ];

  int _selectedTabIndex = 0;
  late List<PostData> _posts;

  @override
  void initState() {
    super.initState();
    _posts = List<PostData>.of(VnlfGalleryFixtures.feedPosts);
  }

  void _updatePostVote(int index, VoteState nextVote) {
    final current = _posts[index];
    final delta = nextVote.value - current.viewerVote.value;
    setState(() {
      _posts[index] = current.copyWith(
        viewerVote: nextVote,
        voteScore: current.voteScore + delta,
      );
    });
  }

  void _toggleBookmark(int index) {
    final current = _posts[index];
    setState(() {
      _posts[index] = current.copyWith(isBookmarked: !current.isBookmarked);
    });
  }

  @override
  Widget build(BuildContext context) {
    final visiblePosts = _selectedTabIndex == 2
        ? _posts.where((p) => p.isArticle).toList()
        : _posts;

    return VnlfAdaptiveShell(
      activeDestination: VnlfNavDestination.feed,
      themeMode: widget.themeMode,
      onThemeModeChanged: widget.onThemeModeChanged,
      onProfileTap: widget.onOpenProfile,
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
      collapseSidebarSemanticLabel:
          VnlfGalleryFixtures.collapseSidebarSemanticLabel,
      rightSidebarChild: VnlfLeaderboardCard(
        entries: VnlfGalleryFixtures.weeklyLeaderboard,
        onAuthorTap: (_) => widget.onOpenProfile?.call(),
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
      centerChild: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VnlfCenterPageHeader(
            title: 'Bảng tin',
            onProfileTap: widget.onOpenProfile,
          ),
          const SizedBox(height: 6),
          VnlfFeedTabBar(
            tabs: _feedTabs,
            selectedIndex: _selectedTabIndex,
            onTabSelected: (index) => setState(() => _selectedTabIndex = index),
          ),
          const SizedBox(height: 12),
          VnlfComposerPromptCard(
            promptText: VnlfGalleryFixtures.composerPromptText,
            addMediaSemanticLabel: VnlfGalleryFixtures.addMediaSemanticLabel,
            onTap: widget.onOpenThread,
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < visiblePosts.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            VnlfPostCard(
              post: visiblePosts[i],
              codeCopyLabel: VnlfGalleryFixtures.codeCopyLabel,
              codeCopiedLabel: VnlfGalleryFixtures.codeCopiedLabel,
              moreOptionsSemanticLabel:
                  VnlfGalleryFixtures.moreOptionsSemanticLabel,
              voteSemanticLabel: VnlfGalleryFixtures.voteCapsuleSemanticLabel(
                visiblePosts[i].voteScore,
              ),
              upvoteSemanticLabel: VnlfGalleryFixtures.upvoteSemanticLabel,
              downvoteSemanticLabel: VnlfGalleryFixtures.downvoteSemanticLabel,
              commentSemanticLabel:
                  VnlfGalleryFixtures.commentActionSemanticLabel,
              shareSemanticLabel: VnlfGalleryFixtures.shareActionSemanticLabel,
              bookmarkSemanticLabel:
                  VnlfGalleryFixtures.bookmarkActionSemanticLabel,
              onVoteChanged: (next) =>
                  _updatePostVote(_posts.indexOf(visiblePosts[i]), next),
              onCommentTap: widget.onOpenThread,
              onAuthorTap: widget.onOpenProfile,
              onBookmarkToggle: () =>
                  _toggleBookmark(_posts.indexOf(visiblePosts[i])),
            ),
          ],
        ],
      ),
    );
  }
}
