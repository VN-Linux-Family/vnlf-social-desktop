import 'package:fleather/fleather.dart';
import 'package:flutter/material.dart';

import '../../../design_system/tokens/vnlf_colors.dart';
import '../../../design_system/tokens/vnlf_typography.dart';

FleatherThemeData composerEditorTheme(
  BuildContext context, {
  required bool postStyle,
}) {
  final colors = VnlfColors.of(context);
  final body = VnlfTypography.body(colors.ink).copyWith(
    fontSize: postStyle
        ? 14
        : MediaQuery.sizeOf(context).width <= 520
        ? 16
        : 17,
    height: postStyle ? 1.65 : 1.72,
  );
  TextBlockTheme heading(
    double size,
    double height,
    double top,
    double bottom,
    double spacing,
  ) => TextBlockTheme(
    style: body.copyWith(
      fontSize: size,
      height: height,
      fontWeight: FontWeight.w600,
      letterSpacing: spacing * size,
    ),
    spacing: VerticalSpacing(top: top, bottom: bottom),
  );
  final h2 = heading(29, 1.14, 29, 9, -.04);
  final h3 = heading(23, 1.2, 24, 7, -.03);
  return FleatherThemeData.fallback(context).copyWith(
    paragraph: TextBlockTheme(
      style: body,
      spacing: VerticalSpacing(bottom: postStyle ? 11 : 16),
    ),
    heading1: h2,
    heading2: h2,
    heading3: h3,
    heading4: h2,
    heading5: h2,
    heading6: h2,
  );
}
