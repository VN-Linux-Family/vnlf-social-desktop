import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens/vnlf_colors.dart';
import '../tokens/vnlf_dimensions.dart';
import '../tokens/vnlf_typography.dart';
import 'shell/vnlf_bottom_bar.dart';
import 'shell/vnlf_rail.dart';
import 'shell/vnlf_sidebar.dart';

export 'shell/vnlf_bottom_bar.dart';
export 'shell/vnlf_center_header.dart';
export 'shell/vnlf_rail.dart';
export 'shell/vnlf_sidebar.dart';

/// Primary navigation destinations in the VNLF app shell.
enum VnlfNavDestination {
  feed(Icons.grid_view_rounded),
  explore(Icons.explore_outlined),
  messages(Icons.chat_bubble_outline_rounded),
  voice(Icons.mic_none_rounded),
  projects(Icons.workspaces_outline);

  const VnlfNavDestination(this.icon);
  final IconData icon;
}

/// Adaptive application shell implementing the 3 production viewports from
/// `DESIGN_REFERENCE.md` and `reference_feed_desktop.png`:
/// - Desktop (`>= 1181px`): 252px Left Sidebar + 717px Center Column + 304px Right Column.
/// - Tablet (`841px - 1180px`): Compact Navigation Rail + Center Column.
/// - Mobile (`<= 840px`): Sticky 64px Top Header + Full-Width Feed + Sticky 56px Bottom Nav + Drawer.
class VnlfAdaptiveShell extends StatelessWidget {
  const VnlfAdaptiveShell({
    super.key,
    required this.centerChild,
    this.rightSidebarChild,
    this.centerChildHandlesScroll = false,
    this.centerPadding,
    this.centerMaxWidth = 1053,
    this.showMobileBottomNav = true,
    this.showMobileHeader = true,
    this.activeDestination = VnlfNavDestination.feed,
    this.onDestinationSelected,
    this.themeMode = ThemeMode.light,
    this.onThemeModeChanged,
    this.onProfileTap,
    this.onSearchTap,
    this.onNotificationsTap,
    this.onBack,
    this.backTooltip = '',
    this.backSemanticLabel,
    this.onSettingsTap,
    this.onLogoutTap,
    this.logoutLabel = '',
    this.onHelpTap,
    this.onFeedbackTap,
    this.onSupportTap,
    this.onFacebookTap,
    this.onTelegramTap,
    this.onDiscordTap,
    this.destinationLabels = const {},
    this.destinationSemanticLabels = const {},
    this.brandTitlePrefix = '',
    this.brandTitleAccent = '',
    this.brandLogoSemanticLabel,
    this.loginLabel = '',
    this.loginSubtitleLabel = '',
    this.supportLabel = '',
    this.supportBadgeText = '',
    this.supportSemanticLabel,
    this.feedbackLabel = '',
    this.feedbackSemanticLabel,
    this.socialSectionLabel = '',
    this.facebookBadgeLabel = '',
    this.facebookSemanticLabel,
    this.telegramSemanticLabel,
    this.discordSemanticLabel,
    this.settingsLabel = '',
    this.settingsSemanticLabel,
    this.helpLabel = '',
    this.helpSemanticLabel,
    this.loginUtilitySemanticLabel,
    this.lightThemeTooltip = '',
    this.darkThemeTooltip = '',
    this.systemThemeTooltip = '',
    this.themePickerSemanticLabel,
    this.railThemeToggleTooltip = '',
    this.railThemeToggleSemanticLabel,
    this.openDrawerTooltip = '',
    this.openDrawerSemanticLabel,
    this.titleText,
    this.searchSemanticLabel = '',
    this.notificationsSemanticLabel = '',
    this.profileSemanticLabel,
    this.collapseSidebarSemanticLabel,
    this.leftSidebarSemanticLabel,
    this.rightSidebarSemanticLabel,
    this.tabletRailSemanticLabel,
    this.mobileHeaderSemanticLabel,
    this.mobileBottomNavSemanticLabel,
    this.unreadDestinations = const {},
    this.notificationBadgeCount = 0,
    this.semanticLabel,
  });

