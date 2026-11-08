import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vnlfsocialapp/main.dart';

import '../tool/ux_audit_fixtures.dart';

void main() {
  Future<GoRouter> open(WidgetTester tester, String path) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.localesTestValue = const [Locale('vi')];
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(
      ProviderScope(overrides: auditOverrides(), child: const MainApp()),
    );
    await tester.pumpAndSettle();
    final router =
        tester.widget<MaterialApp>(find.byType(MaterialApp)).routerConfig!
            as GoRouter;
    router.go(path);
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('desktop post has one working back control', (tester) async {
    final router = await open(tester, '/thread/post-synth-1');
    final arrows = find.byWidgetPredicate(
      (widget) =>
          widget is Icon &&
          (widget.icon == Icons.arrow_back ||
              widget.icon == Icons.arrow_back_rounded),
    );
    expect(arrows, findsOneWidget);
    await tester.tap(arrows);
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/');
  });

  testWidgets(
    'project without optional metadata has no empty information section',
    (tester) async {
      await open(tester, '/projects/vnlf-cli');
      expect(find.text('vnlf-cli'), findsOneWidget);
      expect(find.text('Thông tin'), findsNothing);
      expect(find.text('@banlinux'), findsOneWidget);
      expect(find.text('@banlinux · '), findsNothing);
    },
  );
}
