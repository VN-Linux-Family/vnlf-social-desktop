import 'package:flutter/material.dart';

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
    this.collapseSidebarSemanticLabel,
    this.unreadDestinations = const {},
    this.semanticLabel,
  });

  /// Right complementary column width (`304px`) from `DESIGN_REFERENCE.md`.
  static const double rightSidebarWidth = VnlfDimensions.rightSidebarWidth;

  final VnlfNavDestination activeDestination;
  final ValueChanged<VnlfNavDestination>? onDestinationSelected;
  final Set<VnlfNavDestination> unreadDestinations;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode>? onThemeModeChanged;
  final VoidCallback? onProfileTap;
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
  final String? collapseSidebarSemanticLabel;
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                          style: VnlfTypography.h3(
                            colors.ink,
                          ).copyWith(fontSize: 15, fontWeight: FontWeight.w800),
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
                          VnlfGuestAvatarBox(
                            size: 34,
                            semanticLabel: profileSemanticLabel,
                          ),
                          const SizedBox(width: 10),
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
                                    style: VnlfTypography.meta(colors.muted),
                                  ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 16,
                            color: colors.muted,
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
                if (supportLabel.isNotEmpty || supportBadgeText.isNotEmpty) ...[
                  SidebarSupportTile(
                    label: supportLabel,
                    badgeText: supportBadgeText,
                    semanticLabel: supportSemanticLabel,
                    onTap: onSupportTap ?? () {},
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
                              Icon(
                                Icons.rate_review_outlined,
                                size: 17,
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
                      Row(
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
                          const SizedBox(width: 16),
                          SocialCircleBadge(
                            compact: !isDrawer,
                            assetPath: 'assets/images/social-telegram.webp',
                            semanticLabel: telegramSemanticLabel,
                            onTap: onTelegramTap,
                          ),
                          const SizedBox(width: 16),
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

                const Spacer(),

                // Utility Bottom Links
                if (settingsLabel.isNotEmpty)
                  SidebarUtilityTile(
                    icon: Icons.settings_outlined,
                    label: settingsLabel,
                    semanticLabel: settingsSemanticLabel,
                    onTap: onSettingsTap,
                  ),
                if (helpLabel.isNotEmpty)
                  SidebarUtilityTile(
                    icon: Icons.help_outline_rounded,
                    label: helpLabel,
                    semanticLabel: helpSemanticLabel,
                    onTap: onHelpTap,
                  ),
                if (onLogoutTap != null)
                  SidebarUtilityTile(
                    icon: Icons.logout_rounded,
                    label: logoutLabel,
                    semanticLabel: logoutLabel,
                    onTap: onLogoutTap,
                  )
                else if (loginLabel.isNotEmpty)
                  SidebarUtilityTile(
                    icon: Icons.login_rounded,
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
          if (!isDrawer)
            Positioned(
              top: 26,
              right: -11,
              child: Semantics(
                button: true,
                label: collapseSidebarSemanticLabel,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: colors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.line),
                    boxShadow: VnlfDimensions.subtleShadow(
                      isDark: colors.isDark,
                    ),
                  ),
                  child: Icon(
                    Icons.chevron_left_rounded,
                    size: 14,
                    color: colors.muted,
                  ),
                ),
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

/// Desktop Right Complementary Sidebar (`304px`) matching the right column in
/// `DESIGN_REFERENCE.md` Section 5 and `reference_feed_desktop.png`.
class VnlfDesktopRightSidebar extends StatelessWidget {
  const VnlfDesktopRightSidebar({
    super.key,
    required this.child,
    this.width = VnlfDimensions.rightSidebarWidth,
    this.semanticLabel,
  });

  final Widget child;
  final double width;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final column = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: width),
      child: SizedBox(width: width, child: child),
    );

    if (semanticLabel == null) {
      return column;
    }
    return Semantics(label: semanticLabel, container: true, child: column);
  }
}