  final Widget centerChild;
  final bool centerChildHandlesScroll;
  final bool showMobileHeader;
  final Widget? rightSidebarChild;
  final EdgeInsets? centerPadding;
  final double centerMaxWidth;
  final bool showMobileBottomNav;
  final VnlfNavDestination activeDestination;
  final ValueChanged<VnlfNavDestination>? onDestinationSelected;
  final Set<VnlfNavDestination> unreadDestinations;
  final int notificationBadgeCount;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode>? onThemeModeChanged;
  final VoidCallback? onProfileTap;
  final VoidCallback? onSearchTap;
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onBack;
  final String backTooltip;
  final String? backSemanticLabel;
  final VoidCallback? onSettingsTap;
  final VoidCallback? onLogoutTap;
  final String logoutLabel;
  final VoidCallback? onHelpTap;
  final VoidCallback? onFeedbackTap;
  final VoidCallback? onSupportTap;
  final VoidCallback? onFacebookTap;
  final VoidCallback? onTelegramTap;
  final VoidCallback? onDiscordTap;
  final Map<VnlfNavDestination, String> destinationLabels;
  final Map<VnlfNavDestination, String> destinationSemanticLabels;
  final String brandTitlePrefix;
  final String brandTitleAccent;
  final String? brandLogoSemanticLabel;
  final String loginLabel;
  final String loginSubtitleLabel;
  final String supportLabel;
  final String supportBadgeText;
  final String? supportSemanticLabel;
  final String feedbackLabel;
  final String? feedbackSemanticLabel;
  final String socialSectionLabel;
  final String facebookBadgeLabel;
  final String? facebookSemanticLabel;
  final String? telegramSemanticLabel;
  final String? discordSemanticLabel;
  final String settingsLabel;
  final String? settingsSemanticLabel;
  final String helpLabel;
  final String? helpSemanticLabel;
  final String? loginUtilitySemanticLabel;
  final String lightThemeTooltip;
  final String darkThemeTooltip;
  final String systemThemeTooltip;
  final String? themePickerSemanticLabel;
  final String railThemeToggleTooltip;
  final String? railThemeToggleSemanticLabel;
  final String openDrawerTooltip;
  final String? openDrawerSemanticLabel;
  final String? titleText;
  final String searchSemanticLabel;
  final String notificationsSemanticLabel;
  final String? profileSemanticLabel;
  final String? collapseSidebarSemanticLabel;
  final String? leftSidebarSemanticLabel;
  final String? rightSidebarSemanticLabel;
  final String? tabletRailSemanticLabel;
  final String? mobileHeaderSemanticLabel;
  final String? mobileBottomNavSemanticLabel;
  final String? semanticLabel;

