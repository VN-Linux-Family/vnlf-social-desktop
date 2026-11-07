import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../tokens/vnlf_colors.dart';
import '../../tokens/vnlf_dimensions.dart';
import '../../tokens/vnlf_typography.dart';
import '../brand_assets.dart';
import '../vnlf_avatar.dart';
import '../vnlf_shell.dart';

/// Sticky mobile top header (`64px` height) for viewports `<= 840px`.
class VnlfMobileStickyHeader extends StatelessWidget {
  const VnlfMobileStickyHeader({
    super.key,
    this.onProfileTap,
    this.onSearchTap,
    this.onNotificationsTap,
    this.openDrawerTooltip = '',
    this.openDrawerSemanticLabel,
    this.brandTitlePrefix = '',
    this.brandTitleAccent = '',
    this.brandLogoSemanticLabel,
    this.searchSemanticLabel = '',
    this.notificationsSemanticLabel = '',
    this.profileSemanticLabel,
    this.semanticLabel,
  });

  final VoidCallback? onProfileTap;
  final VoidCallback? onSearchTap;
  final VoidCallback? onNotificationsTap;
  final String openDrawerTooltip;
  final String? openDrawerSemanticLabel;
  final String brandTitlePrefix;
  final String brandTitleAccent;
  final String? brandLogoSemanticLabel;
  final String searchSemanticLabel;
  final String notificationsSemanticLabel;
  final String? profileSemanticLabel;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final insets = MediaQuery.paddingOf(context);

    final header = Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(bottom: BorderSide(color: colors.line)),
      ),
      padding: EdgeInsets.only(
        top: insets.top,
        left: insets.left,
        right: insets.right,
      ),
      child: SizedBox(
        height: VnlfDimensions.mobileHeaderHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: VnlfDimensions.mobileHeaderPaddingH,
          ),
          child: Row(
            children: [
              Semantics(
                button: true,
                label:
                    openDrawerSemanticLabel ??
                    (openDrawerTooltip.isNotEmpty ? openDrawerTooltip : null),
                child: IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  icon: Icon(Icons.menu_rounded, size: 22, color: colors.ink),
                  tooltip: openDrawerTooltip.isNotEmpty
                      ? openDrawerTooltip
                      : null,
                  onPressed: () => Scaffold.maybeOf(context)?.openDrawer(),
                ),
              ),
              const SizedBox(width: 8),
              BrandAssets.logo(size: 26, semanticLabel: brandLogoSemanticLabel),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  overflow: TextOverflow.ellipsis,
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
              ),
              _HeaderSquareIconButton(
                icon: Icons.search_rounded,
                semanticLabel: searchSemanticLabel,
                onTap: onSearchTap,
              ),
              const SizedBox(width: 8),
              _HeaderSquareIconButton(
                icon: Icons.notifications_none_rounded,
                semanticLabel: notificationsSemanticLabel,
                onTap: onNotificationsTap,
              ),
              const SizedBox(width: 8),
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
        ),
      ),
    );

    if (semanticLabel == null) {
      return header;
    }
    return Semantics(label: semanticLabel, container: true, child: header);
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
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);

    Widget button = Semantics(
      button: true,
      label: semanticLabel.isNotEmpty ? semanticLabel : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(VnlfDimensions.radiusMd),
        onTap: onTap,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: colors.surfaceSoft,
            borderRadius: BorderRadius.circular(VnlfDimensions.radiusMd),
          ),
          child: Icon(icon, size: 18, color: colors.ink),
        ),
      ),
    );

    if (semanticLabel.isNotEmpty) {
      button = Tooltip(message: semanticLabel, child: button);
    }

    return button;
  }
}

/// Sticky mobile bottom navigation bar (`56px` height) for viewports `<= 840px`.
class VnlfMobileBottomNav extends StatelessWidget {
  const VnlfMobileBottomNav({
    super.key,
    required this.activeDestination,
    this.onDestinationSelected,
    this.destinationLabels = const {},
    this.destinationSemanticLabels = const {},
    this.semanticLabel,
  });

  final VnlfNavDestination activeDestination;
  final ValueChanged<VnlfNavDestination>? onDestinationSelected;
  final Map<VnlfNavDestination, String> destinationLabels;
  final Map<VnlfNavDestination, String> destinationSemanticLabels;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final insets = MediaQuery.paddingOf(context);

    final nav = Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.line)),
      ),
      padding: EdgeInsets.only(
        bottom: insets.bottom,
        left: insets.left,
        right: insets.right,
      ),
      child: SizedBox(
        height: VnlfDimensions.mobileBottomNavHeight,
        child: Row(
          children: [
            for (final dest in VnlfNavDestination.values)
              Expanded(
                child: Semantics(
                  button: true,
                  selected: dest == activeDestination,
                  label:
                      destinationSemanticLabels[dest] ??
                      destinationLabels[dest],
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onDestinationSelected?.call(dest);
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedScale(
                          scale: dest == activeDestination ? 1.05 : 1.0,
                          duration: VnlfDimensions.resolveDuration(
                            context,
                            VnlfDimensions.motionFast,
                          ),
                          curve: Curves.easeOutCubic,
                          child: AnimatedContainer(
                            duration: VnlfDimensions.resolveDuration(
                              context,
                              VnlfDimensions.motionFast,
                            ),
                            curve: Curves.easeOutCubic,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: dest == activeDestination
                                  ? colors.brandSoft
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(
                                VnlfDimensions.radiusFull,
                              ),
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
                        if ((destinationLabels[dest] ?? '').isNotEmpty) ...[
                          const SizedBox(height: 2),
                          AnimatedDefaultTextStyle(
                            duration: VnlfDimensions.resolveDuration(
                              context,
                              VnlfDimensions.motionFast,
                            ),
                            curve: Curves.easeOutCubic,
                            style: VnlfTypography.caption(
                              dest == activeDestination
                                  ? colors.brand
                                  : colors.muted,
                              fontWeight: dest == activeDestination
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            child: Text(destinationLabels[dest]!),
                          ),
                        ],
                      ],
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
