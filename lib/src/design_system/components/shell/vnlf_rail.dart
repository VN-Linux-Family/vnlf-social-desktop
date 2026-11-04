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
          BrandAssets.logo(size: 32),
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
