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
  return AuthorData(
    id: author.id,
    username: author.username,
    displayName: author.displayName,
    role: author.role,
    avatarUrl: author.avatarUrl,
    loadNetworkAvatar: _loadNetworkAvatarDefault(),
    style: AuthorStyleData(
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
