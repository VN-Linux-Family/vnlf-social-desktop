import 'package:flutter/material.dart';

import '../../../design_system/design_system.dart';

/// Keeps project identity on accents while surfaces follow the active theme.
final class ProjectAccent {
  ProjectAccent(String? value, this.colors) : _projectColor = _parseHex(value);

  final VnlfColors colors;
  final Color? _projectColor;

  Color get color => _projectColor ?? colors.brand;

  Color get soft => _projectColor == null
      ? colors.brandSoft
      : Color.alphaBlend(
          color.withValues(alpha: colors.isDark ? 0.18 : 0.1),
          colors.paper,
        );

  Color get onColor {
    for (final candidate in [colors.ink, colors.paper]) {
      if (_contrast(color, candidate) >= 4.5) return candidate;
    }
    return _contrast(color, Colors.black) > _contrast(color, Colors.white)
        ? Colors.black
        : Colors.white;
  }

  /// Adjusts only an icon's foreground when the supplied accent is too faint.
  Color onSurface(Color background) {
    for (var step = 0; step <= 10; step++) {
      final candidate = Color.lerp(color, colors.ink, step / 10)!;
      if (_contrast(background, candidate) >= 3) return candidate;
    }
    return colors.ink;
  }

  static Color? _parseHex(String? value) {
    final hex = value?.trim();
    if (hex == null ||
        !RegExp(r'^#(?:[0-9a-fA-F]{3}|[0-9a-fA-F]{6})$').hasMatch(hex)) {
      return null;
    }
    var digits = hex.substring(1);
    if (digits.length == 3) {
      digits = digits.split('').map((digit) => '$digit$digit').join();
    }
    return Color(0xff000000 | int.parse(digits, radix: 16));
  }

  static double _contrast(Color first, Color second) {
    final a = first.computeLuminance();
    final b = second.computeLuminance();
    return a > b ? (a + 0.05) / (b + 0.05) : (b + 0.05) / (a + 0.05);
  }
}
