import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vnlfsocialapp/src/app/app_router.dart';
import 'package:vnlfsocialapp/src/app/providers.dart';
import 'package:vnlfsocialapp/src/core/api_client.dart';
import 'package:vnlfsocialapp/src/design_system/design_system.dart';
import 'package:vnlfsocialapp/src/features/projects/presentation/project_card.dart';

void main() {
  for (final width in [390.0, 900.0, 1440.0]) {
    testWidgets('fixture feed renders at width $width', (tester) async {
      final router = await _pumpApp(tester, width: width);
      expect(
        find.text(
          'Vietnam Linux Family là nơi chia sẻ kiến thức. Tiếng Việt: ặ ữ ờ ẫ ệ.',
        ),
        findsOneWidget,
      );
      expect(find.text('Thành viên'), findsOneWidget);
      expect(find.text('Mới nhất'), findsOneWidget);
      expect(find.text('Được chú ý'), findsOneWidget);
      expect(find.text('Article'), findsOneWidget);
      expect(find.byType(RefreshIndicator), findsOneWidget);
      final post = tester.widget<VnlfPostCard>(find.byType(VnlfPostCard));
      expect(post.post!.author.style.distroBadge, DistroBadgeType.arch);
      expect(post.post!.author.style.frame, AvatarFrameType.ring);
      expect(post.post!.author.style.frameColor, const Color(0xff2563eb));
      expect(post.post!.author.style.nameplateId, 'np-default');
      expect(
        post.post!.author.avatarUrl,
        'https://vietnamlinuxfamily.net/assets/avatars/default.png',
      );
      expect(post.post!.author.loadNetworkAvatar, isFalse);
      if (width == 1440) {
        expect(find.text('Hoàng Nam'), findsOneWidget);
        expect(find.text('450'), findsOneWidget);
        await tester.tap(find.text('Xem tất cả'));
        await tester.pumpAndSettle();
        expect(router.routeInformationProvider.value.uri.path, '/leaderboard');
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('leaderboard route renders fixture rankings', (tester) async {
    final router = await _pumpApp(tester);
    router.go('/leaderboard');
    await tester.pumpAndSettle();
    expect(find.byType(VnlfLeaderboardCard), findsOneWidget);
    expect(find.text('Hoàng Nam'), findsOneWidget);
    expect(find.text('Minh Trí'), findsOneWidget);
    expect(find.text('Linh Đan'), findsOneWidget);
    expect(find.text('450'), findsOneWidget);
    expect(find.text('320'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('projects route renders fixture project and repo stats', (
    tester,
  ) async {
    final router = await _pumpApp(tester);
    // As on the website, Projects is reached from the menu behind the avatar.
    await tester.tap(
      find.descendant(
        of: find.byType(VnlfMobileBottomNav),
        matching: find.byTooltip('Mở menu'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: find.byType(Drawer), matching: find.text('Dự án')),
    );
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/projects');
    expect(find.byType(ProjectCard), findsOneWidget);
    expect(find.text('vnlf-cli'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(ProjectCard),
        matching: find.text('Dart'),
      ),
      findsOneWidget,
    );
    expect(find.text('128'), findsOneWidget);
    expect(find.text('24'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('default offline transport settles multiple feature requests', (
    tester,
  ) async {
    await _pumpApp(tester, width: 1440, useFileFixtures: false);
    expect(
      find.text(
        'Vietnam Linux Family là nơi chia sẻ kiến thức. Tiếng Việt: ặ ữ ờ ẫ ệ.',
      ),
      findsOneWidget,
    );
    expect(find.byType(VnlfPostCardSkeleton), findsNothing);
    expect(find.byType(VnlfLeaderboardCardSkeleton), findsNothing);
  });
}

Future<GoRouter> _pumpApp(
  WidgetTester tester, {
  double width = 390,
  bool useFileFixtures = true,
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final fixtures = <String, String>{};
  for (final name in ['feed', 'leaderboards', 'projects']) {
    fixtures['/api/v1/$name'] = File('test/fixtures/$name.json')
        .readAsStringSync();
  }
  final container = ProviderContainer(
    overrides: [
      if (useFileFixtures)
        apiClientProvider.overrideWithValue(
          ApiClient(
            throttleInterval: Duration.zero,
            hostKey: Object(),
            transport: (request) async => ApiResponse(
              statusCode: 200,
              body: fixtures[request.path] ?? jsonEncode({'items': <Object>[]}),
            ),
          ),
        ),
    ],
  );
  final router = createMainRouter();
  addTearDown(router.dispose);
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        locale: const Locale('vi'),
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: const [Locale('vi')],
        theme: VnlfTheme.light(),
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}
