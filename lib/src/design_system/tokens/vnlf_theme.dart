import 'package:flutter/material.dart';

import 'vnlf_colors.dart';
import 'vnlf_dimensions.dart';
import 'vnlf_typography.dart';

/// Builds [ThemeData] instances for light (`:root`) and dark (`html.vnlf-dark`) modes.
abstract final class VnlfTheme {
  static ThemeData light() => _build(VnlfColors.light, Brightness.light);

  static ThemeData dark() => _build(VnlfColors.dark, Brightness.dark);

  static ThemeData _build(VnlfColors colors, Brightness brightness) {
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: colors.brand,
      onPrimary: Colors.white,
      primaryContainer: colors.brandSoft,
      onPrimaryContainer: colors.brandStrong,
      secondary: colors.blue,
      onSecondary: Colors.white,
      error: colors.red,
      onError: Colors.white,
      surface: colors.surface,
      onSurface: colors.ink,
      outline: colors.line,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: VnlfTypography.fontFamily,
      scaffoldBackgroundColor: colors.bg,
      canvasColor: colors.paper,
      colorScheme: colorScheme,
      textTheme: VnlfTypography.textTheme(colors),
      dividerColor: colors.line,
      dividerTheme: DividerThemeData(
        color: colors.line,
        thickness: 1,
        space: 1,
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VnlfDimensions.radiusLg),
          side: BorderSide(color: colors.line),
        ),
      ),
      splashFactory: NoSplash.splashFactory,
      highlightColor: colors.surfaceSoft.withValues(alpha: 0.6),
      hoverColor: colors.surfaceSoft.withValues(alpha: 0.5),
      extensions: <ThemeExtension<dynamic>>[colors],
    );
  }
}
