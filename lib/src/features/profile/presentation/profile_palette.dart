import 'package:flutter/material.dart';

import '../domain/profile_theme.dart';
import '../domain/public_profile.dart';

/// A profile theme's colours for the app's current brightness, as the
/// website maps `--profile-accent`, `--profile-canvas` and the cover.
final class ProfilePalette {
  const ProfilePalette._({
    required this.accent,
    required this.accentInk,
    required this.canvas,
    required this.coverFrom,
    required this.coverTo,
    required this.mono,
  });

  factory ProfilePalette.of(BuildContext context, ProfileDecor decor) {
    final theme = profileThemeColors(decor.themeId, decor.accentColor);
    final colors = Theme.of(context).brightness == Brightness.dark
        ? theme.dark
        : theme.light;
    return ProfilePalette._(
      accent: _color(colors.accent),
      accentInk: _color(colors.accentInk),
      canvas: _color(colors.canvas),
      coverFrom: _color(colors.coverFrom),
      coverTo: _color(colors.coverTo),
      mono: theme.mono,
    );
  }

  final Color accent;
  final Color accentInk;
  final Color canvas;
  final Color coverFrom;
  final Color coverTo;

  /// `terminal` writes the handle, status and numbers in a monospace font.
  final bool mono;

  /// The cover band without an image: CSS `linear-gradient(135deg, …)` over
  /// a [size] box, which runs corner to corner only when the box is square.
  Gradient cover(Size size) {
    final reach = size.width + size.height;
    final x = size.width == 0 ? 1.0 : reach / (2 * size.width);
    final y = size.height == 0 ? 1.0 : reach / (2 * size.height);
    return LinearGradient(
      begin: Alignment(-x, -y),
      end: Alignment(x, y),
      colors: [coverFrom, coverTo],
    );
  }

  static Color _color(String hex) =>
      Color(0xff000000 | int.parse(hex.substring(1), radix: 16));
}

/// The monospace stack the website gives the terminal theme.
const profileMonoFamilies = ['JetBrains Mono', 'DejaVu Sans Mono', 'monospace'];
