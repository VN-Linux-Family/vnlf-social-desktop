import 'package:flutter/material.dart';

import '../icons/vnlf_icon.dart';
import '../tokens/vnlf_colors.dart';
import '../tokens/vnlf_dimensions.dart';
import '../tokens/vnlf_typography.dart';

/// The website's `.action` button: a muted icon with an optional label that
/// turns brand on brand-soft when hovered, and brand with a filled icon when
/// [active] (a saved post).
class VnlfActionButton extends StatefulWidget {
  const VnlfActionButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    this.iconSize = 17,
    this.label,
    this.active = false,
    this.onPressed,
    this.padding = const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
    this.minSize = 0,
  });

  final VnlfLucide icon;
  final double iconSize;
  final String? label;
  final String semanticLabel;
  final bool active;
  final VoidCallback? onPressed;
  final EdgeInsets padding;

  /// Smallest width and height; phones pass 48 for the touch target.
  final double minSize;

  @override
  State<VnlfActionButton> createState() => _VnlfActionButtonState();
}

class _VnlfActionButtonState extends State<VnlfActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final lit = _hovered || widget.active;
    final color = lit ? colors.brand : colors.muted;
    final radius = BorderRadius.circular(VnlfDimensions.radiusSm);
    return Semantics(
      button: true,
      toggled: widget.active ? true : null,
      label: widget.semanticLabel,
      excludeSemantics: true,
      child: Tooltip(
        message: widget.label == null ? widget.semanticLabel : '',
        child: InkWell(
          onTap: widget.onPressed,
          borderRadius: radius,
          hoverColor: Colors.transparent,
          onHover: (value) => setState(() => _hovered = value),
          child: Container(
            constraints: BoxConstraints(
              minWidth: widget.minSize,
              minHeight: widget.minSize,
            ),
            padding: widget.padding,
            decoration: BoxDecoration(
              color: _hovered ? colors.brandSoft : null,
              borderRadius: radius,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 5,
              children: [
                VnlfIcon(
                  widget.icon,
                  size: widget.iconSize,
                  color: color,
                  filled: widget.active,
                ),
                if (widget.label != null)
                  Text(widget.label!, style: VnlfTypography.body(color)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
