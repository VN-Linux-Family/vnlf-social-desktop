import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tokens/vnlf_colors.dart';
import '../tokens/vnlf_dimensions.dart';
import '../tokens/vnlf_typography.dart';
import 'vnlf_avatar.dart';

/// Primary navigation destinations in the VNLF app shell.
enum VnlfNavDestination {
  feed('Bảng tin', Icons.grid_view_rounded),
  explore('Khám phá', Icons.explore_outlined),
  messages('Tin nhắn', Icons.chat_bubble_outline_rounded),
  voice('Voice', Icons.mic_none_rounded),
  projects('Dự án', Icons.workspaces_outline);

  const VnlfNavDestination(this.label, this.icon);
  final String label;
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
    this.activeDestination = VnlfNavDestination.feed,
    this.onDestinationSelected,
    this.themeMode = ThemeMode.light,
    this.onThemeModeChanged,
    this.onProfileTap,
  });

  final Widget centerChild;
  final Widget? rightSidebarChild;
  final VnlfNavDestination activeDestination;
  final ValueChanged<VnlfNavDestination>? onDestinationSelected;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode>? onThemeModeChanged;
  final VoidCallback? onProfileTap;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewport = VnlfViewportSize.fromWidth(constraints.maxWidth);

        return switch (viewport) {
          VnlfViewportSize.desktop => Scaffold(
            backgroundColor: colors.bg,
            body: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                VnlfDesktopSidebar(
                  activeDestination: activeDestination,
                  onDestinationSelected: onDestinationSelected,
                  themeMode: themeMode,
                  onThemeModeChanged: onThemeModeChanged,
                  onProfileTap: onProfileTap,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1053),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: VnlfDimensions.centerFeedMaxWidth,
                                ),
                                child: centerChild,
                              ),
                            ),
                            if (rightSidebarChild != null) ...[
                              const SizedBox(width: 28),
                              SizedBox(
                                width: VnlfDimensions.rightSidebarWidth,
                                child: rightSidebarChild,
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
          VnlfViewportSize.tablet => Scaffold(
            backgroundColor: colors.bg,
            body: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _VnlfTabletRail(
                  activeDestination: activeDestination,
                  onDestinationSelected: onDestinationSelected,
                  themeMode: themeMode,
                  onThemeModeChanged: onThemeModeChanged,
                  onProfileTap: onProfileTap,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
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
          VnlfViewportSize.mobile => Scaffold(
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
                    onDestinationSelected: (dest) {
                      Navigator.of(context).maybePop();
                      onDestinationSelected?.call(dest);
                    },
                    themeMode: themeMode,
                    onThemeModeChanged: onThemeModeChanged,
                    onProfileTap: onProfileTap,
                    isDrawer: true,
                  ),
                ),
              ),
            ),
            body: Column(
              children: [
                _VnlfMobileStickyHeader(onProfileTap: onProfileTap),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
                    child: centerChild,
                  ),
                ),
              ],
            ),
            bottomNavigationBar: _VnlfMobileBottomNav(
              activeDestination: activeDestination,
              onDestinationSelected: onDestinationSelected,
            ),
          ),
        };
      },
    );
  }
}

/// Top header bar inside the center column on Desktop/Tablet (`Bảng tin` + search/bell/avatar buttons).
class VnlfCenterPageHeader extends StatelessWidget {
  const VnlfCenterPageHeader({
    super.key,
    required this.title,
    this.leading,
    this.onProfileTap,
  });

  final String title;
  final Widget? leading;
  final VoidCallback? onProfileTap;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final isMobile =
        MediaQuery.sizeOf(context).width <= VnlfDimensions.mobileMaxWidth;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: isMobile ? 10 : 14),
          child: Row(
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 10)],
              Expanded(
                child: Text(title, style: VnlfTypography.h1(colors.ink)),
              ),
              if (!isMobile) ...[
                _HeaderSquareIconButton(
                  icon: Icons.search_rounded,
                  semanticLabel: 'Tìm kiếm',
                  onTap: () {},
                ),
                const SizedBox(width: 8),
                _HeaderSquareIconButton(
                  icon: Icons.notifications_none_rounded,
                  semanticLabel: 'Thông báo',
                  onTap: () {},
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onProfileTap,
                  child: const VnlfGuestAvatarBox(size: 36),
                ),
              ],
            ],
          ),
        ),
        Divider(color: colors.line, height: 1, thickness: 1),
      ],
    );
  }
}

