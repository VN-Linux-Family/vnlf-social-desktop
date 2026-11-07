import 'package:fleather/fleather.dart';
import 'package:flutter/material.dart';

import '../../../design_system/tokens/vnlf_colors.dart';
import '../../../design_system/tokens/vnlf_typography.dart';

FleatherThemeData composerEditorTheme(
  BuildContext context, {
  required bool postStyle,
}) {
  final colors = VnlfColors.of(context);
  final body = VnlfTypography.body(colors.ink)
      .copyWith(fontSize: 13, height: postStyle ? 1.6 : 1.7);
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
      fontWeight: FontWeight.w700,
      letterSpacing: spacing * size,
    ),
    spacing: VerticalSpacing(top: top, bottom: bottom),
  );
  final h2 = heading(13, 1.14, 29, 9, -.04);
  final h3 = heading(13, 1.2, 24, 7, -.03);
  final fallback = FleatherThemeData.fallback(context);
  return fallback.copyWith(
    lists: TextBlockTheme(
      style: body,
      spacing: fallback.lists.spacing,
      lineSpacing: fallback.lists.lineSpacing,
    ),
    quote: TextBlockTheme(
      style: body.copyWith(color: colors.muted, fontStyle: FontStyle.italic),
      spacing: const VerticalSpacing(top: 22, bottom: 22),
      lineSpacing: const VerticalSpacing(top: 5, bottom: 5),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: colors.brand, width: 3)),
      ),
    ),
    code: TextBlockTheme(
      style: body.copyWith(
        fontFamily: VnlfTypography.monoFontFamily,
        height: 1.65,
        color: colors.codeBlockText,
      ),
      spacing: const VerticalSpacing(top: 20, bottom: 20),
      decoration: BoxDecoration(
        color: colors.codeBlockBg,
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    inlineCode: InlineCodeThemeData(
      style: body.copyWith(
        fontFamily: VnlfTypography.monoFontFamily,
        color: colors.brand,
      ),
      backgroundColor: colors.brandSoft,
      radius: const Radius.circular(4),
    ),
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