  Widget _scrollArea({required EdgeInsets padding, required Widget child}) =>
      centerChildHandlesScroll
      ? Padding(padding: padding, child: child)
      : SingleChildScrollView(padding: padding, child: child);

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);

    final shell = LayoutBuilder(
      builder: (context, constraints) {
        final viewport = VnlfViewportSize.fromWidth(constraints.maxWidth);

        return switch (viewport) {
          VnlfViewportSize.desktop => Scaffold(
            key: const ValueKey('vnlf-shell-scaffold-desktop'),
            backgroundColor: colors.bg,
            body: SafeArea(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  VnlfDesktopSidebar(
                    activeDestination: activeDestination,
                    onDestinationSelected: onDestinationSelected,
                    unreadDestinations: unreadDestinations,
                    themeMode: themeMode,
                    onThemeModeChanged: onThemeModeChanged,
                    onProfileTap: onProfileTap,
                    onSettingsTap: onSettingsTap,
                    onLogoutTap: onLogoutTap,
                    logoutLabel: logoutLabel,
                    onHelpTap: onHelpTap,
                    onFeedbackTap: onFeedbackTap,
                    onSupportTap: onSupportTap,
                    onFacebookTap: onFacebookTap,
                    onTelegramTap: onTelegramTap,
                    onDiscordTap: onDiscordTap,
                    destinationLabels: destinationLabels,
                    destinationSemanticLabels: destinationSemanticLabels,
                    brandTitlePrefix: brandTitlePrefix,
                    brandTitleAccent: brandTitleAccent,
                    brandLogoSemanticLabel: brandLogoSemanticLabel,
                    loginLabel: loginLabel,
                    loginSubtitleLabel: loginSubtitleLabel,
                    supportLabel: supportLabel,
                    supportBadgeText: supportBadgeText,
                    supportSemanticLabel: supportSemanticLabel,
                    feedbackLabel: feedbackLabel,
                    feedbackSemanticLabel: feedbackSemanticLabel,
                    socialSectionLabel: socialSectionLabel,
                    facebookBadgeLabel: facebookBadgeLabel,
                    facebookSemanticLabel: facebookSemanticLabel,
                    telegramSemanticLabel: telegramSemanticLabel,
                    discordSemanticLabel: discordSemanticLabel,
                    settingsLabel: settingsLabel,
                    settingsSemanticLabel: settingsSemanticLabel,
                    helpLabel: helpLabel,
                    helpSemanticLabel: helpSemanticLabel,
                    loginUtilitySemanticLabel: loginUtilitySemanticLabel,
                    lightThemeTooltip: lightThemeTooltip,
                    darkThemeTooltip: darkThemeTooltip,
                    systemThemeTooltip: systemThemeTooltip,
                    themePickerSemanticLabel: themePickerSemanticLabel,
                    profileSemanticLabel: profileSemanticLabel,
                    collapseSidebarSemanticLabel: collapseSidebarSemanticLabel,
                    semanticLabel: leftSidebarSemanticLabel,
                  ),
                  Expanded(
                    child: _scrollArea(
                      padding:
                          centerPadding ??
                          const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 20,
                          ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: centerMaxWidth),
                          child: Row(
                            crossAxisAlignment: centerChildHandlesScroll
                                ? CrossAxisAlignment.stretch
                                : CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: centerMaxWidth == double.infinity
                                        ? double.infinity
                                        : VnlfDimensions.centerFeedMaxWidth,
                                  ),
                                  child: centerChild,
                                ),
                              ),
                              if (rightSidebarChild != null) ...[
                                const SizedBox(width: 28),
                                VnlfDesktopRightSidebar(
                                  width: VnlfDimensions.rightSidebarWidth,
                                  semanticLabel: rightSidebarSemanticLabel,
                                  child: centerChildHandlesScroll
                                      ? SingleChildScrollView(
                                          child: rightSidebarChild!,
                                        )
                                      : rightSidebarChild!,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          VnlfViewportSize.tablet => Scaffold(
            key: const ValueKey('vnlf-shell-scaffold-tablet'),
            backgroundColor: colors.bg,
            body: SafeArea(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  VnlfTabletRail(
                    activeDestination: activeDestination,
                    onDestinationSelected: onDestinationSelected,
                    unreadDestinations: unreadDestinations,
                    themeMode: themeMode,
                    onThemeModeChanged: onThemeModeChanged,
                    onProfileTap: onProfileTap,
                    onLogoutTap: onLogoutTap,
                    logoutLabel: logoutLabel,
                    destinationLabels: destinationLabels,
                    destinationSemanticLabels: destinationSemanticLabels,
                    brandLogoSemanticLabel: brandLogoSemanticLabel,
                    themeToggleTooltip: railThemeToggleTooltip,
                    themeToggleSemanticLabel: railThemeToggleSemanticLabel,
                    profileSemanticLabel: profileSemanticLabel,
                    semanticLabel: tabletRailSemanticLabel,
                  ),
                  Expanded(
                    child: _scrollArea(
                      padding:
                          centerPadding ??
                          const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: VnlfDimensions.centerFeedMaxWidth,
                          ),
                          child: centerChild,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          VnlfViewportSize.mobile => Scaffold(
            key: const ValueKey('vnlf-shell-scaffold-mobile'),
            backgroundColor: colors.bg,
            drawer: SizedBox(
              width: math.min(
                VnlfDimensions.mobileDrawerMaxWidth,
                constraints.maxWidth * 0.86,
              ),
              child: Drawer(
                backgroundColor: colors.bg,
                surfaceTintColor: Colors.transparent,
                child: SafeArea(
                  child: VnlfDesktopSidebar(
                    activeDestination: activeDestination,
                    unreadDestinations: unreadDestinations,
                    onDestinationSelected: (dest) {
                      Navigator.of(context).maybePop();
                      onDestinationSelected?.call(dest);
                    },
                    themeMode: themeMode,
                    onThemeModeChanged: onThemeModeChanged,
                    onProfileTap: () {
                      Navigator.of(context).maybePop();
                      onProfileTap?.call();
                    },
                    onSettingsTap: () {
                      Navigator.of(context).maybePop();
                      onSettingsTap?.call();
                    },
                    onLogoutTap: onLogoutTap == null
                        ? null
                        : () {
                            Navigator.of(context).maybePop();
                            onLogoutTap?.call();
                          },
                    logoutLabel: logoutLabel,
                    onHelpTap: () {
                      Navigator.of(context).maybePop();
                      onHelpTap?.call();
                    },
                    onFeedbackTap: () {
                      Navigator.of(context).maybePop();
                      onFeedbackTap?.call();
                    },
                    onSupportTap: () {
                      Navigator.of(context).maybePop();
                      onSupportTap?.call();
                    },
                    onFacebookTap: () {
                      Navigator.of(context).maybePop();
                      onFacebookTap?.call();
                    },
                    onTelegramTap: () {
                      Navigator.of(context).maybePop();
                      onTelegramTap?.call();
                    },
                    onDiscordTap: () {
                      Navigator.of(context).maybePop();
                      onDiscordTap?.call();
                    },
                    isDrawer: true,
                    destinationLabels: destinationLabels,
                    destinationSemanticLabels: destinationSemanticLabels,
                    brandTitlePrefix: brandTitlePrefix,
                    brandTitleAccent: brandTitleAccent,
                    brandLogoSemanticLabel: brandLogoSemanticLabel,
                    loginLabel: loginLabel,
                    loginSubtitleLabel: loginSubtitleLabel,
                    supportLabel: supportLabel,
                    supportBadgeText: supportBadgeText,
                    supportSemanticLabel: supportSemanticLabel,
                    feedbackLabel: feedbackLabel,
                    feedbackSemanticLabel: feedbackSemanticLabel,
                    socialSectionLabel: socialSectionLabel,
                    facebookBadgeLabel: facebookBadgeLabel,
                    facebookSemanticLabel: facebookSemanticLabel,
                    telegramSemanticLabel: telegramSemanticLabel,
                    discordSemanticLabel: discordSemanticLabel,
                    settingsLabel: settingsLabel,
                    settingsSemanticLabel: settingsSemanticLabel,
                    helpLabel: helpLabel,
                    helpSemanticLabel: helpSemanticLabel,
                    loginUtilitySemanticLabel: loginUtilitySemanticLabel,
                    lightThemeTooltip: lightThemeTooltip,
                    darkThemeTooltip: darkThemeTooltip,
                    systemThemeTooltip: systemThemeTooltip,
                    themePickerSemanticLabel: themePickerSemanticLabel,
                    profileSemanticLabel: profileSemanticLabel,
                    semanticLabel: leftSidebarSemanticLabel,
                  ),
                ),
              ),
            ),
            body: Column(
              children: [
                if (showMobileHeader)
                  VnlfMobileStickyHeader(
                    onProfileTap: onProfileTap,
                    onBack: onBack,
                    backTooltip: backTooltip,
                    backSemanticLabel: backSemanticLabel,
                    openDrawerTooltip: openDrawerTooltip,
                    openDrawerSemanticLabel: openDrawerSemanticLabel,
                    titleText: titleText,
                    brandTitlePrefix: brandTitlePrefix,
                    brandTitleAccent: brandTitleAccent,
                    brandLogoSemanticLabel: brandLogoSemanticLabel,
                    searchSemanticLabel: searchSemanticLabel,
                    onSearchTap: onSearchTap,
                    onNotificationsTap: onNotificationsTap,
                    notificationBadgeCount: notificationBadgeCount,
                    notificationsSemanticLabel: notificationsSemanticLabel,
                    profileSemanticLabel: profileSemanticLabel,
                    semanticLabel: mobileHeaderSemanticLabel,
                  )
                else
                  SizedBox(height: MediaQuery.paddingOf(context).top),
                Expanded(
                  child: SafeArea(
                    top: false,
                    bottom: false,
                    child: _scrollArea(
                      padding:
                          centerPadding ??
                          const EdgeInsets.fromLTRB(12, 12, 12, 20),
                      child: centerChild,
                    ),
                  ),
                ),
              ],
            ),
            bottomNavigationBar: !showMobileBottomNav
                ? null
                : VnlfMobileBottomNav(
                    activeDestination: activeDestination,
                    onDestinationSelected: onDestinationSelected,
                    destinationLabels: destinationLabels,
                    destinationSemanticLabels: destinationSemanticLabels,
                    unreadDestinations: unreadDestinations,
                    semanticLabel: mobileBottomNavSemanticLabel,
                  ),
          ),
        };
      },
    );

    if (semanticLabel == null) {
      return shell;
    }
    return Semantics(label: semanticLabel, container: true, child: shell);
  }
}

/// Feed Tab Bar matching `reference_feed_desktop.png`.
class VnlfFeedTabBar extends StatelessWidget {
  const VnlfFeedTabBar({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    this.onTabSelected,
    this.semanticLabel,
    this.tabSemanticLabels,
  });

  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int>? onTabSelected;
  final String? semanticLabel;
  final List<String>? tabSemanticLabels;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);

    final bar = Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.line)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < tabs.length; i++)
              Padding(
                padding: const EdgeInsets.only(right: 22),
                child: Semantics(
                  button: true,
                  selected: i == selectedIndex,
                  label:
                      (tabSemanticLabels != null &&
                          i < tabSemanticLabels!.length)
                      ? tabSemanticLabels![i]
                      : tabs[i],
                  child: InkWell(
                    onTap: onTabSelected == null
                        ? null
                        : () {
                            HapticFeedback.selectionClick();
                            onTabSelected!(i);
                          },
                    child: Container(
                      padding: const EdgeInsets.only(top: 12, bottom: 10),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: i == selectedIndex
                                ? colors.ink
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Text(
                        tabs[i],
                        style: VnlfTypography.control(
                          i == selectedIndex ? colors.ink : colors.muted,
                          fontWeight: i == selectedIndex
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    if (semanticLabel == null) {
      return bar;
    }
    return Semantics(label: semanticLabel, container: true, child: bar);
  }
}
