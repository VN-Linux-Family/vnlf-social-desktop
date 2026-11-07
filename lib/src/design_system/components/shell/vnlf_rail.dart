import 'package:flutter/material.dart';

import '../../tokens/vnlf_colors.dart';
import '../../tokens/vnlf_dimensions.dart';
import '../brand_assets.dart';
import '../vnlf_avatar.dart';
import '../vnlf_shell.dart';

/// Compact tablet navigation rail (`76px`) for viewports `841px - 1180px`.
class VnlfTabletRail extends StatelessWidget {
  const VnlfTabletRail({
    super.key,
    required this.activeDestination,
    this.onDestinationSelected,
    required this.themeMode,
    this.onThemeModeChanged,
    this.onProfileTap,
    this.onLogoutTap,
    this.logoutLabel = '',
    this.destinationLabels = const {},
    this.destinationSemanticLabels = const {},
    this.brandLogoSemanticLabel,
    this.themeToggleTooltip = '',
    this.themeToggleSemanticLabel,
    this.profileSemanticLabel,
    this.unreadDestinations = const {},
    this.semanticLabel,
  });

  final VnlfNavDestination activeDestination;
  final ValueChanged<VnlfNavDestination>? onDestinationSelected;
  final Set<VnlfNavDestination> unreadDestinations;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode>? onThemeModeChanged;
  final VoidCallback? onProfileTap;
  final VoidCallback? onLogoutTap;
  final String logoutLabel;
  final Map<VnlfNavDestination, String> destinationLabels;
  final Map<VnlfNavDestination, String> destinationSemanticLabels;
  final String? brandLogoSemanticLabel;
  final String themeToggleTooltip;
  final String? themeToggleSemanticLabel;
  final String? profileSemanticLabel;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);

    final rail = Container(
      width: VnlfDimensions.tabletRailWidth,
      decoration: BoxDecoration(
        color: colors.bg,
        border: Border(right: BorderSide(color: colors.line)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          BrandAssets.logo(size: 32, semanticLabel: brandLogoSemanticLabel),
          const SizedBox(height: 20),
          for (final dest in VnlfNavDestination.values) ...[
            _RailNavButton(
              destination: dest,
              selected: dest == activeDestination,
              hasUnread: unreadDestinations.contains(dest),
              tooltip: destinationLabels[dest] ?? '',
              semanticLabel:
                  destinationSemanticLabels[dest] ?? destinationLabels[dest],
              onTap: () => onDestinationSelected?.call(dest),
            ),
            const SizedBox(height: 8),
          ],
          const Spacer(),
          if (onLogoutTap != null)
            IconButton(
              tooltip: logoutLabel,
              onPressed: onLogoutTap,
              icon: Icon(Icons.logout_rounded, size: 19, color: colors.muted),
            ),
          Semantics(
            button: true,
            label:
                themeToggleSemanticLabel ??
                (themeToggleTooltip.isNotEmpty ? themeToggleTooltip : null),
            child: IconButton(
              tooltip: themeToggleTooltip.isNotEmpty
                  ? themeToggleTooltip
                  : null,
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
          ),
          const SizedBox(height: 8),
          Semantics(
            button: true,
            label: profileSemanticLabel,
            child: GestureDetector(
              onTap: onProfileTap,
              child: VnlfGuestAvatarBox(
                size: 36,
                semanticLabel: profileSemanticLabel,
              ),
            ),
          ),
        ],
      ),
    );

    if (semanticLabel == null) {
      return rail;
    }
    return Semantics(label: semanticLabel, container: true, child: rail);
  }
}

class _RailNavButton extends StatelessWidget {
  const _RailNavButton({
    required this.destination,
    required this.selected,
    required this.tooltip,
    required this.onTap,
    this.hasUnread = false,
    this.semanticLabel,
  });

  final VnlfNavDestination destination;
  final bool selected;
  final String tooltip;
  final VoidCallback onTap;
  final bool hasUnread;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final effectiveSemantics =
        semanticLabel ?? (tooltip.isNotEmpty ? tooltip : null);

    Widget button = Semantics(
      button: true,
      selected: selected,
      label: effectiveSemantics,
      child: InkWell(
        borderRadius: BorderRadius.circular(VnlfDimensions.radiusMd),
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: selected ? colors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(VnlfDimensions.radiusMd),
            border: selected ? Border.all(color: colors.line) : null,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Icon(
                destination.icon,
                size: 20,
                color: selected ? colors.brand : colors.muted,
              ),
              if (hasUnread)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD7473E),
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.bg, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    if (tooltip.isNotEmpty) {
      button = Tooltip(message: tooltip, child: button);
    }

    return button;
  }
}
