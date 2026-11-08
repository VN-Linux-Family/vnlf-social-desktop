import 'package:flutter/material.dart';

import 'vnlf_colors.dart';

/// Typography tokens using the bundled `BeVietnamPro` font family.
///
/// Follows the website's unified scale (`design-system/MASTER.md`, docs 31):
/// all visible text is 13px and hierarchy comes from weight 700/800, colour and
/// spacing. The only larger text is the page title in the top bar (18px).
/// Designed for clean Vietnamese diacritic rendering (`Tiếng Việt: ặ ữ ờ ẫ ệ`).
abstract final class VnlfTypography {
  static const String fontFamily = 'BeVietnamPro';
  static const String monoFontFamily = 'monospace';

  /// Base size of every visible text, matching the website's `--vnlf-text`.
  static const double baseSize = 13;

  /// Page title in the top bar: base + 5px (18px), weight 800, line height 1.25.
  static TextStyle pageTitle(Color color) => TextStyle(
    fontFamily: fontFamily,
    fontSize: baseSize + 5,
    height: 1.25,
    fontWeight: FontWeight.w800,
    color: color,
    letterSpacing: -0.18,
  );

  /// Heading level 1 inside content: 13px, weight 700.
  static TextStyle h1(Color color) => _heading(color);

  /// Heading level 2 (section headings): 13px, weight 700.
  static TextStyle h2(Color color) => _heading(color);

  /// Heading level 3 (sub-sections, card titles): 13px, weight 700.
  static TextStyle h3(Color color) => _heading(color);

  static TextStyle _heading(Color color) => TextStyle(
    fontFamily: fontFamily,
    fontSize: baseSize,
    height: 18 / 13,
    fontWeight: FontWeight.w700,
    color: color,
  );

  /// Body: 13px, line height 1.6, weight 400. Posts, comments, descriptions.
  static TextStyle body(Color color) => TextStyle(
    fontFamily: fontFamily,
    fontSize: baseSize,
    height: 1.6,
    fontWeight: FontWeight.w400,
    color: color,
  );

  /// Controls: 13px / 18px, weight 500. Button labels, tabs, inputs, navigation.
  static TextStyle control(
    Color color, {
    FontWeight fontWeight = FontWeight.w500,
  }) => TextStyle(
    fontFamily: fontFamily,
    fontSize: baseSize,
    height: 18 / 13,
    fontWeight: fontWeight,
    color: color,
  );

  /// Metadata: 13px / 18px, weight 400. Shown in a muted colour, not smaller.
  static TextStyle meta(
    Color color, {
    FontWeight fontWeight = FontWeight.w400,
  }) => TextStyle(
    fontFamily: fontFamily,
    fontSize: baseSize,
    height: 18 / 13,
    fontWeight: fontWeight,
    color: color,
  );

  /// Captions, tags and small pills: 13px / 18px, weight 500.
  static TextStyle caption(
    Color color, {
    FontWeight fontWeight = FontWeight.w500,
  }) => TextStyle(
    fontFamily: fontFamily,
    fontSize: baseSize,
    height: 18 / 13,
    fontWeight: fontWeight,
    color: color,
  );

  /// Numbers (scores, points, counters): 13px, weight 800, tabular figures.
  static TextStyle number(Color color) => TextStyle(
    fontFamily: fontFamily,
    fontSize: baseSize,
    height: 18 / 13,
    fontWeight: FontWeight.w800,
    color: color,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  /// Terminal and code snippet style.
  static TextStyle code(Color color) => TextStyle(
    fontFamily: monoFontFamily,
    fontSize: baseSize,
    height: 1.65,
    fontWeight: FontWeight.w400,
    color: color,
  );

  /// Builds a Flutter [TextTheme] mapped to the VNLF type hierarchy.
  static TextTheme textTheme(VnlfColors colors) {
    return TextTheme(
      headlineLarge: h1(colors.ink),
      headlineMedium: h2(colors.ink),
      headlineSmall: h2(colors.ink),
      titleLarge: pageTitle(colors.ink),
      titleMedium: h3(colors.ink),
      titleSmall: h3(colors.ink),
      bodyLarge: body(colors.ink),
      bodyMedium: body(colors.ink),
      labelLarge: control(colors.ink),
      labelMedium: meta(colors.muted),
      labelSmall: meta(colors.muted),
      bodySmall: caption(colors.muted),
    );
  }
}
