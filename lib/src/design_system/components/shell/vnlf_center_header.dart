import 'package:flutter/material.dart';

import '../../icons/vnlf_icon.dart';
import '../../tokens/vnlf_colors.dart';
import '../../tokens/vnlf_dimensions.dart';
import '../../tokens/vnlf_typography.dart';

/// The website's `.main-header` above the center column on wider screens:
/// the page title over a hairline, with actions on the right.
class VnlfCenterPageHeader extends StatelessWidget {
  const VnlfCenterPageHeader({
    super.key,
    required this.title,
    this.leading,
    this.trailing,
    this.onProfileTap,
    this.semanticLabel,
  });

  final String title;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onProfileTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final effectiveSemantics =
        semanticLabel ?? (title.isNotEmpty ? title : null);

    return Semantics(
      header: true,
      label: effectiveSemantics,
      child: Container(
        margin: const EdgeInsets.only(bottom: 25),
        constraints: const BoxConstraints(minHeight: 64),
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 14),
        decoration: BoxDecoration(
          color: colors.bg.withValues(alpha: 0.92),
          border: Border(bottom: BorderSide(color: colors.line)),
        ),
        child: Row(
          spacing: 10,
          children: [
            ?leading,
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: VnlfTypography.pageTitle(colors.ink)
                    .copyWith(letterSpacing: -0.18),
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

/// A 40px bordered header button (search, notifications) as the website
/// draws it, with an optional unread badge.
class VnlfHeaderIconBox extends StatefulWidget {
  const VnlfHeaderIconBox({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.iconSize = 19,
    this.muted = true,
    this.badgeCount = 0,
  });

  final VnlfLucide icon;
  final String tooltip;
  final VoidCallback onPressed;
  final double iconSize;

  /// Search is muted at rest; the bell is ink.
  final bool muted;
  final int badgeCount;

  @override
  State<VnlfHeaderIconBox> createState() => _VnlfHeaderIconBoxState();
}

class _VnlfHeaderIconBoxState extends State<VnlfHeaderIconBox> {
  var _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final color = _hovered
        ? colors.brand
        : (widget.muted ? colors.muted : colors.ink);
    return Tooltip(
      message: widget.tooltip,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: _hovered ? colors.brandSoft : colors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(VnlfDimensions.radiusMd),
              side: BorderSide(color: _hovered ? colors.brand : colors.line),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(VnlfDimensions.radiusMd),
              onTap: widget.onPressed,
              onHover: (value) => setState(() => _hovered = value),
              child: SizedBox.square(
                dimension: 40,
                child: Center(
                  child: VnlfIcon(
                    widget.icon,
                    size: widget.iconSize,
                    color: color,
                  ),
                ),
              ),
            ),
          ),
          if (widget.badgeCount > 0)
            Positioned(
              top: -5,
              right: -5,
              child: VnlfBellCount(count: widget.badgeCount),
            ),
        ],
      ),
    );
  }
}

/// The bell's unseen count, as the website's `.bell-unread-count`: white on
/// dark red, ringed with the surface, "99+" above 99.
class VnlfBellCount extends StatelessWidget {
  const VnlfBellCount({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minWidth: 18),
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    decoration: BoxDecoration(
      color: const Color(0xFFA63030),
      borderRadius: BorderRadius.circular(VnlfDimensions.radiusMd),
      border: Border.all(color: VnlfColors.of(context).surface),
    ),
    child: Text(
      count > 99 ? '99+' : '$count',
      textAlign: TextAlign.center,
      textScaler: TextScaler.noScaling,
      style: VnlfTypography.plain(const Color(0xFFFFFFFF))
          .copyWith(height: 1.2),
    ),
  );
}
