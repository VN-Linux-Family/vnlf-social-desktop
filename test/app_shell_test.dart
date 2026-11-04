import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/l10n/app_localizations.dart';
import 'package:vnlfsocialapp/main.dart';
import 'package:vnlfsocialapp/src/app/app_router.dart';
import 'package:vnlfsocialapp/src/app/providers.dart';
import 'package:vnlfsocialapp/src/design_system/design_system.dart';

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
    for (final path in [
      '/thread/1',
      '/profile/1',
      '/search',
      '/channels',
      '/discover',
      '/settings',
    ]) {
      router.go(path);
      await tester.pumpAndSettle();
      expect(find.byType(VnlfStateCard), findsOneWidget, reason: path);
      expect(router.routeInformationProvider.value.uri.path, path);
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
}
