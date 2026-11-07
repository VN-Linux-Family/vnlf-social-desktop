import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/l10n/app_localizations.dart';
import 'package:vnlfsocialapp/main.dart';
import 'package:vnlfsocialapp/src/app/app_router.dart';
import 'package:vnlfsocialapp/src/app/providers.dart';
import 'package:vnlfsocialapp/src/design_system/design_system.dart';
import 'package:vnlfsocialapp/src/features/channels/presentation/channels_screen.dart';
import 'package:vnlfsocialapp/src/features/search/presentation/search_screen.dart';
import 'package:vnlfsocialapp/src/features/voice/presentation/voice_screen.dart';
import 'package:vnlfsocialapp/src/features/discover/presentation/discover_screen.dart';
import 'package:vnlfsocialapp/src/features/profile/presentation/profile_screen.dart';
import 'package:vnlfsocialapp/src/features/settings/presentation/settings_screen.dart';
import 'package:vnlfsocialapp/src/features/thread/presentation/thread_screen.dart';

void main() {
  testWidgets('shell adapts and navigates to the requested destinations', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final router = createMainRouter();
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(VnlfMobileBottomNav), findsOneWidget);
    await tester.tap(find.text('Discover'));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/discover');
    for (final entry in <String, Type>{
      '/thread/1': ThreadScreen,
      '/profile/1': ProfileScreen,
      '/search': SearchScreen,
      '/channels': ChannelsScreen,
      '/voice': VoiceScreen,
      '/discover': DiscoverScreen,
      '/settings': SettingsScreen,
    }.entries) {
      router.go(entry.key);
      await tester.pumpAndSettle();
      expect(find.byType(entry.value), findsOneWidget, reason: entry.key);
      expect(router.routeInformationProvider.value.uri.path, entry.key);
    }
    tester.view.physicalSize = const Size(1400, 900);
    await tester.pumpAndSettle();
    expect(find.byType(VnlfDesktopSidebar), findsOneWidget);
    expect(find.byType(VnlfMobileBottomNav), findsNothing);
  });

  testWidgets('locale override reaches the application', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const MainApp()),
    );
    await tester.pumpAndSettle();
    container.read(localeProvider.notifier).state = const Locale('en');
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(VnlfAdaptiveShell));
    expect(Localizations.localeOf(context), const Locale('en'));
    expect(find.text('Feed'), findsWidgets);
  });

  testWidgets('account switch removes an active problem notice snackbar', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const MainApp()),
    );
    await tester.pumpAndSettle();

    final authController = container.read(authControllerProvider.notifier);
    await authController.login('testuser', 'password');
    await tester.pumpAndSettle();

    final messenger = tester.state<ScaffoldMessengerState>(
      find.byType(ScaffoldMessenger),
    );
    messenger.showSnackBar(const SnackBar(content: Text('Notice problem')));
    await tester.pump();
    expect(find.text('Notice problem'), findsOneWidget);

    await authController.logout();
    await tester.pump();
    expect(find.text('Notice problem'), findsNothing);
  });

  testWidgets(
    'mobile bottom nav and desktop sidebar show unread badge for messages',
    (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VnlfMobileBottomNav(
              activeDestination: VnlfNavDestination.feed,
              unreadDestinations: {VnlfNavDestination.messages},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).color == const Color(0xFFD7473E),
        ),
        findsOneWidget,
      );

      tester.view.physicalSize = const Size(1200, 800);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VnlfDesktopSidebar(
              activeDestination: VnlfNavDestination.feed,
              unreadDestinations: {VnlfNavDestination.messages},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).color == const Color(0xFFD7473E),
        ),
        findsOneWidget,
      );
    },
  );
}
