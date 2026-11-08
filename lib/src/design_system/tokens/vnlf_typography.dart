import 'package:flutter/material.dart';

import 'vnlf_colors.dart';

/// Typography tokens using the bundled `BeVietnamPro` font family.
///
/// Designed for clean Vietnamese diacritic rendering (`Tiếng Việt: ặ ữ ờ ẫ ệ`).
abstract final class VnlfTypography {
  static const String fontFamily = 'BeVietnamPro';
  static const String monoFontFamily = 'monospace';

  /// `text-h1`: 18px / 24px, weight 700 (Bold). Main screen headings (feed, explore).
  static TextStyle h1(Color color) => TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    height: 24 / 18,
    fontWeight: FontWeight.w700,
    color: color,
    letterSpacing: -0.2,
  );

  /// `text-h2`: 16px / 22px, weight 700 (Bold). Section headings (weekly leaderboard, project title).
  static TextStyle h2(Color color) => TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    height: 22 / 16,
    fontWeight: FontWeight.w700,
    color: color,
    letterSpacing: -0.15,
  );

  /// `text-h3`: 14px / 20px, weight 600 (Semi-bold). Sub-sections, card titles.
  static TextStyle h3(Color color) => TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w600,
    color: color,
  );

  /// `text-body`: 13px / 20.8px (1.6), weight 400 (Regular). Primary post content, comments, descriptions.
  static TextStyle body(Color color) => TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    height: 1.6,
    fontWeight: FontWeight.w400,
    color: color,
  );

  /// `text-control`: 13px / 18px, weight 500 (Medium). Button labels, tabs, form inputs, navigation items.
  static TextStyle control(
    Color color, {
    FontWeight fontWeight = FontWeight.w500,
  }) => TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    height: 18 / 13,
    fontWeight: fontWeight,
    color: color,
  );

  /// `text-meta`: 12px / 16px, weight 400 (Regular). Timestamps, usernames (`@handle`), counters, badges.
  static TextStyle meta(
    Color color, {
    FontWeight fontWeight = FontWeight.w400,
  }) => TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    height: 16 / 12,
    fontWeight: fontWeight,
    color: color,
  );

  /// `text-caption`: 11px / 14px, weight 500 (Medium). Category tags, small indicator pills, footer text.
  static TextStyle caption(
    Color color, {
    FontWeight fontWeight = FontWeight.w500,
  }) => TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    height: 14 / 11,
    fontWeight: fontWeight,
    color: color,
  );

  /// Terminal and code snippet style.
  static TextStyle code(Color color) => TextStyle(
    fontFamily: monoFontFamily,
    fontSize: 13.5,
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
      titleLarge: h1(colors.ink),
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
