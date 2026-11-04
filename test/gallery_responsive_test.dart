import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/design_system/design_system.dart';
import 'package:vnlfsocialapp/src/gallery/gallery_page.dart';

void main() {
  setUpAll(() async {
    final loader = FontLoader('BeVietnamPro');
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      loader.addFont(rootBundle.load('assets/fonts/BeVietnamPro-$weight.ttf'));
    }
    await loader.load();
  });

  Future<void> openGallery(
    WidgetTester tester,
    Size size, {
    GalleryScreenTab screen = GalleryScreenTab.feed,
    double scale = 1.0,
    ThemeMode themeMode = ThemeMode.light,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: VnlfTheme.light(),
        darkTheme: VnlfTheme.dark(),
        themeMode: themeMode,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: GalleryPage(initialScreen: screen, initialThemeMode: themeMode),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder permanentDesktopSidebar() => find.byWidgetPredicate(
    (widget) => widget is VnlfDesktopSidebar && !widget.isDrawer,
    description: 'permanent desktop sidebar',
  );

  // 1. Multi-breakpoint responsive layout checks
  const breakpoints = [360.0, 840.0, 841.0, 1180.0, 1181.0, 1440.0];
  for (final width in breakpoints) {
    for (final screen in [
      GalleryScreenTab.feed,
      GalleryScreenTab.thread,
      GalleryScreenTab.profile,
      GalleryScreenTab.tokens,
    ]) {
      testWidgets('${screen.name} fits viewport $width with zero overflow', (
        tester,
      ) async {
        await openGallery(tester, Size(width, 1000), screen: screen);
        expect(tester.takeException(), isNull);
        expect(find.text('Thư viện giao diện'), findsOneWidget);
      });
    }
  }

  // The 840px and 1180px cutoffs follow the production responsive tiers
  // recorded in DESIGN_REFERENCE.md.
  testWidgets('360px shows mobile navigation and an accessible drawer', (
    tester,
  ) async {
    await openGallery(tester, const Size(360, 900));

    expect(find.byType(VnlfMobileBottomNav), findsOneWidget);
    expect(find.byType(VnlfTabletRail), findsNothing);
    expect(permanentDesktopSidebar(), findsNothing);

    final menuButton = find.byTooltip('Mở menu điều hướng');
    expect(menuButton, findsOneWidget);
    await tester.tap(menuButton);
    await tester.pumpAndSettle();

    expect(find.byType(Drawer), findsOneWidget);
    expect(find.byType(VnlfDesktopSidebar), findsOneWidget);
    expect(find.text('Hỗ trợ cộng đồng'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('900px shows the tablet rail only', (tester) async {
    await openGallery(tester, const Size(900, 1000));

    expect(find.byType(VnlfTabletRail), findsOneWidget);
    expect(find.byType(VnlfMobileBottomNav), findsNothing);
    expect(permanentDesktopSidebar(), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('1440px shows the desktop sidebar and leaderboard', (
    tester,
  ) async {
    await openGallery(tester, const Size(1440, 1000));

    expect(permanentDesktopSidebar(), findsOneWidget);
    expect(find.byType(VnlfLeaderboardCard), findsOneWidget);
    expect(find.byType(VnlfTabletRail), findsNothing);
    expect(find.byType(VnlfMobileBottomNav), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final viewport in [
    (name: '600x900 portrait', size: const Size(600, 900)),
    (name: '700x360 landscape phone', size: const Size(700, 360)),
  ]) {
    testWidgets('${viewport.name} uses mobile layout without overflow', (
      tester,
    ) async {
      await openGallery(tester, viewport.size);

      expect(find.byType(VnlfMobileBottomNav), findsOneWidget);
      expect(find.byType(VnlfTabletRail), findsNothing);
      expect(permanentDesktopSidebar(), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  // 2. Vietnamese diacritic rendering & 200% text scaling
  testWidgets('renders Vietnamese diacritics under 200% text scaling', (
    tester,
  ) async {
    await openGallery(
      tester,
      const Size(390, 844),
      screen: GalleryScreenTab.feed,
      scale: 2.0,
    );
    expect(tester.takeException(), isNull);
  });

  // 3. Dark mode scrolling at 200% scale
  for (final screen in [
    GalleryScreenTab.feed,
    GalleryScreenTab.thread,
    GalleryScreenTab.profile,
  ]) {
    testWidgets('${screen.name} scrolls cleanly at 200% scale in dark mode', (
      tester,
    ) async {
      await openGallery(
        tester,
        const Size(360, 844),
        screen: screen,
        scale: 2.0,
        themeMode: ThemeMode.dark,
      );
      expect(tester.takeException(), isNull);
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
