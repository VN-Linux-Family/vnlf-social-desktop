import 'package:flutter/material.dart';

import '../../icons/vnlf_icon.dart';

import '../../tokens/vnlf_colors.dart';
import '../../tokens/vnlf_dimensions.dart';
import '../../tokens/vnlf_typography.dart';
import '../brand_assets.dart';
import '../vnlf_avatar.dart';
import '../vnlf_shell.dart';
import 'vnlf_sidebar_tiles.dart';

export 'vnlf_theme_segment_picker.dart' show VnlfThemeSegmentPicker;

/// Desktop Left Sidebar (`252px`) matching the permanent left column in
/// `DESIGN_REFERENCE.md` and `reference_feed_desktop.png`.
class VnlfDesktopSidebar extends StatelessWidget {
  const VnlfDesktopSidebar({
    super.key,
    required this.activeDestination,
    this.onDestinationSelected,
    this.themeMode = ThemeMode.light,
    this.onThemeModeChanged,
    this.onProfileTap,
    this.profileAvatar,
    this.onSettingsTap,
    this.onLogoutTap,
    this.onHelpTap,
    this.onFeedbackTap,
    this.onSupportTap,
    this.onFacebookTap,
    this.onTelegramTap,
    this.onDiscordTap,
    this.isDrawer = false,
    this.width = VnlfDimensions.leftSidebarWidth,
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
    this.logoutLabel = '',
    this.settingsSemanticLabel,
    this.helpLabel = '',
    this.helpSemanticLabel,
    this.loginUtilitySemanticLabel,
    this.lightThemeTooltip = '',
    this.darkThemeTooltip = '',
    this.systemThemeTooltip = '',
    this.themePickerSemanticLabel,
    this.profileSemanticLabel,
    this.unreadDestinations = const {},
    this.semanticLabel,
  });

  /// Right complementary column width (`304px`) from `DESIGN_REFERENCE.md`.
  static const double rightSidebarWidth = VnlfDimensions.rightSidebarWidth;

  /// The highlighted item; null on pages that are not in the menu.
  final VnlfNavDestination? activeDestination;
  final ValueChanged<VnlfNavDestination>? onDestinationSelected;
  final Set<VnlfNavDestination> unreadDestinations;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode>? onThemeModeChanged;
  final VoidCallback? onProfileTap;

