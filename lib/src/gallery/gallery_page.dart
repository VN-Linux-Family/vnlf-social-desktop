import 'package:flutter/material.dart';

import '../design_system/design_system.dart';
import 'screens/vnlf_feed_screen.dart';
import 'screens/vnlf_profile_screen.dart';
import 'screens/vnlf_thread_screen.dart';
import 'screens/vnlf_tokens_catalog_view.dart';
import 'widgets/gallery_side_by_side_view.dart';
import 'widgets/gallery_workbench_bar.dart';

/// Screens available in the `/gallery` workbench.
enum GalleryScreenTab {
  feed('Bảng tin (Feed)'),
  thread('Bài viết (Thread)'),
  profile('Hồ sơ (Profile)'),
  sideBySide('Phone + Desktop'),
  tokens('Tokens & Components');

  const GalleryScreenTab(this.label);
  final String label;
}

/// Viewport width presets for testing responsive breakpoints at `/gallery`.
enum GalleryViewportPreset {
  responsive('Tự động', null),
  phone('Phone (390px)', 390.0),
  tablet('Tablet (960px)', 960.0),
  desktop('Desktop (1280px)', 1280.0);

  const GalleryViewportPreset(this.label, this.width);
  final String label;
  final double? width;
}

/// Primary `/gallery` page showcasing VNLF design tokens, atomic components,
/// and the 3 key screens (`feed`, `thread`, `profile`) at phone (`< 840px`)
/// and desktop (`>= 1181px`) widths.
class GalleryPage extends StatefulWidget {
  const GalleryPage({
    super.key,
    this.initialScreen = GalleryScreenTab.feed,
    this.initialViewport = GalleryViewportPreset.responsive,
    this.initialThemeMode = ThemeMode.light,
    this.showGalleryToolbar = true,
  });

  final GalleryScreenTab initialScreen;
  final GalleryViewportPreset initialViewport;
  final ThemeMode initialThemeMode;
  final bool showGalleryToolbar;

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  late GalleryScreenTab _activeScreen;
  late GalleryViewportPreset _viewportPreset;
  late ThemeMode _themeMode;
  late bool _showToolbar;

  @override
  void initState() {
    super.initState();
    _activeScreen = widget.initialScreen;
    _viewportPreset = widget.initialViewport;
    _themeMode = widget.initialThemeMode;
    _showToolbar = widget.showGalleryToolbar;
  }

  ThemeData _resolveTheme(BuildContext context) {
    final platformBrightness = MediaQuery.platformBrightnessOf(context);
    final useDark =
        _themeMode == ThemeMode.dark ||
        (_themeMode == ThemeMode.system &&
            platformBrightness == Brightness.dark);
    return useDark ? VnlfTheme.dark() : VnlfTheme.light();
  }

  Widget _buildScreenBody(GalleryScreenTab tab) {
    return switch (tab) {
      GalleryScreenTab.feed => VnlfFeedScreen(
        themeMode: _themeMode,
        onThemeModeChanged: (mode) => setState(() => _themeMode = mode),
        onOpenThread: () =>
            setState(() => _activeScreen = GalleryScreenTab.thread),
        onOpenProfile: () =>
            setState(() => _activeScreen = GalleryScreenTab.profile),
      ),
      GalleryScreenTab.thread => VnlfThreadScreen(
        themeMode: _themeMode,
        onThemeModeChanged: (mode) => setState(() => _themeMode = mode),
        onBackToFeed: () =>
            setState(() => _activeScreen = GalleryScreenTab.feed),
        onOpenProfile: () =>
            setState(() => _activeScreen = GalleryScreenTab.profile),
      ),
      GalleryScreenTab.profile => VnlfProfileScreen(
        themeMode: _themeMode,
        onThemeModeChanged: (mode) => setState(() => _themeMode = mode),
        onOpenThread: () =>
            setState(() => _activeScreen = GalleryScreenTab.thread),
        onBackToFeed: () =>
            setState(() => _activeScreen = GalleryScreenTab.feed),
      ),
      GalleryScreenTab.tokens => const VnlfTokensCatalogView(),
      GalleryScreenTab.sideBySide => SideBySideViewportComparison(
        themeMode: _themeMode,
        onThemeModeChanged: (mode) => setState(() => _themeMode = mode),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final activeTheme = _resolveTheme(context);
    final colors = activeTheme.extension<VnlfColors>() ?? VnlfColors.light;

    return Theme(
      data: activeTheme,
      child: Scaffold(
        backgroundColor: colors.bg,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_showToolbar)
              GalleryWorkbenchBar(
                activeScreen: _activeScreen,
                onScreenChanged: (tab) => setState(() => _activeScreen = tab),
                viewportPreset: _viewportPreset,
                onViewportChanged: (preset) =>
                    setState(() => _viewportPreset = preset),
                themeMode: _themeMode,
                onThemeModeChanged: (mode) => setState(() => _themeMode = mode),
                onHideToolbar: () => setState(() => _showToolbar = false),
              ),
            Expanded(
              child: Stack(
                children: [
                  _ViewportFrameContainer(
                    preset: _activeScreen == GalleryScreenTab.sideBySide
                        ? GalleryViewportPreset.responsive
                        : _viewportPreset,
                    child: _buildScreenBody(_activeScreen),
                  ),
                  if (!_showToolbar)
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Opacity(
                        opacity: 0.0,
                        child: GestureDetector(
                          onTap: () => setState(() => _showToolbar = true),
                          child: const Text('Thư viện giao diện'),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ViewportFrameContainer extends StatelessWidget {
  const _ViewportFrameContainer({required this.preset, required this.child});

  final GalleryViewportPreset preset;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final targetWidth = preset.width;
    if (targetWidth == null) {
      return child;
    }

    final colors = VnlfColors.of(context);
    return ColoredBox(
      color: colors.surfaceSoft,
      child: Center(
        child: Container(
          width: targetWidth,
          decoration: BoxDecoration(
            color: colors.bg,
            border: Border.symmetric(
              vertical: BorderSide(color: colors.line, width: 1.5),
            ),
            boxShadow: VnlfDimensions.hardShadow(isDark: colors.isDark),
          ),
          clipBehavior: Clip.antiAlias,
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              size: Size(targetWidth, MediaQuery.sizeOf(context).height),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
