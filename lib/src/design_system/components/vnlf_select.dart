import 'package:flutter/material.dart';

import '../icons/vnlf_icon.dart';
import '../tokens/vnlf_colors.dart';
import '../tokens/vnlf_dimensions.dart';
import '../tokens/vnlf_typography.dart';
import 'vnlf_overlays.dart';

/// One choice of a [VnlfSelect].
final class VnlfSelectOption<T> {
  const VnlfSelectOption(this.value, this.label);

  final T value;
  final String label;
}

/// The website's `Select` (`components/ui/select.tsx`): a bordered trigger
/// with the chosen label and a chevron, opening a list anchored to it where
/// the chosen row is tinted and checked.
class VnlfSelect<T> extends StatelessWidget {
  const VnlfSelect({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  /// What the control is for, read by screen readers.
  final String label;
  final T value;
  final List<VnlfSelectOption<T>> options;

  /// Null disables the control.
  final ValueChanged<T>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final chosen = options.where((option) => option.value == value).firstOrNull;
    final radius = BorderRadius.circular(VnlfDimensions.radiusMd);
    return Semantics(
      container: true,
      button: true,
      enabled: onChanged != null,
      label: label,
      value: chosen?.label,
      excludeSemantics: true,
      onTap: onChanged == null ? null : () => _open(context),
      child: Material(
        color: colors.surfaceSoft,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: colors.line),
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: onChanged == null ? null : () => _open(context),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 42),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 10,
                children: [
                  Flexible(
                    child: Text(
                      chosen?.label ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: VnlfTypography.plain(colors.ink),
                    ),
                  ),
                  VnlfIcon(VnlfLucide.chevronDown, size: 16, color: colors.ink),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context) async {
    final box = context.findRenderObject()! as RenderBox;
    final anchor = box.localToGlobal(Offset.zero) & box.size;
    final phone = MediaQuery.sizeOf(context).width < 841;
    final picked = await showVnlfPopover<T>(
      context,
      anchor: anchor,
      label: label,
      width: anchor.width < 160 ? 160 : anchor.width,
      radius: VnlfDimensions.radiusMd,
      padding: const EdgeInsets.all(5),
      builder: (context) => _SelectList<T>(
        options: options,
        value: value,
        rowHeight: phone ? 44 : 42,
      ),
    );
    if (picked != null && picked != value) onChanged?.call(picked);
  }
}

class _SelectList<T> extends StatelessWidget {
  const _SelectList({
    required this.options,
    required this.value,
    required this.rowHeight,
  });

  final List<VnlfSelectOption<T>> options;
  final T value;
  final double rowHeight;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final option in options)
          _SelectRow(
            label: option.label,
            selected: option.value == value,
            height: rowHeight,
            onTap: () => Navigator.of(context).pop(option.value),
          ),
      ],
    ),
  );
}

class _SelectRow extends StatefulWidget {
  const _SelectRow({
    required this.label,
    required this.selected,
    required this.height,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final double height;
  final VoidCallback onTap;

  @override
  State<_SelectRow> createState() => _SelectRowState();
}

class _SelectRowState extends State<_SelectRow> {
  var _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    // The chosen row, the hovered one and the focused one share one tint.
    final tinted = widget.selected || _hovered;
    final ink = tinted ? colors.brand : colors.ink;
    final radius = BorderRadius.circular(VnlfDimensions.radiusMd);
    return Semantics(
      selected: widget.selected,
      inMutuallyExclusiveGroup: true,
      child: Material(
        color: tinted ? colors.brandSoft : Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: widget.onTap,
          onHover: (value) => setState(() => _hovered = value),
          onFocusChange: (value) => setState(() => _hovered = value),
          hoverColor: Colors.transparent,
          focusColor: Colors.transparent,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: widget.height),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                spacing: 9,
                children: [
                  Expanded(
                    child: Text(widget.label, style: VnlfTypography.plain(ink)),
                  ),
                  if (widget.selected)
                    VnlfIcon(VnlfLucide.check, size: 16, color: ink),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
