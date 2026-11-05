import 'dart:io';

import 'package:flutter/material.dart';

import '../../../design_system/design_system.dart';
import '../../../domain/models.dart';

bool _loadNetworkAvatarDefault() {
  if (const bool.hasEnvironment('VNLF_LIVE')) {
    return const bool.fromEnvironment('VNLF_LIVE');
  }
  try {
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return false;
    }
  } catch (_) {}
  return true;
}

AuthorData presentAuthor(Author author) {
  final style = author.style;
  final badge =
      DistroBadgeType.values
          .where((badge) => badge.name == style?.distroBadge?.toLowerCase())
          .firstOrNull ??
      DistroBadgeType.none;

  List<Color>? gradientLight;
  List<Color>? gradientDark;
  final ng = style?.nameGradient;
  if (ng != null) {
    final fromLight = _color(ng['from']);
    final toLight = _color(ng['to']);
    final fromDark = _color(ng['from'], dark: true);
    final toDark = _color(ng['to'], dark: true);
    if (fromLight != null && toLight != null) {
      gradientLight = [fromLight, toLight];
    }
    if (fromDark != null && toDark != null) {
      gradientDark = [fromDark, toDark];
    }
  } else if (style?.nameplate case final np?) {
    final fromLight = _color(np['name']);
    final toLight = _color(np['name2']);
    final fromDark = _color(np['name'], dark: true);
    final toDark = _color(np['name2'], dark: true);
    if (fromLight != null && toLight != null) {
      gradientLight = [fromLight, toLight];
    }
    if (fromDark != null && toDark != null) {
      gradientDark = [fromDark, toDark];
    }
  }

  final effect = switch (style?.nameEffect?.toLowerCase()) {
    'glitch' => NameEffectType.glitch,
    'rainbow' => NameEffectType.rainbow,
    'cursor' => NameEffectType.cursor,
    _ => NameEffectType.none,
  };

  return AuthorData(
    id: author.id,
    username: author.username,
    displayName: author.displayName,
    role: author.role,
    avatarUrl: author.avatarUrl,
    loadNetworkAvatar: _loadNetworkAvatarDefault(),
    style: AuthorStyleData(
      nameColor: _color(style?.nameColor?['light'] ?? style?.nameColor),
      nameDarkColor: _color(
        style?.nameColor?['dark'] ?? style?.nameColor,
        dark: true,
      ),
      nameGradientLight: gradientLight,
      nameGradientDark: gradientDark,
      nameEffect: effect,
      frame: style?.frame == null ? AvatarFrameType.none : AvatarFrameType.ring,
      frameColor: _color(style?.frame?['color']),
      frameDarkColor: _color(style?.frame?['color'], dark: true),
      nameplateId: switch (style?.nameplate?['id']) {
        final String id => id,
        _ => null,
      },
      nameplateColor: _color(style?.nameplate?['color']),
      nameplateDarkColor: _color(style?.nameplate?['color'], dark: true),
      distroBadge: badge,
      distroBadgeLabel: style?.distroBadge,
      hasPixelBadge: style?.icon?['pixelArt'] == true,
      iconUrl: style?.icon?['url'] as String?,
      iconName: style?.icon?['name'] as String?,
    ),
  );
}

Color? _color(Object? value, {bool dark = false}) {
  final source = value is Map ? value[dark ? 'dark' : 'light'] : value;
  if (source is! String) return null;
  final hex = source.replaceFirst('#', '');
  if (hex.length != 6) return null;
  final number = int.tryParse(hex, radix: 16);
  return number == null ? null : Color(0xff000000 | number);
}