  /// The member's 38px rounded avatar; guests get the "?" box.
  final Widget? profileAvatar;
  final VoidCallback? onSettingsTap;
  final VoidCallback? onLogoutTap;
  final VoidCallback? onHelpTap;
  final VoidCallback? onFeedbackTap;
  final VoidCallback? onSupportTap;
  final VoidCallback? onFacebookTap;
  final VoidCallback? onTelegramTap;
  final VoidCallback? onDiscordTap;
  final bool isDrawer;
  final double width;
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
  final String logoutLabel;
  final String? settingsSemanticLabel;
  final String helpLabel;
  final String? helpSemanticLabel;
  final String? loginUtilitySemanticLabel;
  final String lightThemeTooltip;
  final String darkThemeTooltip;
  final String systemThemeTooltip;
  final String? themePickerSemanticLabel;
  final String? profileSemanticLabel;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);

    final sidebar = ConstrainedBox(
      constraints: isDrawer
          ? const BoxConstraints(minWidth: 0, maxWidth: double.infinity)
          : BoxConstraints.tightFor(width: width),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: isDrawer ? double.infinity : width,
            decoration: BoxDecoration(
              color: colors.bg,
              border: isDrawer
                  ? null
                  : Border(right: BorderSide(color: colors.line)),
            ),
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 14),
            child: CustomScrollView(
              slivers: [
                SliverList.list(
                  children: [
                    // Brand Logo Header
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          BrandAssets.logo(
                            size: 30,
                            semanticLabel: brandLogoSemanticLabel,
                          ),
                          const SizedBox(width: 9),
                          RichText(
                            text: TextSpan(
                              style: VnlfTypography.h3(colors.ink)
                                  .copyWith(fontWeight: FontWeight.w800),
                              children: [
                                TextSpan(text: brandTitlePrefix),
                                TextSpan(
                                  text: brandTitleAccent,
                                  style: TextStyle(
                                    color: colors.brand,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Login / Profile Prompt Pill
                    Semantics(
                      button: true,
                      label:
                          profileSemanticLabel ??
                          (loginLabel.isNotEmpty ? loginLabel : null),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(
                          VnlfDimensions.radiusMd,
                        ),
                        onTap: onProfileTap,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 6,
                          ),
                          child: Row(
                            children: [
                              profileAvatar ??
                                  VnlfGuestAvatarBox(
                                    size: 38,
                                    semanticLabel: profileSemanticLabel,
                                  ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (loginLabel.isNotEmpty)
                                      Text(
                                        loginLabel,
                                        style: VnlfTypography.control(
                                          colors.ink,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    if (loginSubtitleLabel.isNotEmpty)
                                      Text(
                                        loginSubtitleLabel,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: VnlfTypography.meta(
                                          colors.muted,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              VnlfIcon(
                                VnlfLucide.chevronDown,
                                size: 15,
                                color: colors.ink,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Primary Navigation Links
                    for (final dest in VnlfNavDestination.values) ...[
                      SidebarNavTile(
                        icon: dest.icon,
                        label: destinationLabels[dest] ?? '',
                        semanticLabel:
                            destinationSemanticLabels[dest] ??
                            destinationLabels[dest],
                        selected: dest == activeDestination,
                        hasUnread: unreadDestinations.contains(dest),
                        onTap: () => onDestinationSelected?.call(dest),
                      ),
                      const SizedBox(height: 2),
                    ],

                    // Special support tile
                    if (supportLabel.isNotEmpty ||
                        supportBadgeText.isNotEmpty) ...[
                      SidebarSupportTile(
                        label: supportLabel,
                        badgeText: supportBadgeText,
                        semanticLabel: supportSemanticLabel,
                        onTap: onSupportTap,
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Soft brand pill: feedback & bug report
                    if (feedbackLabel.isNotEmpty) ...[
                      Semantics(
                        button: true,
                        label: feedbackSemanticLabel ?? feedbackLabel,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(
                              VnlfDimensions.radiusMd,
                            ),
                            onTap: onFeedbackTap,
                            child: Container(
                              decoration: BoxDecoration(
                                color: colors.brandSoft,
                                borderRadius: BorderRadius.circular(
                                  VnlfDimensions.radiusMd,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              child: Row(
                                children: [
                                  VnlfIcon(
                                    VnlfLucide.messageSquareText,
                                    size: 18,
                                    color: colors.brand,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      feedbackLabel,
                                      style: VnlfTypography.control(
                                        colors.brand,
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
                      const SizedBox(height: 12),
                    ],
                    Divider(color: colors.line, height: 1),
                    const SizedBox(height: 12),

                    // Community Social Links
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (socialSectionLabel.isNotEmpty) ...[
                            Text(
                              socialSectionLabel,
                              style: VnlfTypography.meta(colors.muted),
                            ),
                            const SizedBox(height: 10),
                          ],
                          // Wraps instead of overflowing in the 220px tablet sidebar.
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              SocialCircleBadge(
                                compact: !isDrawer,
                                label: facebookBadgeLabel.isNotEmpty
                                    ? facebookBadgeLabel
                                    : null,
                                assetPath: facebookBadgeLabel.isEmpty
                                    ? 'assets/images/social-facebook.webp'
                                    : null,
                                semanticLabel: facebookSemanticLabel,
                                onTap: onFacebookTap,
                              ),
                              SocialCircleBadge(
                                compact: !isDrawer,
                                assetPath: 'assets/images/social-telegram.webp',
                                semanticLabel: telegramSemanticLabel,
                                onTap: onTelegramTap,
                              ),
                              SocialCircleBadge(
                                compact: !isDrawer,
                                assetPath: 'assets/images/social-discord.webp',
                                semanticLabel: discordSemanticLabel,
                                onTap: onDiscordTap,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Utility Bottom Links
                      if (settingsLabel.isNotEmpty)
                        SidebarUtilityTile(
                          icon: VnlfLucide.settings,
                          label: settingsLabel,
                          semanticLabel: settingsSemanticLabel,
                          onTap: onSettingsTap,
                        ),
                      if (helpLabel.isNotEmpty)
                        SidebarUtilityTile(
                          icon: VnlfLucide.circleHelp,
                          label: helpLabel,
                          semanticLabel: helpSemanticLabel,
                          onTap: onHelpTap,
                        ),
                      if (onLogoutTap != null)
                        SidebarUtilityTile(
                          icon: VnlfLucide.logOut,
                          label: logoutLabel,
                          semanticLabel: logoutLabel,
                          onTap: onLogoutTap,
                        )
                      else if (loginLabel.isNotEmpty)
                        SidebarUtilityTile(
                          icon: VnlfLucide.logOut,
                          label: loginLabel,
                          semanticLabel: loginUtilitySemanticLabel,
                          onTap: onProfileTap,
                        ),
                      const SizedBox(height: 8),

                      // 3-State Theme Picker Segment Control
                      VnlfThemeSegmentPicker(
                        themeMode: themeMode,
                        onThemeModeChanged: onThemeModeChanged,
                        lightTooltip: lightThemeTooltip,
                        darkTooltip: darkThemeTooltip,
                        systemTooltip: systemThemeTooltip,
                        semanticLabel: themePickerSemanticLabel,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (semanticLabel == null) {
      return sidebar;
    }
    return Semantics(label: semanticLabel, container: true, child: sidebar);
  }
}

/// The website's right rail (`aside.right-rail`): 304px, the full height
/// beside the scrolling center, with a hairline on its left. Its content
/// does not scroll with the page; the footer sits under the cards.
class VnlfDesktopRightSidebar extends StatelessWidget {
  const VnlfDesktopRightSidebar({
    super.key,
    required this.child,
    this.footer,
    this.width = VnlfDimensions.rightSidebarWidth,
    this.semanticLabel,
  });

  final Widget child;
  final Widget? footer;
  final double width;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final column = Container(
      width: width,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: colors.line)),
      ),
      // The website clips the rail; scrolling keeps large text reachable.
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 34, 20, 25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [child, ?footer],
        ),
      ),
    );

    if (semanticLabel == null) {
      return column;
    }
    return Semantics(label: semanticLabel, container: true, child: column);
  }
}

/// The website's rail footer: the copyright line, then policy links that
/// turn brand on hover.
class VnlfRailFooter extends StatelessWidget {
  const VnlfRailFooter({
    super.key,
    required this.copyright,
    required this.links,
  });

  final String copyright;
  final List<(String, VoidCallback)> links;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 7),
      child: Wrap(
        spacing: 9,
        runSpacing: 4,
        children: [
          SizedBox(
            width: double.infinity,
            child: Text(copyright, style: VnlfTypography.body(colors.muted)),
          ),
          for (final (label, onTap) in links) _FooterLink(label, onTap),
        ],
      ),
    );
  }
}

class _FooterLink extends StatefulWidget {
  const _FooterLink(this.label, this.onTap);

  final String label;
  final VoidCallback onTap;

  @override
  State<_FooterLink> createState() => _FooterLinkState();
}

class _FooterLinkState extends State<_FooterLink> {
  var _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    return Semantics(
      link: true,
      child: InkWell(
        onTap: widget.onTap,
        onHover: (value) => setState(() => _hovered = value),
        child: Text(
          widget.label,
          style: VnlfTypography.body(_hovered ? colors.brand : colors.muted),
        ),
      ),
    );
  }
}
