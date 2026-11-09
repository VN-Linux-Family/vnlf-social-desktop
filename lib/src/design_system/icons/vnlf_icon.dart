import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../tokens/vnlf_colors.dart';
import 'vnlf_lucide.dart';

export 'vnlf_lucide.dart';

/// Draws a lucide icon the way lucide-react does on the website: the 24×24
/// outline scaled to [size] and stroked with [strokeWidth] in [color].
class VnlfIcon extends StatelessWidget {
  const VnlfIcon(
    this.icon, {
    super.key,
    this.size = 24,
    this.color,
    this.strokeWidth = 2,
    this.filled = false,
    this.semanticLabel,
  });

  final VnlfLucide icon;
  final double size;

  /// Defaults to the surrounding [IconTheme] color, then ink.
  final Color? color;
  final double strokeWidth;

  /// Fills the outline too, as the website does for an active vote or a
  /// saved bookmark.
  final bool filled;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final resolved =
        color ?? IconTheme.of(context).color ?? VnlfColors.of(context).ink;
    final fill = filled ? 'currentColor' : 'none';
    final svg =
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" '
        'fill="$fill" stroke="currentColor" stroke-width="$strokeWidth" '
        'stroke-linecap="round" stroke-linejoin="round">${icon.body}</svg>';
    return SvgPicture.string(
      svg,
      width: size,
      height: size,
      theme: SvgTheme(currentColor: resolved),
      semanticsLabel: semanticLabel,
      excludeFromSemantics: semanticLabel == null,
    );
  }
}