/// Feed Tab Bar (`Mới nhất`, `Được chú ý`, `Article`, `Đang theo dõi`) matching `reference_feed_desktop.png`.
class VnlfFeedTabBar extends StatelessWidget {
  const VnlfFeedTabBar({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    this.onTabSelected,
  });

  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int>? onTabSelected;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);

    return Container(
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
                child: InkWell(
                  onTap: onTabSelected == null ? null : () => onTabSelected!(i),
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
          ],
        ),
      ),
    );
  }
}

/// Fixed 252px Left Sidebar matching `reference_feed_desktop.png`.
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
                    const VnlfLogoEmblem(size: 30),
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
                _SidebarNavTile(
                  icon: dest.icon,
                  label: dest.label,
                  selected: dest == activeDestination,
                  onTap: () => onDestinationSelected?.call(dest),
                ),
                const SizedBox(height: 2),
              ],

              // Special "Hỗ trợ CaramOS" item with orange star + green "3" badge
              _SidebarCaramOsTile(onTap: () {}),
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
                        _SocialCircleBadge(label: 'f'),
                        SizedBox(width: 8),
                        _SocialCircleBadge(icon: Icons.send_rounded),
                        SizedBox(width: 8),
                        _SocialCircleBadge(icon: Icons.sports_esports_rounded),
                      ],
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Utility Bottom Links
              _SidebarUtilityTile(
                icon: Icons.settings_outlined,
                label: 'Cài đặt',
              ),
              _SidebarUtilityTile(
                icon: Icons.help_outline_rounded,
                label: 'Trợ giúp',
              ),
              _SidebarUtilityTile(
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

/// 3-state segment toggle (`Sáng`, `Tối`, `Tự động`) at the bottom of the sidebar.
class VnlfThemeSegmentPicker extends StatelessWidget {
  const VnlfThemeSegmentPicker({
    super.key,
    required this.themeMode,
    this.onThemeModeChanged,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode>? onThemeModeChanged;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);

    return Container(
      height: 36,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colors.surfaceSoft,
        borderRadius: BorderRadius.circular(VnlfDimensions.radiusLg),
        border: Border.all(color: colors.line),
      ),
      child: Row(
        children: [
          _SegmentBtn(
            icon: Icons.wb_sunny_outlined,
            tooltip: 'Sáng',
            selected: themeMode == ThemeMode.light,
            onTap: () => onThemeModeChanged?.call(ThemeMode.light),
          ),
          _SegmentBtn(
            icon: Icons.dark_mode_outlined,
            tooltip: 'Tối',
            selected: themeMode == ThemeMode.dark,
            onTap: () => onThemeModeChanged?.call(ThemeMode.dark),
          ),
          _SegmentBtn(
            icon: Icons.desktop_windows_outlined,
            tooltip: 'Tự động',
            selected: themeMode == ThemeMode.system,
            onTap: () => onThemeModeChanged?.call(ThemeMode.system),
          ),
        ],
      ),
    );
  }
}

/// Custom painted VNLF circular emblem matching top-left logo in `reference_feed_desktop.png`.
class VnlfLogoEmblem extends StatelessWidget {
  const VnlfLogoEmblem({super.key, this.size = 30.0});
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _VnlfLogoPainter(
          brandColor: colors.brand,
          inkColor: colors.ink,
        ),
      ),
    );
  }
}

class _VnlfLogoPainter extends CustomPainter {
  const _VnlfLogoPainter({required this.brandColor, required this.inkColor});

  final Color brandColor;
  final Color inkColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 1.5;

