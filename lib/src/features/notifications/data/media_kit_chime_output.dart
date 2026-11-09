import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';

import '../domain/community_sounds.dart';

/// Plays the chimes in `assets/sounds/` through one media_kit player, the
/// native player the app already uses for video.
final class MediaKitChimeOutput {
  Player? _player;
  bool _unavailable = false;

  Future<void> play(CommunityChime chime) async {
    if (_unavailable) return;
    try {
      MediaKit.ensureInitialized();
      final player = _player ??= Player();
      await player.open(Media('asset:///assets/sounds/${chime.file}'));
    } on Object catch (error) {
      // Linux needs libmpv from the system. Without it the app stays silent
      // instead of failing again for every message.
      _unavailable = true;
      debugPrint('Community chime unavailable: ${error.runtimeType}');
    }
  }

  Future<void> dispose() async {
    final player = _player;
    _player = null;
    await player?.dispose();
  }
}
