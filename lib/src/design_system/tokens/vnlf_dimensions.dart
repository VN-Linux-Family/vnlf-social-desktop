import 'package:flutter/material.dart';

/// Radii, breakpoints, container sizes, shadows, and motion tokens from `DESIGN_REFERENCE.md`.
abstract final class VnlfDimensions {
  // Border Radii
  /// `--radius-sm`: Tags, small pills, code blocks, badge frames (`6.0`).
  static const double radiusSm = 6.0;

  /// `--radius-md`: Standard buttons, inputs, post action bars (`10.0`).
  static const double radiusMd = 10.0;

  /// `--radius-lg`: Cards, dialogue modals, sheet containers (`14.0`).
  static const double radiusLg = 14.0;

  /// `--radius-full`: Avatars, pill filters, voting capsules (`999.0`).
  static const double radiusFull = 999.0;

  // Responsive Breakpoints
  /// Tablet viewport lower bound. Mobile is strictly below 840 logical pixels.
  static const double tabletMinWidth = 840.0;

  /// Desktop viewport lower bound (`>= 1181px`).
  static const double desktopMinWidth = 1181.0;

  // Layout Containers & Shell Metrics
  /// Desktop 3-column container width (`1280px`).
  static const double desktopContainerWidth = 1280.0;

  /// Left navigation sidebar fixed width (`252px`).
  static const double leftSidebarWidth = 252.0;

  /// Compact tablet navigation rail width (`72px`).
  static const double tabletRailWidth = 72.0;

  /// Center feed container max width (`717px`).
  static const double centerFeedMaxWidth = 717.0;

  /// Right complementary column width (`304px`).
  static const double rightSidebarWidth = 304.0;

  /// Sticky mobile top header height (`64px`).
  static const double mobileHeaderHeight = 64.0;

  /// Sticky mobile top header horizontal padding (`17px`).
  static const double mobileHeaderPaddingH = 17.0;

  /// Sticky mobile bottom navigation bar height (`56px`).
  static const double mobileBottomNavHeight = 56.0;

  /// Mobile secondary drawer max width (`320px`).
  static const double mobileDrawerMaxWidth = 320.0;

  // Motion Tokens (150-300ms, respects reduce-motion)
  static const Duration motionFast = Duration(milliseconds: 150);
  static const Duration motionNormal = Duration(milliseconds: 220);
  static const Duration motionSlow = Duration(milliseconds: 300);

  /// Returns [Duration.zero] when accessibility reduce-motion is enabled.
  static Duration resolveDuration(
    BuildContext context, [
    Duration duration = motionNormal,
  ]) {
    final disableAnimations =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return disableAnimations ? Duration.zero : duration;
  }

  // Shadows
  /// Light Mode Subtle (`--shadow`): `0px 1px 2px rgba(16, 24, 20, 0.05)`.
  static const List<BoxShadow> shadowLightSubtle = [
    BoxShadow(
      color: Color.fromRGBO(16, 24, 20, 0.05),
      offset: Offset(0, 1),
      blurRadius: 2,
    ),
  ];

  /// Light Mode Elevated (`--shadow-hard`): `0px 12px 32px rgba(16, 24, 20, 0.12), 0px 2px 6px rgba(16, 24, 20, 0.06)`.
  static const List<BoxShadow> shadowLightHard = [
    BoxShadow(
      color: Color.fromRGBO(16, 24, 20, 0.12),
      offset: Offset(0, 12),
      blurRadius: 32,
    ),
    BoxShadow(
      color: Color.fromRGBO(16, 24, 20, 0.06),
      offset: Offset(0, 2),
      blurRadius: 6,
    ),
  ];

  /// Dark Mode Subtle (`--shadow`): `0px 1px 2px rgba(0, 0, 0, 0.35)`.
  static const List<BoxShadow> shadowDarkSubtle = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.35),
      offset: Offset(0, 1),
      blurRadius: 2,
    ),
  ];

  /// Dark Mode Elevated (`--shadow-hard`): `0px 16px 40px rgba(0, 0, 0, 0.55), 0px 2px 8px rgba(0, 0, 0, 0.35)`.
  static const List<BoxShadow> shadowDarkHard = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.55),
      offset: Offset(0, 16),
      blurRadius: 40,
    ),
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.35),
      offset: Offset(0, 2),
      blurRadius: 8,
    ),
  ];

  static List<BoxShadow> subtleShadow({required bool isDark}) =>
      isDark ? shadowDarkSubtle : shadowLightSubtle;

  static List<BoxShadow> hardShadow({required bool isDark}) =>
      isDark ? shadowDarkHard : shadowLightHard;
}

/// Viewport classification according to `DESIGN_REFERENCE.md` Section 5.
enum VnlfViewportSize {
  /// `< 840px`: 1 column + sticky 64px top header + sticky 56px bottom nav.
  mobile,

  /// `840px <= width < 1181px`: compact nav rail + main feed surface.
  tablet,

  /// `>= 1181px`: 3 columns (252px left sidebar, 717px center feed, 304px right sidebar).
  desktop;

  static VnlfViewportSize fromWidth(double width) {
    if (width < VnlfDimensions.tabletMinWidth) {
      return VnlfViewportSize.mobile;
    }
    if (width < VnlfDimensions.desktopMinWidth) {
      return VnlfViewportSize.tablet;
    }
    return VnlfViewportSize.desktop;
  }
}
