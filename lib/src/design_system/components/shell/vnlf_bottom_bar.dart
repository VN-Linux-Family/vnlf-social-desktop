import 'package:flutter/material.dart';

import '../../tokens/vnlf_colors.dart';
import '../../tokens/vnlf_dimensions.dart';
import '../../tokens/vnlf_typography.dart';
import '../brand_assets.dart';
import '../vnlf_avatar.dart';
import '../vnlf_shell.dart';

/// Sticky mobile top header (`64px` height) for viewports `<= 840px`.
class VnlfMobileStickyHeader extends StatelessWidget {
  const VnlfMobileStickyHeader({super.key, this.onProfileTap});

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
          BrandAssets.logo(size: 26),
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

    return Tooltip(
      message: semanticLabel,
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
  }
}

/// Sticky mobile bottom navigation bar (`56px` height) for viewports `<= 840px`.
class VnlfMobileBottomNav extends StatelessWidget {
  const VnlfMobileBottomNav({
    super.key,
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
