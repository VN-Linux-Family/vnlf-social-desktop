import 'package:flutter/material.dart';

import '../design_system/design_system.dart';
import 'screens/vnlf_feed_screen.dart';
import 'screens/vnlf_profile_screen.dart';
import 'screens/vnlf_thread_screen.dart';
import 'screens/vnlf_tokens_catalog_view.dart';

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
/// and the 3 key screens (`feed`, `thread`, `profile`) at phone (`<= 840px`)
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
      GalleryScreenTab.sideBySide => _SideBySideViewportComparison(
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
              _GalleryWorkbenchBar(
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

/// Renders Phone (`390px <= 840px`) and Desktop (`1280px >= 1181px`) side-by-side
/// for any of the 3 key screens (`feed`, `thread`, `profile`).
class _SideBySideViewportComparison extends StatefulWidget {
  const _SideBySideViewportComparison({
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  @override
  State<_SideBySideViewportComparison> createState() =>
      _SideBySideViewportComparisonState();
}

class _SideBySideViewportComparisonState
    extends State<_SideBySideViewportComparison> {
  int _selectedKeyScreen = 0; // 0: Feed, 1: Thread, 2: Profile

  Widget _buildKeyScreen() {
    return switch (_selectedKeyScreen) {
      0 => VnlfFeedScreen(
        themeMode: widget.themeMode,
        onThemeModeChanged: widget.onThemeModeChanged,
      ),
      1 => VnlfThreadScreen(
        themeMode: widget.themeMode,
        onThemeModeChanged: widget.onThemeModeChanged,
      ),
      _ => VnlfProfileScreen(
        themeMode: widget.themeMode,
        onThemeModeChanged: widget.onThemeModeChanged,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    const labels = [
      '1. Bảng tin (Feed)',
      '2. Bài viết (Thread)',
      '3. Hồ sơ (Profile)',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border(bottom: BorderSide(color: colors.line)),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'So sánh khung nhìn Phone (<= 840px) & Desktop (>= 1181px):',
                style: VnlfTypography.meta(
                  colors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              for (var i = 0; i < labels.length; i++)
                ChoiceChip(
                  label: Text(
                    labels[i],
                    style: VnlfTypography.caption(
                      _selectedKeyScreen == i ? Colors.white : colors.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  selected: _selectedKeyScreen == i,
                  selectedColor: colors.brand,
                  backgroundColor: colors.surfaceSoft,
                  onSelected: (_) => setState(() => _selectedKeyScreen = i),
                ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Phone Frame (390px <= 840px)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Phone Viewport (390px <= 840px)',
                      style: VnlfTypography.meta(
                        colors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: Container(
                        width: 390,
                        decoration: BoxDecoration(
                          border: Border.all(color: colors.line),
                          borderRadius: BorderRadius.circular(
                            VnlfDimensions.radiusLg,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: MediaQuery(
                          data: MediaQuery.of(context)
                              .copyWith(size: const Size(390, 844)),
                          child: _buildKeyScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                // Desktop Frame (1280px >= 1181px)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Desktop Viewport (1280px >= 1181px)',
                      style: VnlfTypography.meta(
                        colors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: Container(
                        width: 1280,
                        decoration: BoxDecoration(
                          border: Border.all(color: colors.line),
                          borderRadius: BorderRadius.circular(
                            VnlfDimensions.radiusLg,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: MediaQuery(
                          data: MediaQuery.of(context)
                              .copyWith(size: const Size(1280, 900)),
                          child: _buildKeyScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _GalleryWorkbenchBar extends StatelessWidget {
  const _GalleryWorkbenchBar({
    required this.activeScreen,
    required this.onScreenChanged,
    required this.viewportPreset,
    required this.onViewportChanged,
    required this.themeMode,
    required this.onThemeModeChanged,
    required this.onHideToolbar,
  });

  final GalleryScreenTab activeScreen;
  final ValueChanged<GalleryScreenTab> onScreenChanged;
  final GalleryViewportPreset viewportPreset;
  final ValueChanged<GalleryViewportPreset> onViewportChanged;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final VoidCallback onHideToolbar;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(bottom: BorderSide(color: colors.line)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const VnlfLogoEmblem(size: 20),
            const SizedBox(width: 7),
            Text(
              'Thư viện giao diện',
              style: VnlfTypography.control(
                colors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 14),
            for (final tab in GalleryScreenTab.values) ...[
              _ToolbarPillButton(
                label: tab.label,
                selected: tab == activeScreen,
                onTap: () => onScreenChanged(tab),
              ),
              const SizedBox(width: 6),
            ],
            const SizedBox(width: 10),
            Container(width: 1, height: 18, color: colors.line),
            const SizedBox(width: 10),
            for (final preset in GalleryViewportPreset.values) ...[
              _ToolbarPillButton(
                label: preset.label,
                selected: preset == viewportPreset,
                onTap: () => onViewportChanged(preset),
              ),
              const SizedBox(width: 6),
            ],
            const SizedBox(width: 10),
            Container(width: 1, height: 18, color: colors.line),
            const SizedBox(width: 10),
            _ToolbarPillButton(
              label: themeMode == ThemeMode.dark ? '🌙 Tối' : '☀️ Sáng',
              selected: themeMode == ThemeMode.dark,
              onTap: () => onThemeModeChanged(
                themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
              ),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message: 'Ẩn thanh công cụ để chụp toàn màn hình',
              child: InkWell(
                borderRadius: BorderRadius.circular(VnlfDimensions.radiusSm),
                onTap: onHideToolbar,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.fullscreen_rounded,
                    size: 18,
                    color: colors.muted,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolbarPillButton extends StatelessWidget {
  const _ToolbarPillButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(VnlfDimensions.radiusSm),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
        decoration: BoxDecoration(
          color: selected ? colors.brandSoft : colors.surfaceSoft,
          borderRadius: BorderRadius.circular(VnlfDimensions.radiusSm),
          border: Border.all(
            color: selected
                ? colors.brand.withValues(alpha: 0.45)
                : colors.line,
          ),
        ),
        child: Text(
          label,
          style: VnlfTypography.caption(
            selected ? colors.brand : colors.muted,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
