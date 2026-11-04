import 'dart:math' as math;

import 'package:flutter/material.dart';

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
                              VnlfDesktopRightSidebar(
                                width: VnlfDimensions.rightSidebarWidth,
                                child: rightSidebarChild!,
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
                VnlfTabletRail(
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
                VnlfMobileStickyHeader(onProfileTap: onProfileTap),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
                    child: centerChild,
                  ),
                ),
              ],
            ),
            bottomNavigationBar: VnlfMobileBottomNav(
              activeDestination: activeDestination,
              onDestinationSelected: onDestinationSelected,
            ),
          ),
        };
      },
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
