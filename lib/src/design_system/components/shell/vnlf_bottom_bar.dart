import 'package:flutter/material.dart';

import '../../icons/vnlf_icon.dart';

import 'package:flutter/services.dart';

import '../../tokens/vnlf_colors.dart';
import '../../tokens/vnlf_dimensions.dart';
import '../../tokens/vnlf_typography.dart';
import '../vnlf_avatar.dart';
import '../vnlf_shell.dart';

/// The website's `.nav-unread-dot` colour (`#d7473e`).
const _unreadColor = Color(0xFFD7473E);

/// Phone top bar (`54px`) for viewports `< 840px`, following the website's
/// lean phone shell (docs 41): the page title on the left, then create,
/// search and notifications. The menu opens from the bottom bar.
class VnlfMobileStickyHeader extends StatelessWidget {
  const VnlfMobileStickyHeader({
    super.key,
    required this.title,
    this.onBack,
    this.backTooltip = '',
    this.backSemanticLabel,
    this.onComposeTap,
    this.composeSemanticLabel = '',
    this.onSearchTap,
    this.searchSemanticLabel = '',
    this.onNotificationsTap,
    this.notificationsSemanticLabel = '',
    this.notificationBadgeCount = 0,
    this.semanticLabel,
  });

  final String title;
  final VoidCallback? onBack;
  final String backTooltip;
  final String? backSemanticLabel;
  final VoidCallback? onComposeTap;
  final String composeSemanticLabel;
  final VoidCallback? onSearchTap;
  final String searchSemanticLabel;
  final VoidCallback? onNotificationsTap;
  final String notificationsSemanticLabel;
  final int notificationBadgeCount;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final insets = MediaQuery.paddingOf(context);

    // 54px including the 1px hairline, like the website's border-box bar.
    final header = Container(
      height: VnlfDimensions.mobileHeaderHeight + insets.top,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(bottom: BorderSide(color: colors.line)),
      ),
      padding: EdgeInsets.only(
        top: insets.top,
        left: insets.left,
        right: insets.right,
      ),
      child: SizedBox.expand(
        child: Padding(
          padding: EdgeInsets.only(
            // A back control sits in the start gutter, like an app bar.
            left: onBack == null ? VnlfDimensions.mobileHeaderPaddingStart : 4,
            right: VnlfDimensions.mobileHeaderPaddingEnd,
          ),
          child: Row(
            children: [
              if (onBack != null)
                Semantics(
                  label: backSemanticLabel,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      size: 22,
                      color: colors.ink,
                    ),
                    tooltip: backTooltip.isNotEmpty ? backTooltip : null,
                    onPressed: onBack,
                  ),
                ),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: VnlfTypography.pageTitle(colors.ink),
                  ),
                ),
              ),
              if (onComposeTap != null)
                _HeaderIconButton(
                  icon: VnlfLucide.squarePlus,
                  semanticLabel: composeSemanticLabel,
                  onTap: onComposeTap,
                ),
              _HeaderIconButton(
                icon: VnlfLucide.search,
                semanticLabel: searchSemanticLabel,
                onTap: onSearchTap,
              ),
              _HeaderIconButton(
                icon: VnlfLucide.bell,
                semanticLabel: notificationsSemanticLabel,
                badgeCount: notificationBadgeCount,
                onTap: onNotificationsTap,
              ),
            ],
          ),
        ),
      ),
    );

    if (semanticLabel == null) {
      return header;
    }
    return Semantics(label: semanticLabel, container: true, child: header);
  }
}

/// Bare header icon with a 48px circular target, as on the website.
class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
    this.badgeCount = 0,
  });

  final VnlfLucide icon;
  final String semanticLabel;
  final VoidCallback? onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);

    Widget button = Semantics(
      button: true,
      label: semanticLabel.isNotEmpty ? semanticLabel : null,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                VnlfIcon(
                  icon,
                  size: icon == VnlfLucide.bell ? 20 : 22,
                  color: colors.ink,
                ),
                if (badgeCount > 0)
                  Positioned(
                    top: -1,
                    right: -1,
                    child: _Dot(color: _unreadColor, ring: colors.surface),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    if (semanticLabel.isNotEmpty) {
      button = Tooltip(message: semanticLabel, child: button);
    }
    return button;
  }
}

