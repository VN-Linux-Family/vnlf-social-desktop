import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vnlfsocialapp/src/app/app_router.dart';
import 'package:vnlfsocialapp/src/design_system/design_system.dart';
import 'package:vnlfsocialapp/src/features/channels/presentation/channels_screen.dart';
import 'package:vnlfsocialapp/src/features/search/presentation/search_screen.dart';
import 'package:vnlfsocialapp/src/features/voice/presentation/voice_screen.dart';

void main() {
  testWidgets('router navigates to every community route', (tester) async {
    final app = await _pumpApp(tester, const Size(360, 900));
    addTearDown(app.dispose);

    for (final route in _communityRoutes) {
      app.router.go(route.path);
      await tester.pumpAndSettle();

      expect(
        app.router.routeInformationProvider.value.uri.path,
        route.path,
        reason: 'router should navigate to ${route.path}',
      );
      expect(find.byType(route.screen), findsOneWidget, reason: route.path);
      expect(
        find.descendant(
          of: find.byType(route.screen),
          matching: find.text(route.vietnamese),
        ),
        findsOneWidget,
        reason: 'Vietnamese screen title for ${route.path}',
      );
    }
  });

  for (final viewport in [
    (name: 'mobile', width: 360.0),
    (name: 'tablet', width: 900.0),
    (name: 'desktop', width: 1440.0),
  ]) {
    testWidgets('${viewport.name} width renders its matching navigation', (
      tester,
    ) async {
      final app = await _pumpApp(tester, Size(viewport.width, 900));
      addTearDown(app.dispose);

      switch (viewport.name) {
        case 'mobile':
          expect(find.byType(VnlfMobileBottomNav), findsOneWidget);
          expect(_permanentDesktopSidebar(), findsNothing);
        case 'tablet':
          // The website keeps the full sidebar at 220px between 841 and 1180px.
          expect(find.byType(VnlfMobileBottomNav), findsNothing);
          expect(_permanentDesktopSidebar(), findsOneWidget);
          expect(tester.getSize(_permanentDesktopSidebar()).width, 220);
        case 'desktop':
          expect(find.byType(VnlfMobileBottomNav), findsNothing);
          expect(_permanentDesktopSidebar(), findsOneWidget);
          expect(tester.getSize(_permanentDesktopSidebar()).width, 252);
      }
    });
  }
  testWidgets('every community screen keeps its title and nav labels', (
    tester,
  ) async {
    final app = await _pumpApp(tester, const Size(360, 900));
    addTearDown(app.dispose);

    for (final route in _communityRoutes) {
      app.router.go(route.path);
      await tester.pumpAndSettle();
      _expectScreenTitle(route.screen, route.vietnamese);
      _expectMobileNavigation(tester, const [
        'Bảng tin',
        'Khám phá',
        'Tin nhắn',
        'Voice',
        'Mở menu',
      ]);
    }
  });
}

const _communityRoutes = <({String path, String vietnamese, Type screen})>[
  (path: '/search', vietnamese: 'Tìm trong cộng đồng', screen: SearchScreen),
  (
    path: '/channels',
    vietnamese: 'Đăng nhập để xem kênh cộng đồng',
    screen: ChannelsScreen,
  ),
  (
    path: '/voice',
    vietnamese: 'Đăng nhập để tham gia Voice',
    screen: VoiceScreen,
  ),
];

Future<_TestApp> _pumpApp(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final container = ProviderContainer(overrides: []);
  final router = createMainRouter();
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: _RouterApp(router: router),
    ),
  );
  await tester.pumpAndSettle();
  return _TestApp(container: container, router: router);
}

Finder _permanentDesktopSidebar() => find.byWidgetPredicate(
  (widget) => widget is VnlfDesktopSidebar && !widget.isDrawer,
  description: 'permanent desktop sidebar',
);

void _expectScreenTitle(Type screen, String title) {
  expect(find.byType(screen), findsOneWidget);
  expect(
    find.descendant(of: find.byType(screen), matching: find.text(title)),
    findsOneWidget,
  );
}

/// The phone bar is icon-only like the website; names stay semantic labels.
void _expectMobileNavigation(WidgetTester tester, List<String> labels) {
  final navigation = find.byType(VnlfMobileBottomNav);
  expect(navigation, findsOneWidget);
  for (final label in labels) {
    expect(
      find.descendant(
        of: navigation,
        matching: find.byWidgetPredicate(
          (widget) => widget is Semantics && widget.properties.label == label,
        ),
      ),
      findsOneWidget,
      reason: 'mobile navigation should announce $label',
    );
  }
}

class _RouterApp extends ConsumerWidget {
  const _RouterApp({required this.router});

  final GoRouter router;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      locale: const Locale('vi'),
      theme: VnlfTheme.light(),
      darkTheme: VnlfTheme.dark(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('vi')],
      routerConfig: router,
    );
  }
}

class _TestApp {
  const _TestApp({required this.container, required this.router});

  final ProviderContainer container;
  final GoRouter router;

  void dispose() {
    router.dispose();
    container.dispose();
  }
}
