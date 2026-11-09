import 'package:flutter/material.dart';

import '../../icons/vnlf_icon.dart';

import '../../tokens/vnlf_colors.dart';
import '../../tokens/vnlf_dimensions.dart';

/// 3-state segment toggle at the bottom of the sidebar.
class VnlfThemeSegmentPicker extends StatelessWidget {
  const VnlfThemeSegmentPicker({
    super.key,
    required this.themeMode,
    this.onThemeModeChanged,
    this.lightTooltip = '',
    this.darkTooltip = '',
    this.systemTooltip = '',
    this.semanticLabel,
    this.lightSemanticLabel,
    this.darkSemanticLabel,
    this.systemSemanticLabel,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode>? onThemeModeChanged;
  final String lightTooltip;
  final String darkTooltip;
  final String systemTooltip;
  final String? semanticLabel;
  final String? lightSemanticLabel;
  final String? darkSemanticLabel;
  final String? systemSemanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);

    final picker = Container(
      height: 54,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colors.surfaceSoft,
        borderRadius: BorderRadius.circular(VnlfDimensions.radiusLg),
        border: Border.all(color: colors.line),
      ),
      child: Row(
        children: [
          _SegmentBtn(
            icon: VnlfLucide.sun,
            tooltip: lightTooltip,
            semanticLabel: lightSemanticLabel,
            selected: themeMode == ThemeMode.light,
            onTap: onThemeModeChanged == null
                ? null
                : () => onThemeModeChanged!(ThemeMode.light),
          ),
          _SegmentBtn(
            icon: VnlfLucide.moon,
            tooltip: darkTooltip,
            semanticLabel: darkSemanticLabel,
            selected: themeMode == ThemeMode.dark,
            onTap: onThemeModeChanged == null
                ? null
                : () => onThemeModeChanged!(ThemeMode.dark),
          ),
          _SegmentBtn(
            icon: VnlfLucide.monitor,
            tooltip: systemTooltip,
            semanticLabel: systemSemanticLabel,
            selected: themeMode == ThemeMode.system,
            onTap: onThemeModeChanged == null
                ? null
                : () => onThemeModeChanged!(ThemeMode.system),
          ),
        ],
      ),
    );

    if (semanticLabel == null) {
      return picker;
    }
    return Semantics(label: semanticLabel, container: true, child: picker);
  }
}

class _SegmentBtn extends StatelessWidget {
  const _SegmentBtn({
    required this.icon,
    required this.tooltip,
    required this.selected,
    required this.onTap,
    this.semanticLabel,
  });

  final VnlfLucide icon;
  final String tooltip;
  final bool selected;
  final VoidCallback? onTap;
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
        onTap: onTap,
        borderRadius: BorderRadius.circular(VnlfDimensions.radiusMd),
        child: Container(
          decoration: BoxDecoration(
            color: selected ? colors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(VnlfDimensions.radiusMd),
            boxShadow: selected
                ? VnlfDimensions.subtleShadow(isDark: colors.isDark)
                : null,
          ),
          alignment: Alignment.center,
          child: VnlfIcon(
            icon,
            size: 15,
            color: selected ? colors.brand : colors.muted,
          ),
        ),
      ),
    );

    if (tooltip.isNotEmpty) {
      button = Tooltip(message: tooltip, child: button);
    }

    return Expanded(child: button);
  }
}