    // Outer green ring
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = brandColor
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke,
    );

    // Network / distro nodes inside
    final p1 = Offset(size.width * 0.34, size.height * 0.34);
    final p2 = Offset(size.width * 0.34, size.height * 0.66);
    final p3 = Offset(size.width * 0.68, size.height * 0.5);

    final linePaint = Paint()
      ..color = inkColor
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    canvas.drawLine(p1, p3, linePaint);
    canvas.drawLine(p2, p3, linePaint);

    canvas.drawCircle(p1, 2.5, Paint()..color = brandColor);
    canvas.drawCircle(p2, 2.5, Paint()..color = inkColor);
    canvas.drawCircle(p3, 2.8, Paint()..color = const Color(0xFFD99A06));
  }

  @override
  bool shouldRepaint(covariant _VnlfLogoPainter oldDelegate) =>
      oldDelegate.brandColor != brandColor || oldDelegate.inkColor != inkColor;
}

class _SidebarNavTile extends StatelessWidget {
  const _SidebarNavTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);

    return Container(
      decoration: BoxDecoration(
        color: selected ? colors.surface : Colors.transparent,
        borderRadius: BorderRadius.circular(VnlfDimensions.radiusMd),
        border: selected ? Border.all(color: colors.line) : null,
        boxShadow: selected
            ? VnlfDimensions.subtleShadow(isDark: colors.isDark)
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(VnlfDimensions.radiusMd),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9.5),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: selected ? colors.brand : colors.muted,
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    label,
                    style: VnlfTypography.control(
                      selected ? colors.ink : colors.muted,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarCaramOsTile extends StatelessWidget {
  const _SidebarCaramOsTile({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(VnlfDimensions.radiusMd),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9.5),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0xFFD97706),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.star_rounded,
                size: 12,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                'Hỗ trợ CaramOS',
                style: VnlfTypography.control(colors.muted),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6.5, vertical: 2),
              decoration: BoxDecoration(
                color: colors.brand,
                borderRadius: BorderRadius.circular(VnlfDimensions.radiusFull),
              ),
              child: Text(
                '3',
                style: VnlfTypography.caption(
                  Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarUtilityTile extends StatelessWidget {
  const _SidebarUtilityTile({
    required this.icon,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(VnlfDimensions.radiusSm),
      onTap: onTap ?? () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7.5),
        child: Row(
          children: [
            Icon(icon, size: 17, color: colors.muted),
            const SizedBox(width: 10),
            Text(label, style: VnlfTypography.control(colors.muted)),
          ],
        ),
      ),
    );
  }
}

class _SocialCircleBadge extends StatelessWidget {
  const _SocialCircleBadge({this.label, this.icon});

  final String? label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);

    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.socialIconBg,
        shape: BoxShape.circle,
      ),
      child: label != null
          ? Text(
              label!,
              style: const TextStyle(
                fontFamily: VnlfTypography.fontFamily,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1.0,
              ),
            )
          : Icon(icon, size: 13, color: Colors.white),
    );
  }
}