/// Floating phone navigation (`56px`) from the website's lean shell: four
/// destination icons and the account avatar, which opens the menu. Visible
/// labels are omitted as on the website; they remain semantic labels.
class VnlfMobileBottomNav extends StatelessWidget {
  const VnlfMobileBottomNav({
    super.key,
    required this.activeDestination,
    this.onDestinationSelected,
    this.destinationLabels = const {},
    this.destinationSemanticLabels = const {},
    this.unreadDestinations = const {},
    this.onMenuTap,
    this.menuSemanticLabel = '',
    this.menuOpen = false,
    this.accountAvatar,
    this.semanticLabel,
  });

  /// Destinations in the bar; the others are reached through the menu.
  static const destinations = [
    VnlfNavDestination.feed,
    VnlfNavDestination.explore,
    VnlfNavDestination.messages,
    VnlfNavDestination.voice,
  ];

  /// The highlighted item; null on pages that are not in the menu.
  final VnlfNavDestination? activeDestination;
  final ValueChanged<VnlfNavDestination>? onDestinationSelected;
  final Map<VnlfNavDestination, String> destinationLabels;
  final Map<VnlfNavDestination, String> destinationSemanticLabels;
  final Set<VnlfNavDestination> unreadDestinations;
  final VoidCallback? onMenuTap;
  final String menuSemanticLabel;
  final bool menuOpen;

  /// The signed-in member's avatar; a neutral placeholder is used otherwise.
  final Widget? accountAvatar;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final insets = MediaQuery.paddingOf(context);

    final nav = Padding(
      padding: EdgeInsets.fromLTRB(
        12 + insets.left,
        0,
        12 + insets.right,
        6 + insets.bottom,
      ),
      child: Container(
        height: VnlfDimensions.mobileBottomNavHeight,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border.all(color: colors.line),
          borderRadius: BorderRadius.circular(VnlfDimensions.radiusFull),
          boxShadow: VnlfDimensions.hardShadow(isDark: colors.isDark),
        ),
        child: Row(
          children: [
            for (final dest in destinations)
              Expanded(
                child: _NavCell(
                  label:
                      destinationSemanticLabels[dest] ??
                      destinationLabels[dest],
                  selected: dest == activeDestination,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onDestinationSelected?.call(dest);
                  },
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      VnlfIcon(
                        dest.icon,
                        size: 24,
                        strokeWidth: dest == activeDestination ? 2.3 : 1.8,
                        color: dest == activeDestination
                            ? colors.brand
                            : colors.muted,
                      ),
                      if (unreadDestinations.contains(dest))
                        Positioned(
                          top: -3,
                          right: -5,
                          child: _Dot(
                            color: _unreadColor,
                            ring: colors.surface,
                            size: 10,
                            ringWidth: 2,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: _NavCell(
                label: menuSemanticLabel.isNotEmpty ? menuSemanticLabel : null,
                expanded: menuOpen,
                onTap: onMenuTap,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: menuOpen ? colors.brand : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: SizedBox.square(
                    dimension: 28,
                    child: ClipOval(
                      child:
                          accountAvatar ??
                          const VnlfGuestAvatarBox(size: 28, isCircle: true),
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
      return nav;
    }
    return Semantics(label: semanticLabel, container: true, child: nav);
  }
}

class _NavCell extends StatelessWidget {
  const _NavCell({
    required this.label,
    required this.onTap,
    required this.child,
    this.selected = false,
    this.expanded,
  });

  final String? label;
  final VoidCallback? onTap;
  final Widget child;
  final bool selected;
  final bool? expanded;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final shape = BorderRadius.circular(VnlfDimensions.radiusFull);
    return Semantics(
      button: true,
      selected: selected,
      expanded: expanded,
      label: label,
      child: Tooltip(
        message: label ?? '',
        excludeFromSemantics: true,
        child: InkWell(
          borderRadius: shape,
          onTap: onTap,
          child: AnimatedContainer(
            duration: VnlfDimensions.resolveDuration(
              context,
              VnlfDimensions.motionFast,
            ),
            curve: Curves.easeOutCubic,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? colors.brandSoft : Colors.transparent,
              borderRadius: shape,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({
    required this.color,
    required this.ring,
    this.size = 8,
    this.ringWidth = 1.5,
  });

  final Color color;
  final Color ring;
  final double size;
  final double ringWidth;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      border: Border.all(color: ring, width: ringWidth),
    ),
  );
}
