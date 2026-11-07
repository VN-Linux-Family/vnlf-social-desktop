import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vnlfsocialapp/l10n/app_localizations.dart';
import 'package:vnlfsocialapp/src/app/app_router.dart';
import 'package:vnlfsocialapp/src/app/providers.dart';
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
          expect(find.byType(VnlfTabletRail), findsNothing);
          expect(_permanentDesktopSidebar(), findsNothing);
        case 'tablet':
          expect(find.byType(VnlfMobileBottomNav), findsNothing);
          expect(find.byType(VnlfTabletRail), findsOneWidget);
          expect(_permanentDesktopSidebar(), findsNothing);
        case 'desktop':
          expect(find.byType(VnlfMobileBottomNav), findsNothing);
          expect(find.byType(VnlfTabletRail), findsNothing);
          expect(_permanentDesktopSidebar(), findsOneWidget);
      }
    });
  }

  testWidgets('locale override rebuilds every community screen and nav label', (
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
        'Dự án',
      ]);
    }

    app.container.read(localeProvider.notifier).state = const Locale('en');
    await tester.pumpAndSettle();

    for (final route in _communityRoutes) {
      app.router.go(route.path);
      await tester.pumpAndSettle();
      _expectScreenTitle(route.screen, route.english);
      _expectMobileNavigation(tester, const [
        'Feed',
        'Discover',
        'Messages',
        'Voice',
        'Projects',
      ]);
    }
  });
}

const _communityRoutes =
    <({String path, String vietnamese, String english, Type screen})>[
      (
        path: '/search',
        vietnamese: 'Tìm kiếm',
        english: 'Search',
        screen: SearchScreen,
      ),
      (
        path: '/channels',
        vietnamese: 'Đăng nhập để xem kênh cộng đồng',
        english: 'Sign in to view community channels',
        screen: ChannelsScreen,
      ),
      (
        path: '/voice',
        vietnamese: 'Kênh thoại',
        english: 'Voice',
        screen: VoiceScreen,
      ),
    ];

Future<_TestApp> _pumpApp(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final container = ProviderContainer(
    overrides: [
      localeProvider.overrideWith(
        (ref) => LocaleController(
          ref.watch(preferencesStorageProvider),
          null,
          const Locale('vi'),
        ),
      ),
    ],
  );
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

void _expectMobileNavigation(WidgetTester tester, List<String> labels) {
  final navigation = find.byType(VnlfMobileBottomNav);
  expect(navigation, findsOneWidget);
  for (final label in labels) {
    expect(
      find.descendant(of: navigation, matching: find.text(label)),
      findsOneWidget,
      reason: 'mobile navigation should show $label',
    );
  }
}

class _RouterApp extends ConsumerWidget {
  const _RouterApp({required this.router});

  final GoRouter router;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      locale: ref.watch(localeProvider),
      theme: VnlfTheme.light(),
      darkTheme: VnlfTheme.dark(),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
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
