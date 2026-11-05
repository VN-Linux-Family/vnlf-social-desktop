import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player_win/video_player_win.dart';

import '../../core/external_uri.dart';
import '../models/vnlf_models.dart';
import '../tokens/vnlf_colors.dart';
import 'vnlf_windows_video_surface.dart';

/// Windows uses the OS media stack on both x64 and ARM64.
class VnlfWindowsVideo extends StatefulWidget {
  const VnlfWindowsVideo({
    super.key,
    required this.media,
    this.createController,
  });
  final PostMediaData media;
  final WinVideoPlayerController Function(Uri)? createController;
  @override
  State<VnlfWindowsVideo> createState() => _VnlfWindowsVideoState();
}

class _VnlfWindowsVideoState extends State<VnlfWindowsVideo>
    with WidgetsBindingObserver {
  WinVideoPlayerController? _controller;
  Future<void>? _opening;
  bool _loading = false;
  bool _failed = false;
  bool _busy = false;
  bool _foreground = true;
  int _revision = 0;
  Route<void>? _expandedRoute;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didUpdateWidget(covariant VnlfWindowsVideo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.media.url != widget.media.url) {
      _detach();
      _loading = _failed = _busy = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    final controller = _controller;
    if (!_foreground && controller?.value.isInitialized == true) {
      unawaited(_operate(controller!.pause));
    }
  }

  void _detach() {
    _closeExpanded();
    _revision++;
    final controller = _controller;
    final opening = _opening;
    _controller = null;
    _opening = null;
    if (controller != null) unawaited(_release(controller, opening));
  }

  Future<void> _release(
    WinVideoPlayerController controller,
    Future<void>? opening,
  ) async {
    // The backend cannot cancel an in-flight open. Keep its notifier alive until
    // open settles, then release it; a detached generation can never start play.
    try {
      await opening;
    } catch (_) {
      /* The opening failure is shown by _start. */
    }
    try {
      if (controller.value.isInitialized) await controller.pause();
    } catch (_) {
      /* Disposal below still releases the native player. */
    }
    try {
      await controller.dispose();
    } catch (_) {
      /* Detached platform cleanup has no active UI. */
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _detach();
    super.dispose();
  }

  Future<void> _start() async {
    if (_loading) return;
    final uri = externalWebUri(widget.media.url);
    if (uri == null) return;
    _detach();
    final revision = _revision;
    final controller =
        widget.createController?.call(uri) ??
        WinVideoPlayerController.networkUrl(uri);
    _controller = controller;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final opening = controller.initialize();
      _opening = opening;
      await opening.timeout(const Duration(seconds: 30));
      if (!mounted || revision != _revision) return;
      if (!controller.value.isInitialized || controller.value.hasError) {
        throw StateError('Video initialization failed');
      }
      if (_foreground) await controller.play();
    } catch (_) {
      if (mounted && revision == _revision) setState(() => _failed = true);
    } finally {
      if (mounted && revision == _revision) setState(() => _loading = false);
    }
  }

  Future<void> _operate(Future<void> Function() operation) async {
    if (_busy) return;
    final revision = _revision;
    setState(() => _busy = true);
    try {
      await operation();
    } catch (_) {
      if (mounted && revision == _revision) setState(() => _failed = true);
    } finally {
      if (mounted && revision == _revision) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final english = Localizations.localeOf(context).languageCode == 'en';
    final controller = _controller;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: AspectRatio(
        aspectRatio: widget.media.aspectRatio,
        child: controller == null || _failed || _loading
            ? _preview(english)
            : _surface(controller, english),
      ),
    );
  }

  Widget _surface(
    WinVideoPlayerController controller,
    bool english, {
    bool expanded = false,
  }) => VnlfWindowsVideoSurface(
    controller: controller,
    english: english,
    onFailure: () {
      if (mounted && identical(controller, _controller)) {
        setState(() => _failed = true);
      }
    },
    errorBuilder: () => _preview(english, failed: true),
    onExpand: expanded ? null : () => _expand(controller, english),
  );
  void _expand(WinVideoPlayerController controller, bool english) {
    if (_expandedRoute != null) return;
    final route = MaterialPageRoute<void>(
      builder: (_) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: Text(widget.media.alt.isEmpty ? 'Video' : widget.media.alt),
        ),
        body: SafeArea(
          child: Center(
            child: AspectRatio(
              aspectRatio: widget.media.aspectRatio,
              child: _surface(controller, english, expanded: true),
            ),
          ),
        ),
      ),
    );
    _expandedRoute = route;
    unawaited(
      Navigator.of(context).push(route).whenComplete(() {
        if (identical(_expandedRoute, route)) _expandedRoute = null;
      }),
    );
  }

  void _closeExpanded() {
    final route = _expandedRoute;
    _expandedRoute = null;
    if (route == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navigator = route.navigator;
      if (navigator != null && navigator.mounted && route.isActive) {
        navigator.removeRoute(route);
      }
    });
  }

  Widget _preview(bool english, {bool failed = false}) => ColoredBox(
    color: VnlfColors.of(context).surfaceSoft,
    child: Stack(
      fit: StackFit.expand,
      children: [
        if (!_failed &&
            !failed &&
            externalWebUri(widget.media.posterUrl) != null)
          Image.network(
            widget.media.posterUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const SizedBox(),
          ),
        Center(
          child: _loading
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      iconSize: 48,
                      tooltip: _failed || failed
                          ? (english ? 'Retry video' : 'Thử lại video')
                          : (english ? 'Play video' : 'Phát video'),
                      onPressed: _start,
                      icon: const Icon(Icons.play_circle_fill_rounded),
                    ),
                    if (_failed || failed)
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
  );
}
