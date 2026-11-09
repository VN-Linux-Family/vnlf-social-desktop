import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/external_uri.dart';
import '../../i18n/vi.dart';
import '../models/vnlf_models.dart';
import '../tokens/vnlf_colors.dart';
import 'vnlf_windows_video.dart';
import 'vnlf_video_playback.dart';

/// Video resources are allocated only after an explicit play action.
class VnlfVideo extends StatefulWidget {
  const VnlfVideo({super.key, required this.media, this.createPlayback});
  final PostMediaData media;
  final VnlfVideoPlayback Function()? createPlayback;
  @override
  State<VnlfVideo> createState() => _VnlfVideoState();
}

class _VnlfVideoState extends State<VnlfVideo> with WidgetsBindingObserver {
  VnlfVideoPlayback? _playback;
  Completer<void>? _released;
  bool _failed = false;
  bool _loading = false;
  bool _foreground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didUpdateWidget(covariant VnlfVideo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.media.url != widget.media.url ||
        oldWidget.media.state != widget.media.state &&
            (widget.media.state == 'FAILED' ||
                widget.media.state == 'PROCESSING')) {
      _release();
      _failed = _loading = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    final playback = _playback;
    if (!_foreground && playback != null) {
      unawaited(_pause(playback));
    }
  }

  Future<void> _pause(VnlfVideoPlayback playback) async {
    try {
      await playback.pause();
    } catch (_) {
      /* Open/disposal can overlap a lifecycle event. */
    }
  }

  void _release() {
    final playback = _playback;
    _playback = null;
    _released?.complete();
    _released = null;
    if (playback != null) unawaited(_disposePlayback(playback));
  }

  Future<void> _disposePlayback(VnlfVideoPlayback playback) async {
    try {
      await playback.dispose();
    } catch (_) {
      /* Detached native cleanup has no active UI. */
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _release();
    super.dispose();
  }

  Future<void> _play() async {
    final uri = externalWebUri(widget.media.url);
    if (_loading || uri == null) return;
    _release();
    VnlfVideoPlayback? playback;
    try {
      playback = widget.createPlayback?.call() ?? MediaKitVideoPlayback();
      final current = playback;
      final released = Completer<void>();
      setState(() {
        _playback = current;
        _released = released;
        _loading = true;
        _failed = false;
      });
      bool owns() => mounted && identical(_playback, current);
      await Future.any([current.open(uri), released.future])
          .timeout(const Duration(seconds: 30));
      if (!owns()) return;
      await Future.any([current.firstFrame, released.future])
          .timeout(const Duration(seconds: 20));
      if (!owns()) return;
      if (_foreground) {
        await current.play();
        if (!owns()) return;
        // An inactive event can arrive while the native play command is pending.
        if (!_foreground) await _pause(current);
      }
      if (owns()) setState(() => _loading = false);
    } catch (_) {
      if (mounted && (playback == null || identical(_playback, playback))) {
        _release();
        setState(() {
          _failed = true;
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
              ? vi.app.common.videoDangDuocXu
              : vi.app.designSystem.videoKhongKhaDung,
        ),
      );
    }
    if (Platform.isWindows && widget.createPlayback == null) {
      return VnlfWindowsVideo(media: widget.media);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: AspectRatio(
        aspectRatio: widget.media.aspectRatio,
        child: _playback != null && !_failed
            ? Stack(
                fit: StackFit.expand,
                children: [
                  AbsorbPointer(
                    absorbing: _loading,
                    child: _playback!.buildSurface(),
                  ),
                  if (_loading)
                    const Center(child: CircularProgressIndicator()),
                ],
              )
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
                                  tooltip: vi.app.designSystem.phatVideo,
                                  onPressed: _play,
                                  icon: const Icon(
                                    Icons.play_circle_fill_rounded,
                                  ),
                                ),
                                if (_failed)
                                  Text(vi.app.designSystem.khongPhatDuocVideo),
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
