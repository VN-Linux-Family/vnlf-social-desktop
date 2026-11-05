import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/l10n/app_localizations.dart';
import 'package:vnlfsocialapp/src/design_system/design_system.dart';

void main() {
  group('Safe Area Insets', () {
    testWidgets('mobile header and bottom nav include top and bottom insets', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const insets = EdgeInsets.only(top: 48, bottom: 34, left: 12, right: 12);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: MediaQuery(
              data: const MediaQueryData(
                size: Size(390, 844),
                padding: insets,
                viewPadding: insets,
              ),
              child: VnlfAdaptiveShell(
                centerChild: const Text('Mobile Content'),
                onDestinationSelected: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Header should occupy 64 (content) + 48 (safe area top) + 1 (border) = 113 height
      final headerFinder = find.byType(VnlfMobileStickyHeader);
      expect(headerFinder, findsOneWidget);
      final headerSize = tester.getSize(headerFinder);
      expect(
        headerSize.height,
        greaterThanOrEqualTo(VnlfDimensions.mobileHeaderHeight + insets.top),
      );

      // Bottom nav should occupy 56 (content) + 34 (safe area bottom) + 1 (border) = 91 height
      final bottomNavFinder = find.byType(VnlfMobileBottomNav);
      expect(bottomNavFinder, findsOneWidget);
      final bottomNavSize = tester.getSize(bottomNavFinder);
      expect(
        bottomNavSize.height,
        greaterThanOrEqualTo(
          VnlfDimensions.mobileBottomNavHeight + insets.bottom,
        ),
      );

      // Verify that interactive buttons inside the header and nav are below top inset and above bottom inset
      final menuButton = find.byIcon(Icons.menu_rounded);
      expect(menuButton, findsOneWidget);
      final menuTop = tester.getTopLeft(menuButton).dy;
      expect(menuTop, greaterThanOrEqualTo(insets.top));

      final firstNavIcon = find.byIcon(Icons.grid_view_rounded);
      expect(firstNavIcon, findsOneWidget);
      final navIconBottom = tester.getBottomRight(firstNavIcon).dy;
      expect(navIconBottom, lessThanOrEqualTo(844 - insets.bottom));
    });

    testWidgets('tablet and desktop shells wrap content in SafeArea', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const insets = EdgeInsets.only(top: 24, bottom: 20, left: 16, right: 16);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: MediaQuery(
              data: const MediaQueryData(
                size: Size(1280, 800),
                padding: insets,
                viewPadding: insets,
              ),
              child: VnlfAdaptiveShell(
                centerChild: const Text('Desktop Content'),
                onDestinationSelected: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final safeAreaFinder = find.byType(SafeArea);
      expect(safeAreaFinder, findsWidgets);

      final sidebarFinder = find.byType(VnlfDesktopSidebar);
      expect(sidebarFinder, findsOneWidget);
      final sidebarTop = tester.getTopLeft(sidebarFinder).dy;
      expect(sidebarTop, greaterThanOrEqualTo(insets.top));
    });
  });
}
