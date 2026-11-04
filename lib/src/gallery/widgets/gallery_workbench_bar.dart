import 'package:flutter/material.dart';

import '../../design_system/components/brand_assets.dart';
import '../../design_system/tokens/vnlf_colors.dart';
import '../../design_system/tokens/vnlf_dimensions.dart';
import '../../design_system/tokens/vnlf_typography.dart';
import '../gallery_page.dart';

class GalleryWorkbenchBar extends StatelessWidget {
  const GalleryWorkbenchBar({
    super.key,
    required this.activeScreen,
    required this.onScreenChanged,
    required this.viewportPreset,
    required this.onViewportChanged,
    required this.themeMode,
    required this.onThemeModeChanged,
    required this.onHideToolbar,
  });

  final GalleryScreenTab activeScreen;
  final ValueChanged<GalleryScreenTab> onScreenChanged;
  final GalleryViewportPreset viewportPreset;
  final ValueChanged<GalleryViewportPreset> onViewportChanged;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final VoidCallback onHideToolbar;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(bottom: BorderSide(color: colors.line)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            BrandAssets.logo(size: 20),
            const SizedBox(width: 7),
            Text(
              'Thư viện giao diện',
              style: VnlfTypography.control(
                colors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 14),
            for (final tab in GalleryScreenTab.values) ...[
              ToolbarPillButton(
                label: tab.label,
                selected: tab == activeScreen,
                onTap: () => onScreenChanged(tab),
              ),
              const SizedBox(width: 6),
            ],
            const SizedBox(width: 10),
            Container(width: 1, height: 18, color: colors.line),
            const SizedBox(width: 10),
            for (final preset in GalleryViewportPreset.values) ...[
              ToolbarPillButton(
                label: preset.label,
                selected: preset == viewportPreset,
                onTap: () => onViewportChanged(preset),
              ),
              const SizedBox(width: 6),
            ],
            const SizedBox(width: 10),
            Container(width: 1, height: 18, color: colors.line),
            const SizedBox(width: 10),
            ToolbarPillButton(
              label: themeMode == ThemeMode.dark ? '🌙 Tối' : '☀️ Sáng',
              selected: themeMode == ThemeMode.dark,
              onTap: () => onThemeModeChanged(
                themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
              ),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message: 'Ẩn thanh công cụ để chụp toàn màn hình',
              child: InkWell(
                borderRadius: BorderRadius.circular(VnlfDimensions.radiusSm),
                onTap: onHideToolbar,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.fullscreen_rounded,
                    size: 18,
                    color: colors.muted,
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

class ToolbarPillButton extends StatelessWidget {
  const ToolbarPillButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(VnlfDimensions.radiusSm),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
        decoration: BoxDecoration(
          color: selected ? colors.brandSoft : colors.surfaceSoft,
          borderRadius: BorderRadius.circular(VnlfDimensions.radiusSm),
          border: Border.all(
            color: selected
                ? colors.brand.withValues(alpha: 0.45)
                : colors.line,
          ),
        ),
        child: Text(
          label,
          style: VnlfTypography.caption(
            selected ? colors.brand : colors.muted,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
