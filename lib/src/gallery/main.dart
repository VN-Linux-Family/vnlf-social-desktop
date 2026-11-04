import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../design_system/design_system.dart';
import 'gallery_page.dart';

const String _screenEnv = String.fromEnvironment(
  'VNLF_SCREEN',
  defaultValue: 'feed',
);
const String _viewportEnv = String.fromEnvironment(
  'VNLF_VIEWPORT',
  defaultValue: 'responsive',
);
const String _themeEnv = String.fromEnvironment(
  'VNLF_THEME',
  defaultValue: 'light',
);
const bool _showToolbarEnv = bool.fromEnvironment(
  'VNLF_TOOLBAR',
  defaultValue: true,
);

GalleryScreenTab _parseScreen(String value) => switch (value) {
  'thread' => GalleryScreenTab.thread,
  'profile' => GalleryScreenTab.profile,
  'dual' => GalleryScreenTab.sideBySide,
  'tokens' => GalleryScreenTab.tokens,
  _ => GalleryScreenTab.feed,
};

GalleryViewportPreset _parseViewport(String value) => switch (value) {
  'phone' => GalleryViewportPreset.phone,
  'tablet' => GalleryViewportPreset.tablet,
  'desktop' => GalleryViewportPreset.desktop,
  _ => GalleryViewportPreset.responsive,
};

ThemeMode _parseThemeMode(String value) => switch (value) {
  'dark' => ThemeMode.dark,
  'system' => ThemeMode.system,
  _ => ThemeMode.light,
};

void main() {
  final screenshotDir = Platform.environment['VNLF_SCREENSHOT_DIR'];
  if (screenshotDir != null && screenshotDir.isNotEmpty) {
    runApp(
      ProviderScope(
        child: _AutomatedScreenshotHarness(outputDir: screenshotDir),
      ),
    );
    return;
  }
  runApp(const ProviderScope(child: VnlfGalleryApp()));
}

final GoRouter _galleryRouter = GoRouter(
  initialLocation: '/gallery',
  routes: [
    GoRoute(path: '/', redirect: (context, state) => '/gallery'),
    GoRoute(
      path: '/gallery',
      builder: (context, state) {
        final screenParam = state.uri.queryParameters['screen'] ?? _screenEnv;
        final viewportParam =
            state.uri.queryParameters['viewport'] ?? _viewportEnv;
        final themeParam = state.uri.queryParameters['theme'] ?? _themeEnv;
        final toolbarParam = state.uri.queryParameters['toolbar'];
        final showToolbar = toolbarParam == null
            ? _showToolbarEnv
            : toolbarParam != 'false';

        return GalleryPage(
          initialScreen: _parseScreen(screenParam),
          initialViewport: _parseViewport(viewportParam),
          initialThemeMode: _parseThemeMode(themeParam),
          showGalleryToolbar: showToolbar,
        );
      },
    ),
  ],
);

/// Standalone entrypoint for running and validating the VNLF component gallery
/// (`flutter run -t lib/src/gallery/main.dart -d linux`).
class VnlfGalleryApp extends StatelessWidget {
  const VnlfGalleryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'VNLF Social Gallery',
      debugShowCheckedModeBanner: false,
      theme: VnlfTheme.light(),
      darkTheme: VnlfTheme.dark(),
      routerConfig: _galleryRouter,
    );
  }
}

class _ScreenshotJob {
  const _ScreenshotJob({
    required this.fileName,
    required this.screen,
    required this.size,
    this.themeMode = ThemeMode.light,
    this.showToolbar = false,
  });

  final String fileName;
  final GalleryScreenTab screen;
  final Size size;
  final ThemeMode themeMode;
  final bool showToolbar;
}

class _AutomatedScreenshotHarness extends StatefulWidget {
  const _AutomatedScreenshotHarness({required this.outputDir});
  final String outputDir;

  @override
  State<_AutomatedScreenshotHarness> createState() =>
      _AutomatedScreenshotHarnessState();
}

class _AutomatedScreenshotHarnessState
    extends State<_AutomatedScreenshotHarness> {
  final GlobalKey _repaintKey = GlobalKey();

  static const List<_ScreenshotJob> _jobs = [
    _ScreenshotJob(
      fileName: 'argon_feed_desktop_1288x1088.png',
      screen: GalleryScreenTab.feed,
      size: Size(1288, 1088),
      showToolbar: false,
    ),
    _ScreenshotJob(
      fileName: 'argon_feed_desktop_dark.png',
      screen: GalleryScreenTab.feed,
      size: Size(1288, 1088),
      themeMode: ThemeMode.dark,
      showToolbar: false,
    ),
    _ScreenshotJob(
      fileName: 'argon_feed_phone_390x844.png',
      screen: GalleryScreenTab.feed,
      size: Size(390, 844),
      showToolbar: false,
    ),
    _ScreenshotJob(
      fileName: 'argon_thread_desktop_1288x1088.png',
      screen: GalleryScreenTab.thread,
      size: Size(1288, 1088),
      showToolbar: false,
    ),
    _ScreenshotJob(
      fileName: 'argon_thread_phone_390x844.png',
      screen: GalleryScreenTab.thread,
      size: Size(390, 844),
      showToolbar: false,
    ),
    _ScreenshotJob(
      fileName: 'argon_profile_desktop_1288x1088.png',
      screen: GalleryScreenTab.profile,
      size: Size(1288, 1088),
      showToolbar: false,
    ),
    _ScreenshotJob(
      fileName: 'argon_profile_phone_390x844.png',
      screen: GalleryScreenTab.profile,
      size: Size(390, 844),
      showToolbar: false,
    ),
    _ScreenshotJob(
      fileName: 'argon_gallery_tokens_desktop.png',
      screen: GalleryScreenTab.tokens,
      size: Size(1288, 1088),
      showToolbar: true,
    ),
  ];

  int _jobIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _captureLoop());
  }

  Future<void> _captureLoop() async {
    final dir = Directory(widget.outputDir);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    for (var i = 0; i < _jobs.length; i++) {
      if (!mounted) return;
      setState(() => _jobIndex = i);
      await Future<void>.delayed(const Duration(milliseconds: 350));
      await WidgetsBinding.instance.endOfFrame;

      final boundary =
          _repaintKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary != null) {
        final image = await boundary.toImage(pixelRatio: 1.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          final file = File('${dir.path}/${_jobs[i].fileName}');
          await file.writeAsBytes(byteData.buffer.asUint8List());
        }
      }
    }
    exit(0);
  }

  @override
  Widget build(BuildContext context) {
    final job = _jobs[_jobIndex];

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: VnlfTheme.light(),
      darkTheme: VnlfTheme.dark(),
      home: OverflowBox(
        minWidth: job.size.width,
        maxWidth: job.size.width,
        minHeight: job.size.height,
        maxHeight: job.size.height,
        alignment: Alignment.topLeft,
        child: RepaintBoundary(
          key: _repaintKey,
          child: SizedBox(
            width: job.size.width,
            height: job.size.height,
            child: MediaQuery(
              data: MediaQueryData(size: job.size, devicePixelRatio: 1.0),
              child: GalleryPage(
                key: ValueKey<String>(job.fileName),
                initialScreen: job.screen,
                initialViewport: GalleryViewportPreset.responsive,
                initialThemeMode: job.themeMode,
                showGalleryToolbar: job.showToolbar,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
