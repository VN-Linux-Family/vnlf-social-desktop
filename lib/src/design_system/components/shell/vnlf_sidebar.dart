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
    this.isDrawer = false,
  });

  final VnlfNavDestination activeDestination;
  final ValueChanged<VnlfNavDestination>? onDestinationSelected;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode>? onThemeModeChanged;
  final VoidCallback? onProfileTap;
  final bool isDrawer;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: isDrawer ? double.infinity : VnlfDimensions.leftSidebarWidth,
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
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  children: [
                    BrandAssets.logo(size: 30),
                    const SizedBox(width: 9),
                    RichText(
                      text: TextSpan(
                        style: VnlfTypography.h3(
                          colors.ink,
                        ).copyWith(fontSize: 15, fontWeight: FontWeight.w800),
                        children: [
                          const TextSpan(text: 'VNLF '),
                          TextSpan(
                            text: 'Social',
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
              InkWell(
                borderRadius: BorderRadius.circular(VnlfDimensions.radiusMd),
                onTap: onProfileTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      const VnlfGuestAvatarBox(size: 34),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Đăng nhập',
                              style: VnlfTypography.control(
                                colors.ink,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Để dùng đầy đủ tí...',
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
              const SizedBox(height: 14),

              // Primary Navigation Links
              for (final dest in VnlfNavDestination.values) ...[
                SidebarNavTile(
                  icon: dest.icon,
                  label: dest.label,
                  selected: dest == activeDestination,
                  onTap: () => onDestinationSelected?.call(dest),
                ),
                const SizedBox(height: 2),
              ],

              // Special support tile
              SidebarSupportTile(onTap: () {}),
              const SizedBox(height: 8),

              // Soft brand pill: "Góp ý & báo lỗi"
              Container(
                decoration: BoxDecoration(
                  color: colors.brandSoft,
                  borderRadius: BorderRadius.circular(VnlfDimensions.radiusMd),
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
                        'Góp ý & báo lỗi',
                        style: VnlfTypography.control(
                          colors.brand,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Divider(color: colors.line, height: 1),
              const SizedBox(height: 12),

              // Community Social Links
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'VNLF trên các mạng xã hội khác',
                      style: VnlfTypography.meta(colors.muted),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: const [
                        SocialCircleBadge(label: 'f'),
                        SizedBox(width: 8),
                        SocialCircleBadge(icon: Icons.send_rounded),
                        SizedBox(width: 8),
                        SocialCircleBadge(icon: Icons.sports_esports_rounded),
                      ],
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Utility Bottom Links
              const SidebarUtilityTile(
                icon: Icons.settings_outlined,
                label: 'Cài đặt',
              ),
              const SidebarUtilityTile(
                icon: Icons.help_outline_rounded,
                label: 'Trợ giúp',
              ),
              SidebarUtilityTile(
                icon: Icons.login_rounded,
                label: 'Đăng nhập',
                onTap: onProfileTap,
              ),
              const SizedBox(height: 8),

              // 3-State Theme Picker Segment Control
              VnlfThemeSegmentPicker(
                themeMode: themeMode,
                onThemeModeChanged: onThemeModeChanged,
              ),
            ],
          ),
        ),
        if (!isDrawer)
          Positioned(
            top: 26,
            right: -11,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: colors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: colors.line),
                boxShadow: VnlfDimensions.subtleShadow(isDark: colors.isDark),
              ),
              child: Icon(
                Icons.chevron_left_rounded,
                size: 14,
                color: colors.muted,
              ),
            ),
          ),
      ],
    );
  }
}