class _SegmentBtn extends StatelessWidget {
  const _SegmentBtn({
    required this.icon,
    required this.tooltip,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);

    return Expanded(
      child: Tooltip(
        message: tooltip,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: VnlfDimensions.resolveDuration(
              context,
              VnlfDimensions.motionFast,
            ),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? colors.surface : Colors.transparent,
              borderRadius: BorderRadius.circular(VnlfDimensions.radiusMd),
              border: selected ? Border.all(color: colors.line) : null,
            ),
            child: Icon(
              icon,
              size: 15,
              color: selected ? colors.ink : colors.muted,
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderSquareIconButton extends StatelessWidget {
  const _HeaderSquareIconButton({
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);

    return Semantics(
      button: true,
      label: semanticLabel,
      child: InkWell(
        borderRadius: BorderRadius.circular(VnlfDimensions.radiusMd),
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(VnlfDimensions.radiusMd),
            border: Border.all(color: colors.line),
          ),
          child: Icon(icon, size: 18, color: colors.ink),
        ),
      ),
    );
  }
}

class _VnlfTabletRail extends StatelessWidget {
  const _VnlfTabletRail({
    required this.activeDestination,
    this.onDestinationSelected,
    required this.themeMode,
    this.onThemeModeChanged,
    this.onProfileTap,
  });

  final VnlfNavDestination activeDestination;
  final ValueChanged<VnlfNavDestination>? onDestinationSelected;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode>? onThemeModeChanged;
  final VoidCallback? onProfileTap;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);

    return Container(
      width: VnlfDimensions.tabletRailWidth,
      decoration: BoxDecoration(
        color: colors.bg,
        border: Border(right: BorderSide(color: colors.line)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          const VnlfLogoEmblem(size: 32),
          const SizedBox(height: 20),
          for (final dest in VnlfNavDestination.values) ...[
            Tooltip(
              message: dest.label,
              child: InkWell(
                borderRadius: BorderRadius.circular(VnlfDimensions.radiusMd),
                onTap: () => onDestinationSelected?.call(dest),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: dest == activeDestination
                        ? colors.surface
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(
                      VnlfDimensions.radiusMd,
                    ),
                    border: dest == activeDestination
                        ? Border.all(color: colors.line)
                        : null,
                  ),
                  child: Icon(
                    dest.icon,
                    size: 20,
                    color: dest == activeDestination
                        ? colors.brand
                        : colors.muted,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          const Spacer(),
          IconButton(
            tooltip: 'Chế độ giao diện',
            onPressed: () {
              final next = themeMode == ThemeMode.dark
                  ? ThemeMode.light
                  : ThemeMode.dark;
              onThemeModeChanged?.call(next);
            },
            icon: Icon(
              themeMode == ThemeMode.dark
                  ? Icons.dark_mode_outlined
                  : Icons.wb_sunny_outlined,
              size: 19,
              color: colors.muted,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onProfileTap,
            child: const VnlfGuestAvatarBox(size: 36),
          ),
        ],
      ),
    );
  }
}

/// Sticky Mobile Top Header (`64px` height, `17px` horizontal padding).
class _VnlfMobileStickyHeader extends StatelessWidget {
  const _VnlfMobileStickyHeader({this.onProfileTap});
  final VoidCallback? onProfileTap;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);

    return Container(
      height: VnlfDimensions.mobileHeaderHeight,
      padding: const EdgeInsets.symmetric(
        horizontal: VnlfDimensions.mobileHeaderPaddingH,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(bottom: BorderSide(color: colors.line)),
      ),
      child: Row(
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            icon: Icon(Icons.menu_rounded, size: 22, color: colors.ink),
            tooltip: 'Mở menu điều hướng',
            onPressed: () => Scaffold.maybeOf(context)?.openDrawer(),
          ),
          const SizedBox(width: 8),
          const VnlfLogoEmblem(size: 26),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: VnlfTypography.h3(colors.ink)
                    .copyWith(fontWeight: FontWeight.w800),
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
          ),
          _HeaderSquareIconButton(
            icon: Icons.search_rounded,
            semanticLabel: 'Tìm kiếm',
            onTap: () {},
          ),
          const SizedBox(width: 8),
          _HeaderSquareIconButton(
            icon: Icons.notifications_none_rounded,
            semanticLabel: 'Thông báo',
            onTap: () {},
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onProfileTap,
            child: const VnlfGuestAvatarBox(size: 36),
          ),
        ],
      ),
    );
  }
}

/// Sticky Mobile Bottom Navigation Bar (`56px` height, 5 destinations).
class _VnlfMobileBottomNav extends StatelessWidget {
  const _VnlfMobileBottomNav({
    required this.activeDestination,
    this.onDestinationSelected,
  });

  final VnlfNavDestination activeDestination;
  final ValueChanged<VnlfNavDestination>? onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);

    return Container(
      height: VnlfDimensions.mobileBottomNavHeight,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.line)),
      ),
      child: Row(
        children: [
          for (final dest in VnlfNavDestination.values)
            Expanded(
              child: InkWell(
                onTap: () => onDestinationSelected?.call(dest),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      dest.icon,
                      size: 20,
                      color: dest == activeDestination
                          ? colors.brand
                          : colors.muted,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      dest.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: VnlfTypography.caption(
                        dest == activeDestination ? colors.brand : colors.muted,
                        fontWeight: dest == activeDestination
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
