import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('vi')],
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
      final searchButton = find.descendant(
        of: find.byType(VnlfMobileStickyHeader),
        matching: find.byWidgetPredicate(
          (w) => w is VnlfIcon && w.icon == VnlfLucide.search,
        ),
      );
      expect(searchButton, findsOneWidget);
      final searchTop = tester.getTopLeft(searchButton).dy;
      expect(searchTop, greaterThanOrEqualTo(insets.top));

      final firstNavIcon = find.byWidgetPredicate(
        (w) => w is VnlfIcon && w.icon == VnlfLucide.layoutGrid,
      );
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
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('vi')],
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
