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
          VnlfViewportSize.mobile => _MobileShellScaffold(
            colors: colors,
            constraints: constraints,
            activeDestination: activeDestination,
            unreadDestinations: unreadDestinations,
            themeMode: themeMode,
            onThemeModeChanged: onThemeModeChanged,
            onDestinationSelected: onDestinationSelected,
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
            leftSidebarSemanticLabel: leftSidebarSemanticLabel,
            showMobileHeader: showMobileHeader,
            showMobileBottomNav: showMobileBottomNav,
            onBack: onBack,
            backTooltip: backTooltip,
            backSemanticLabel: backSemanticLabel,
            openDrawerTooltip: openDrawerTooltip,
            openDrawerSemanticLabel: openDrawerSemanticLabel,
            titleText: titleText,
            searchSemanticLabel: searchSemanticLabel,
            onSearchTap: onSearchTap,
            onNotificationsTap: onNotificationsTap,
            notificationBadgeCount: notificationBadgeCount,
            notificationsSemanticLabel: notificationsSemanticLabel,
            mobileHeaderSemanticLabel: mobileHeaderSemanticLabel,
            mobileBottomNavSemanticLabel: mobileBottomNavSemanticLabel,
            centerPadding: centerPadding,
            centerChildHandlesScroll: centerChildHandlesScroll,
            centerChild: centerChild,
          ),
        };
      },
    );

    final scopedShell = PopScope(
      canPop: activeDestination == VnlfNavDestination.feed && onBack == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          if (onBack != null) {
            onBack!();
          } else if (onDestinationSelected != null) {
            onDestinationSelected!(VnlfNavDestination.feed);
          }
        }
      },
      child: shell,
    );

    if (semanticLabel == null) {
      return scopedShell;
    }
    return Semantics(label: semanticLabel, container: true, child: scopedShell);
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

class _MobileShellScaffold extends StatefulWidget {
  const _MobileShellScaffold({
    required this.colors,
    required this.constraints,
    required this.activeDestination,
    required this.unreadDestinations,
    required this.themeMode,
    required this.onThemeModeChanged,
    required this.onDestinationSelected,
    required this.onProfileTap,
    required this.onSettingsTap,
    required this.onLogoutTap,
    required this.logoutLabel,
    required this.onHelpTap,
    required this.onFeedbackTap,
    required this.onSupportTap,
    required this.onFacebookTap,
    required this.onTelegramTap,
    required this.onDiscordTap,
    required this.destinationLabels,
    required this.destinationSemanticLabels,
    required this.brandTitlePrefix,
    required this.brandTitleAccent,
    required this.brandLogoSemanticLabel,
    required this.loginLabel,
    required this.loginSubtitleLabel,
    required this.supportLabel,
    required this.supportBadgeText,
    required this.supportSemanticLabel,
    required this.feedbackLabel,
    required this.feedbackSemanticLabel,
    required this.socialSectionLabel,
    required this.facebookBadgeLabel,
    required this.facebookSemanticLabel,
    required this.telegramSemanticLabel,
    required this.discordSemanticLabel,
    required this.settingsLabel,
    required this.settingsSemanticLabel,
    required this.helpLabel,
    required this.helpSemanticLabel,
    required this.loginUtilitySemanticLabel,
    required this.lightThemeTooltip,
    required this.darkThemeTooltip,
    required this.systemThemeTooltip,
    required this.themePickerSemanticLabel,
    required this.profileSemanticLabel,
    required this.leftSidebarSemanticLabel,
    required this.showMobileHeader,
    required this.showMobileBottomNav,
    required this.onBack,
    required this.backTooltip,
    required this.backSemanticLabel,
    required this.openDrawerTooltip,
    required this.openDrawerSemanticLabel,
    required this.titleText,
    required this.searchSemanticLabel,
    required this.onSearchTap,
    required this.onNotificationsTap,
    required this.notificationBadgeCount,
    required this.notificationsSemanticLabel,
    required this.mobileHeaderSemanticLabel,
    required this.mobileBottomNavSemanticLabel,
    required this.centerPadding,
    required this.centerChildHandlesScroll,
    required this.centerChild,
  });

