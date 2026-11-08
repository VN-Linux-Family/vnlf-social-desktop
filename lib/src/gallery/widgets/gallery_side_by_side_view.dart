import 'package:flutter/material.dart';

import '../../design_system/tokens/vnlf_colors.dart';
import '../../design_system/tokens/vnlf_dimensions.dart';
import '../../design_system/tokens/vnlf_typography.dart';
import '../screens/vnlf_feed_screen.dart';
import '../screens/vnlf_profile_screen.dart';
import '../screens/vnlf_thread_screen.dart';

/// Renders Phone (`390px < 840px`) and Desktop (`1280px >= 1181px`) side-by-side
/// for any of the 3 key screens (`feed`, `thread`, `profile`).
class SideBySideViewportComparison extends StatefulWidget {
  const SideBySideViewportComparison({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  @override
  State<SideBySideViewportComparison> createState() =>
      _SideBySideViewportComparisonState();
}

class _SideBySideViewportComparisonState
    extends State<SideBySideViewportComparison> {
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
                'So sánh khung nhìn Phone (< 840px) & Desktop (>= 1181px):',
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
                      _selectedKeyScreen == i ? colors.surface : colors.ink,
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
                // Phone Frame (390px < 840px)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Phone Viewport (390px < 840px)',
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
