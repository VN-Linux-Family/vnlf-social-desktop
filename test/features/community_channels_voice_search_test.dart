import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vnlfsocialapp/l10n/app_localizations.dart';
import 'package:vnlfsocialapp/src/app/app_router.dart';
import 'package:vnlfsocialapp/src/design_system/design_system.dart';
import 'package:vnlfsocialapp/src/domain/models.dart';
import 'package:vnlfsocialapp/src/features/projects/presentation/projects_screen.dart';

void main() {
  testWidgets('desktop feed search button opens global search', (tester) async {
    final router = await _pump(tester, '/', width: 1440);
    await tester.tap(find.byTooltip('Tìm kiếm'));
    await tester.pumpAndSettle();
    expect(router.routerDelegate.state.matchedLocation, '/search');
    expect(find.byKey(const Key('search-input')), findsOneWidget);
  });

  testWidgets('channel switch isolates messages and retains local sends', (
    tester,
  ) async {
    await _pump(tester, '/channels');
    await tester.tap(find.byTooltip('Chọn kênh'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('#hoi-dap-linux'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('chat-input')),
      'Tiếng Việt: ặ ữ ờ ẫ ệ',
    );
    await tester.pump();
    await tester.tap(find.byTooltip('Gửi tin nhắn'));
    await tester.pumpAndSettle();
    expect(find.text('Tiếng Việt: ặ ữ ờ ẫ ệ'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('chat-input')))
          .controller!
          .text,
      isEmpty,
    );
    await tester.tap(find.byTooltip('Chọn kênh'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('#chung'));
    await tester.pumpAndSettle();
    expect(find.text('Tiếng Việt: ặ ữ ờ ẫ ệ'), findsNothing);
    await tester.tap(find.byTooltip('Chọn kênh'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('#hoi-dap-linux'));
    await tester.pumpAndSettle();
    expect(find.text('Tiếng Việt: ặ ữ ờ ẫ ệ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('voice join enables mute, deafen, share and leave controls', (
    tester,
  ) async {
    await _pump(tester, '/voice');
    expect(
      tester
          .widget<IconButton>(
            find
                .ancestor(
                  of: find.byTooltip('Bật mic'),
                  matching: find.byType(IconButton),
                )
                .first,
          )
          .onPressed,
      isNull,
    );
    await tester.tap(find.text('Tham gia phòng'));
    await tester.pumpAndSettle();
    expect(find.text('Rời phòng'), findsOneWidget);
    expect(find.text('Bạn'), findsOneWidget);
    await tester.tap(find.byTooltip('Bật mic'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Tắt mic'), findsOneWidget);
    await tester.tap(find.byTooltip('Tắt âm thanh'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Bật âm thanh'), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(
            find
                .ancestor(
                  of: find.byTooltip('Bật mic'),
                  matching: find.byType(IconButton),
                )
                .first,
          )
          .onPressed,
      isNull,
    );
    await tester.tap(find.byTooltip('Bật âm thanh'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Chia sẻ màn hình'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Dừng chia sẻ'), findsOneWidget);
    await tester.tap(find.text('Rời phòng'));
    await tester.pumpAndSettle();
    expect(find.text('Bạn'), findsNothing);
    expect(find.text('Tham gia phòng'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'search query, scope, popular tags and clear filter real results',
    (tester) async {
      await _pump(tester, '/search');
      await tester.enterText(
        find.byKey(const Key('search-input')),
        '  VNLF-CLI  ',
      );
      await tester.pumpAndSettle();
      expect(find.text('vnlf-cli'), findsOneWidget);
      await tester.tap(find.widgetWithText(ChoiceChip, 'Bài viết'));
      await tester.pumpAndSettle();
      expect(find.text('vnlf-cli'), findsNothing);
      expect(find.text('Không tìm thấy kết quả'), findsOneWidget);
      await tester.tap(find.byTooltip('Xóa tìm kiếm'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ActionChip, 'Wayland'));
      await tester.pumpAndSettle();
      expect(find.text('Trải nghiệm Arch Linux và Wayland'), findsOneWidget);
      await tester.tap(find.widgetWithText(ChoiceChip, 'Thành viên'));
      await tester.enterText(find.byKey(const Key('search-input')), 'hoangnam');
      await tester.pumpAndSettle();
      expect(find.text('Hoàng Nam'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('feed vote and bookmark survive a visit to thread and back', (
    tester,
  ) async {
    final router = await _pump(tester, '/');
    PostData post() =>
        tester.widget<VnlfPostCard>(find.byType(VnlfPostCard)).post!;
    expect(post().voteScore, 3);
    await tester.tap(find.bySemanticsLabel('Ủng hộ'));
    await tester.pumpAndSettle();
    expect(post().voteScore, 2);
    expect(post().viewerVote, VoteState.neutral);
    await tester.tap(find.bySemanticsLabel('Phản đối'));
    await tester.pumpAndSettle();
    expect(post().voteScore, 1);
    await tester.tap(find.bySemanticsLabel('Ủng hộ'));
    await tester.pumpAndSettle();
    expect(post().voteScore, 3);
    await tester.tap(find.bySemanticsLabel('Lưu bài viết'));
    await tester.pumpAndSettle();
    expect(post().isBookmarked, isTrue);
    router.go('/thread/fixture-post-1');
    await tester.pumpAndSettle();
    expect(post().voteScore, 3);
    expect(post().isBookmarked, isTrue);
    await tester.tap(find.bySemanticsLabel('Phản đối'));
    await tester.pumpAndSettle();
    expect(post().voteScore, 1);
    router.go('/');
    await tester.pumpAndSettle();
    expect(post().voteScore, 1);
    expect(post().isBookmarked, isTrue);
  });

  testWidgets(
    'project language filter excludes other languages and can reset',
    (tester) async {
      await _pump(
        tester,
        '/projects',
        overrides: [
          projectsProvider.overrideWith(
            (ref) async => ProjectsPage(
              items: const [
                ProjectItem(
                  id: 'dart',
                  name: 'Dart Tool',
                  repo: {'language': 'Dart'},
                ),
                ProjectItem(
                  id: 'rust',
                  name: 'Rust Tool',
                  repo: {'language': 'Rust'},
                ),
              ],
            ),
          ),
        ],
      );
      expect(find.byType(VnlfProjectPreviewCard), findsNWidgets(2));
      await tester.tap(find.widgetWithText(ChoiceChip, 'Rust'));
      await tester.pumpAndSettle();
      expect(find.text('Rust Tool'), findsOneWidget);
      expect(find.text('Dart Tool'), findsNothing);
      await tester.tap(find.widgetWithText(ChoiceChip, 'Python'));
      await tester.pumpAndSettle();
      expect(find.text('Không có dự án phù hợp'), findsOneWidget);
      await tester.tap(find.widgetWithText(ChoiceChip, 'Tất cả'));
      await tester.pumpAndSettle();
      expect(find.byType(VnlfProjectPreviewCard), findsNWidgets(2));
    },
  );

  testWidgets('leaderboard periods change points and ranking order', (
    tester,
  ) async {
    await _pump(tester, '/leaderboard');
    expect(find.text('450'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Tháng này'));
    await tester.pumpAndSettle();
    expect(find.text('1280'), findsOneWidget);
    expect(find.text('450'), findsNothing);
    expect(
      tester
          .widget<VnlfLeaderboardCard>(find.byType(VnlfLeaderboardCard))
          .entries
          .first
          .author
          .username,
      'minhtri',
    );
    await tester.tap(find.widgetWithText(ChoiceChip, 'Tất cả'));
    await tester.pumpAndSettle();
    expect(find.text('8640'), findsOneWidget);
    expect(
      tester
          .widget<VnlfLeaderboardCard>(find.byType(VnlfLeaderboardCard))
          .entries
          .first
          .author
          .username,
      'hoangnam',
    );
    await tester.tap(find.widgetWithText(ChoiceChip, 'Tuần này'));
    await tester.pumpAndSettle();
    expect(find.text('450'), findsOneWidget);
  });

  for (final width in [390.0, 900.0, 1440.0]) {
    for (final route in ['/channels', '/voice', '/search']) {
      testWidgets('$route fits width $width with scaled text', (tester) async {
        await _pump(tester, route, width: width, scale: 1.3);
        expect(find.text('Màn hình này chưa có nội dung.'), findsNothing);
        expect(tester.takeException(), isNull);
        if (route == '/channels' && width == 1440) {
          expect(find.text('Đang hoạt động'), findsOneWidget);
        }
      });
    }
  }
}

Future<GoRouter> _pump(
  WidgetTester tester,
  String route, {
  double width = 390,
  double scale = 1,
  List<Override> overrides = const [],
}) async {
  tester.view.physicalSize = Size(width, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final router = createMainRouter()..go(route);
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp.router(
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: VnlfTheme.light(),
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}
