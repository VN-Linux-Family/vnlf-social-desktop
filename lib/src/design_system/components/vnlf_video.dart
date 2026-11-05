import 'dart:async';

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../core/external_uri.dart';
import '../models/vnlf_models.dart';
import '../tokens/vnlf_colors.dart';

/// Video resources are allocated only after an explicit play action.
class VnlfVideo extends StatefulWidget {
  const VnlfVideo({super.key, required this.media});
  final PostMediaData media;
  @override
  State<VnlfVideo> createState() => _VnlfVideoState();
}

class _VnlfVideoState extends State<VnlfVideo> with WidgetsBindingObserver {
  Player? _player;
  VideoController? _video;
  StreamSubscription<String>? _errors;
  bool _failed = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) unawaited(_player?.pause());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_errors?.cancel());
    unawaited(_player?.dispose());
    super.dispose();
  }

  Future<void> _play() async {
    if (_loading || externalWebUri(widget.media.url) == null) return;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      MediaKit.ensureInitialized();
      _player ??= Player();
      _video ??= VideoController(_player!);
      _errors ??= _player!.stream.error.listen((_) {
        if (mounted) setState(() => _failed = true);
      });
      await _player!.open(Media(widget.media.url));
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final english = Localizations.localeOf(context).languageCode == 'en';
    final unavailable =
        widget.media.state == 'FAILED' ||
        externalWebUri(widget.media.url) == null;
    if (widget.media.state == 'PROCESSING' || unavailable) {
      return Container(
        constraints: const BoxConstraints(minHeight: 120),
        alignment: Alignment.center,
        color: VnlfColors.of(context).surfaceSoft,
        child: Text(
          widget.media.state == 'PROCESSING'
              ? (english ? 'Video is processing' : 'Video đang được xử lý')
              : (english ? 'Video unavailable' : 'Video không khả dụng'),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: AspectRatio(
        aspectRatio: widget.media.aspectRatio,
        child: _video != null && !_failed
            ? Video(controller: _video!, controls: AdaptiveVideoControls)
            : ColoredBox(
                color: VnlfColors.of(context).surfaceSoft,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (externalWebUri(widget.media.posterUrl) != null &&
                        !_failed)
                      Image.network(
                        widget.media.posterUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) =>
                            const SizedBox.shrink(),
                      ),
                    Center(
                      child: _loading
                          ? const CircularProgressIndicator()
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  iconSize: 48,
                                  tooltip: english
                                      ? 'Play video'
                                      : 'Phát video',
                                  onPressed: _play,
                                  icon: const Icon(
                                    Icons.play_circle_fill_rounded,
                                  ),
                                ),
                                if (_failed)
                                  Text(
                                    english
                                        ? 'Video unavailable. Tap to retry.'
                                        : 'Không phát được video. Bấm để thử lại.',
                                  ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
