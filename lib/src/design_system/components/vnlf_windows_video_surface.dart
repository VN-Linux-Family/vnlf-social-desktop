import 'package:flutter/material.dart';
import 'package:video_player_win/video_player_win.dart';

import '../../i18n/vi.dart';

/// A borrowed controller keeps the same playback position in the expanded view.
class VnlfWindowsVideoSurface extends StatefulWidget {
  const VnlfWindowsVideoSurface({
    super.key,
    required this.controller,
    required this.onFailure,
    required this.errorBuilder,
    this.onExpand,
  });
  final WinVideoPlayerController controller;
  final VoidCallback onFailure;
  final Widget Function() errorBuilder;
  final VoidCallback? onExpand;
  @override
  State<VnlfWindowsVideoSurface> createState() =>
      _VnlfWindowsVideoSurfaceState();
}

class _VnlfWindowsVideoSurfaceState extends State<VnlfWindowsVideoSurface> {
  bool _busy = false;
  bool _failed = false;
  Future<void> _operate(Future<void> Function() operation) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await operation();
    } catch (_) {
      if (mounted) {
        setState(() => _failed = true);
        widget.onFailure();
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) => ValueListenableBuilder<WinVideoPlayerValue>(
    valueListenable: widget.controller,
    child: WinVideoPlayer(widget.controller),
    builder: (context, value, video) {
      if (_failed || value.hasError || !value.isInitialized) {
        return widget.errorBuilder();
      }
      final max = value.duration.inMilliseconds
          .toDouble()
          .clamp(1, double.infinity)
          .toDouble();
      return Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(
            color: Colors.black,
            child: Center(
              child: AspectRatio(aspectRatio: value.aspectRatio, child: video),
            ),
          ),
          if (value.isBuffering)
            const Center(child: CircularProgressIndicator()),
          Align(
            alignment: Alignment.bottomCenter,
            child: ColoredBox(
              color: Colors.black.withValues(alpha: .7),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Slider(
                    value: value.position.inMilliseconds
                        .toDouble()
                        .clamp(0, max)
                        .toDouble(),
                    max: max,
                    onChanged: _busy
                        ? null
                        : (position) => _operate(
                            () => widget.controller.seekTo(
                              Duration(milliseconds: position.round()),
                            ),
                          ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        tooltip: value.isPlaying
                            ? vi.app.designSystem.tamDung
                            : vi.app.designSystem.phatVideo,
                        color: Colors.white,
                        onPressed: _busy
                            ? null
                            : () => _operate(
                                value.isPlaying
                                    ? widget.controller.pause
                                    : widget.controller.play,
                              ),
                        icon: Icon(
                          value.isPlaying ? Icons.pause : Icons.play_arrow,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '${_time(value.position)} / ${_time(value.duration)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      IconButton(
                        tooltip: value.volume == 0
                            ? vi.app.designSystem.batAmThanh
                            : vi.app.common.tatAmThanh,
                        color: Colors.white,
                        onPressed: _busy
                            ? null
                            : () => _operate(
                                () => widget.controller.setVolume(
                                  value.volume == 0 ? 1 : 0,
                                ),
                              ),
                        icon: Icon(
                          value.volume == 0
                              ? Icons.volume_off
                              : Icons.volume_up,
                        ),
                      ),
                      if (widget.onExpand != null)
                        IconButton(
                          tooltip: vi.app.designSystem.phongToVideo,
                          color: Colors.white,
                          onPressed: _busy ? null : widget.onExpand,
                          icon: const Icon(Icons.fullscreen),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    },
  );
}

String _time(Duration value) =>
    '${value.inMinutes}:${(value.inSeconds % 60).toString().padLeft(2, '0')}';
