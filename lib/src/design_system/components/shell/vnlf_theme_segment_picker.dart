import 'package:flutter/material.dart';

import '../../tokens/vnlf_colors.dart';
import '../../tokens/vnlf_dimensions.dart';

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
          behavior: HitTestBehavior.opaque,
          child: Container(
            decoration: BoxDecoration(
              color: selected ? colors.surface : Colors.transparent,
              borderRadius: BorderRadius.circular(VnlfDimensions.radiusMd),
              boxShadow: selected
                  ? VnlfDimensions.subtleShadow(isDark: colors.isDark)
                  : null,
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 16,
              color: selected ? colors.brand : colors.muted,
            ),
          ),
        ),
      ),
    );
  }
}
