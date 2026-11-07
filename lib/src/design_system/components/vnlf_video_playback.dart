import 'package:flutter/widgets.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

/// A native player owns its decoding surface and resources for one media URL.
abstract interface class VnlfVideoPlayback {
  Future<void> open(Uri uri);
  Future<void> get firstFrame;
  Future<void> play();
  Future<void> pause();
  Future<void> dispose();
  Widget buildSurface();
}

final class MediaKitVideoPlayback implements VnlfVideoPlayback {
  MediaKitVideoPlayback() {
    MediaKit.ensureInitialized();
    _player = Player();
    _video = VideoController(_player);
  }
  late final Player _player;
  late final VideoController _video;
  Future<void>? _opening;

  @override
  Future<void> open(Uri uri) =>
      _opening = _player.open(Media(uri.toString()), play: false);
  // Decoder diagnostics can describe a failed hardware attempt followed by a
  // successful software fallback. A decoded frame confirms usable video.
  @override
  Future<void> get firstFrame => _video.waitUntilFirstFrameRendered;
  @override
  Future<void> play() => _player.play();
  @override
  Future<void> pause() => _player.pause();
  @override
  Future<void> dispose() async {
    try {
      await _opening;
    } catch (_) {
      /* The owning widget reports open failures. */
    }
    await _player.dispose();
  }

  @override
  Widget buildSurface() =>
      Video(controller: _video, controls: AdaptiveVideoControls);
}