  final VnlfColors colors;
  final BoxConstraints constraints;
  final VnlfNavDestination activeDestination;
  final Set<VnlfNavDestination> unreadDestinations;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode>? onThemeModeChanged;
  final ValueChanged<VnlfNavDestination>? onDestinationSelected;
  final VoidCallback? onProfileTap;
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
  final String? profileSemanticLabel;
  final String? leftSidebarSemanticLabel;
  final bool showMobileHeader;
  final bool showMobileBottomNav;
  final VoidCallback? onBack;
  final String backTooltip;
  final String? backSemanticLabel;
  final String openDrawerTooltip;
  final String? openDrawerSemanticLabel;
  final String? titleText;
  final String searchSemanticLabel;
  final VoidCallback? onSearchTap;
  final VoidCallback? onNotificationsTap;
  final int notificationBadgeCount;
  final String notificationsSemanticLabel;
  final String? mobileHeaderSemanticLabel;
  final String? mobileBottomNavSemanticLabel;
  final EdgeInsets? centerPadding;
  final bool centerChildHandlesScroll;
  final Widget centerChild;

  @override
  State<_MobileShellScaffold> createState() => _MobileShellScaffoldState();
}

class _MobileShellScaffoldState extends State<_MobileShellScaffold> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void didUpdateWidget(covariant _MobileShellScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.centerChild != oldWidget.centerChild ||
        widget.titleText != oldWidget.titleText ||
        widget.activeDestination != oldWidget.activeDestination) {
      if (_scaffoldKey.currentState?.isDrawerOpen == true) {
        _scaffoldKey.currentState?.closeDrawer();
      }
    }
  }

  void _closeDrawer(BuildContext drawerCtx) {
    _scaffoldKey.currentState?.closeDrawer();
    Scaffold.maybeOf(drawerCtx)?.closeDrawer();
    Navigator.of(drawerCtx).maybePop();
  }

  Widget _scrollArea({required EdgeInsets padding, required Widget child}) =>
      widget.centerChildHandlesScroll
      ? Padding(padding: padding, child: child)
      : SingleChildScrollView(padding: padding, child: child);

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_scaffoldKey.currentState?.isDrawerOpen == true) {
          _scaffoldKey.currentState?.closeDrawer();
        } else if (widget.onBack != null) {
          widget.onBack!();
        } else if (widget.activeDestination != VnlfNavDestination.feed) {
          widget.onDestinationSelected?.call(VnlfNavDestination.feed);
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: widget.colors.bg,
        drawer: SizedBox(
          width: math.min(
            VnlfDimensions.mobileDrawerMaxWidth,
            widget.constraints.maxWidth * 0.86,
          ),
          child: Drawer(
            backgroundColor: widget.colors.bg,
            surfaceTintColor: Colors.transparent,
            child: SafeArea(
              child: Builder(
                builder: (drawerCtx) => VnlfDesktopSidebar(
                  activeDestination: widget.activeDestination,
                  unreadDestinations: widget.unreadDestinations,
                  onDestinationSelected: (dest) {
                    _closeDrawer(drawerCtx);
                    widget.onDestinationSelected?.call(dest);
                  },
                  themeMode: widget.themeMode,
                  onThemeModeChanged: widget.onThemeModeChanged,
                  onProfileTap: () {
                    _closeDrawer(drawerCtx);
                    widget.onProfileTap?.call();
                  },
                  onSettingsTap: () {
                    _closeDrawer(drawerCtx);
                    widget.onSettingsTap?.call();
                  },
                  onLogoutTap: widget.onLogoutTap == null
                      ? null
                      : () {
                          _closeDrawer(drawerCtx);
                          widget.onLogoutTap?.call();
                        },
                  logoutLabel: widget.logoutLabel,
                  onHelpTap: () {
                    _closeDrawer(drawerCtx);
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      widget.onHelpTap?.call();
                    });
                  },
                  onFeedbackTap: () {
                    _closeDrawer(drawerCtx);
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      widget.onFeedbackTap?.call();
                    });
                  },
                  onSupportTap: () {
                    _closeDrawer(drawerCtx);
                    widget.onSupportTap?.call();
                  },
                  onFacebookTap: () {
                    _closeDrawer(drawerCtx);
                    widget.onFacebookTap?.call();
                  },
                  onTelegramTap: () {
                    _closeDrawer(drawerCtx);
                    widget.onTelegramTap?.call();
                  },
                  onDiscordTap: () {
                    _closeDrawer(drawerCtx);
                    widget.onDiscordTap?.call();
                  },
                  isDrawer: true,
                  destinationLabels: widget.destinationLabels,
                  destinationSemanticLabels: widget.destinationSemanticLabels,
                  brandTitlePrefix: widget.brandTitlePrefix,
                  brandTitleAccent: widget.brandTitleAccent,
                  brandLogoSemanticLabel: widget.brandLogoSemanticLabel,
                  loginLabel: widget.loginLabel,
                  loginSubtitleLabel: widget.loginSubtitleLabel,
                  supportLabel: widget.supportLabel,
                  supportBadgeText: widget.supportBadgeText,
                  supportSemanticLabel: widget.supportSemanticLabel,
                  feedbackLabel: widget.feedbackLabel,
                  feedbackSemanticLabel: widget.feedbackSemanticLabel,
                  socialSectionLabel: widget.socialSectionLabel,
                  facebookBadgeLabel: widget.facebookBadgeLabel,
                  facebookSemanticLabel: widget.facebookSemanticLabel,
                  telegramSemanticLabel: widget.telegramSemanticLabel,
                  discordSemanticLabel: widget.discordSemanticLabel,
                  settingsLabel: widget.settingsLabel,
                  settingsSemanticLabel: widget.settingsSemanticLabel,
                  helpLabel: widget.helpLabel,
                  helpSemanticLabel: widget.helpSemanticLabel,
                  loginUtilitySemanticLabel: widget.loginUtilitySemanticLabel,
                  lightThemeTooltip: widget.lightThemeTooltip,
                  darkThemeTooltip: widget.darkThemeTooltip,
                  systemThemeTooltip: widget.systemThemeTooltip,
                  themePickerSemanticLabel: widget.themePickerSemanticLabel,
                  profileSemanticLabel: widget.profileSemanticLabel,
                  semanticLabel: widget.leftSidebarSemanticLabel,
                ),
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            if (widget.showMobileHeader)
              VnlfMobileStickyHeader(
                onProfileTap: widget.onProfileTap,
                onBack: widget.onBack,
                backTooltip: widget.backTooltip,
                backSemanticLabel: widget.backSemanticLabel,
                openDrawerTooltip: widget.openDrawerTooltip,
                openDrawerSemanticLabel: widget.openDrawerSemanticLabel,
                titleText: widget.titleText,
                brandTitlePrefix: widget.brandTitlePrefix,
                brandTitleAccent: widget.brandTitleAccent,
                brandLogoSemanticLabel: widget.brandLogoSemanticLabel,
                searchSemanticLabel: widget.searchSemanticLabel,
                onSearchTap: widget.onSearchTap,
                onNotificationsTap: widget.onNotificationsTap,
                notificationBadgeCount: widget.notificationBadgeCount,
                notificationsSemanticLabel: widget.notificationsSemanticLabel,
                profileSemanticLabel: widget.profileSemanticLabel,
                semanticLabel: widget.mobileHeaderSemanticLabel,
              )
            else
              SizedBox(height: MediaQuery.paddingOf(context).top),
            Expanded(
              child: SafeArea(
                top: false,
                bottom: false,
                child: _scrollArea(
                  padding:
                      widget.centerPadding ??
                      const EdgeInsets.fromLTRB(12, 12, 12, 20),
                  child: widget.centerChild,
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: !widget.showMobileBottomNav
            ? null
            : VnlfMobileBottomNav(
                activeDestination: widget.activeDestination,
                onDestinationSelected: widget.onDestinationSelected,
                destinationLabels: widget.destinationLabels,
                destinationSemanticLabels: widget.destinationSemanticLabels,
                unreadDestinations: widget.unreadDestinations,
                semanticLabel: widget.mobileBottomNavSemanticLabel,
              ),
      ),
    );
  }
}
