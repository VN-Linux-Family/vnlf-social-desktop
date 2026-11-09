import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vnlfsocialapp/main.dart';
import 'package:vnlfsocialapp/src/app/providers.dart';
import 'package:vnlfsocialapp/src/design_system/design_system.dart';
import 'package:vnlfsocialapp/src/domain/models.dart';
import 'package:vnlfsocialapp/src/domain/repositories.dart';
import 'package:vnlfsocialapp/src/features/thread/presentation/thread_sidebar.dart';

void main() {
  testWidgets('profile retries a repository failure and loads the member', (
    tester,
  ) async {
    final repository = _RecoveringFeedRepository();
    final router = await _pumpApp(
      tester,
      app: ProviderScope(
        overrides: [feedRepositoryProvider.overrideWithValue(repository)],
        child: const MainApp(),
      ),
    );
    router.go('/profile/retry');
    await tester.pumpAndSettle();
    expect(find.text('Không tải được nội dung'), findsOneWidget);
    repository.unavailable = false;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.text('Thành viên khôi phục'), findsWidgets);
    expect(find.text('Không tải được nội dung'), findsNothing);
  });

  for (final width in [390.0, 900.0, 1440.0]) {
    testWidgets('native routes fit width $width with large text', (
      tester,
    ) async {
      final router = await _pumpApp(tester, width: width, textScale: 1.6);
      for (final path in [
        '/thread/post-synth-1',
        '/profile/hoangnam',
        '/settings',
        '/discover',
      ]) {
        router.go(path);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: path);
        if (width == 1440 && path.startsWith('/thread/')) {
          expect(find.byType(ThreadSidebar), findsOneWidget);
          expect(find.text('Xem trang cá nhân'), findsOneWidget);
        }
      }
    });
  }

  testWidgets('thread opens sample content and supports a local comment', (
    tester,
  ) async {
    final router = await _pumpApp(tester);
    router.go('/thread/post-synth-1');
    await tester.pumpAndSettle();

    expect(find.text('Bài viết'), findsOneWidget);
    expect(find.text('Trải nghiệm Arch Linux và Wayland'), findsOneWidget);
    expect(find.byType(VnlfCommentTree), findsWidgets);
    expect(find.textContaining('Tiếng Việt: ặ ữ ờ ẫ ệ'), findsWidgets);
    final input = find.byKey(const ValueKey('comment-input'));
    await tester.ensureVisible(input);
    await tester.enterText(input, 'Mình đã thử trên máy ảo.');
    final send = find.widgetWithText(FilledButton, 'Thêm bình luận');
    await tester.ensureVisible(send);
    await tester.tap(send);
    await tester.pumpAndSettle();
    expect(find.text('Mình đã thử trên máy ảo.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('feed content and comments open the matching full thread', (
    tester,
  ) async {
    final router = await _pumpApp(tester);
    await tester.tap(
      find.text(
        'Vietnam Linux Family là nơi chia sẻ kiến thức. Tiếng Việt: ặ ữ ờ ẫ ệ.',
      ),
    );
    await tester.pumpAndSettle();
    expect(
      router.routerDelegate.currentConfiguration.last.matchedLocation,
      '/thread/fixture-post-1',
    );
    expect(
      find.textContaining('Vietnam Linux Family là nơi chia sẻ'),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('Quay lại'));
    await tester.pumpAndSettle();
    expect(
      router.routerDelegate.currentConfiguration.last.matchedLocation,
      '/',
    );
    await tester.tap(find.byIcon(Icons.mode_comment_outlined));
    await tester.pumpAndSettle();
    expect(
      router.routerDelegate.currentConfiguration.last.matchedLocation,
      '/thread/fixture-post-1',
    );
  });

  testWidgets('feed author opens their own profile', (tester) async {
    final router = await _pumpApp(tester);
    await tester.tap(find.text('Thành viên'));
    await tester.pumpAndSettle();
    expect(
      router.routerDelegate.currentConfiguration.last.matchedLocation,
      '/profile/thanhvien',
    );
    expect(find.text('@thanhvien'), findsWidgets);
  });

  testWidgets('profile shows identity and switches public content tabs', (
    tester,
  ) async {
    final router = await _pumpApp(tester);
    router.go('/profile/hoangnam');
    await tester.pumpAndSettle();
    expect(find.text('Hoàng Nam'), findsWidgets);
    expect(find.text('@hoangnam'), findsWidgets);
    expect(find.text('người theo dõi'), findsOneWidget);
    expect(find.text('Tổng XP'), findsOneWidget);
    expect(find.textContaining('Bài viết'), findsWidgets);
    final projects = find.descendant(
      of: find.byType(VnlfFeedTabBar),
      matching: find.textContaining('Dự án'),
    );
    await tester.ensureVisible(projects);
    await tester.tap(projects);
    await tester.pumpAndSettle();
    expect(find.text('vnlf-cli'), findsOneWidget);
    final guestbook = find.text('Sổ lưu bút');
    await tester.ensureVisible(guestbook);
    await tester.tap(guestbook);
    await tester.pumpAndSettle();
    expect(find.text('Chưa có lời nhắn'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('settings changes the application theme and language', (
    tester,
  ) async {
    final router = await _pumpApp(tester);
    router.go('/settings');
    await tester.pumpAndSettle();
    expect(find.text('Offline fixture'), findsOneWidget);
    expect(find.text('Phiên bản đang dùng: 0.1.0'), findsOneWidget);
    await tester.tap(find.text('Tối'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
    );
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsWidgets);
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).locale,
      const Locale('en'),
    );
    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.light,
    );
    await tester.tap(find.text('System'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.system,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('settings on mobile has exactly one back button', (tester) async {
    final router = await _pumpApp(tester, width: 390);
    router.go('/settings');
    await tester.pumpAndSettle();

    final backButtons = find.byWidgetPredicate(
      (widget) =>
          widget is IconButton &&
          widget.icon is Icon &&
          ((widget.icon as Icon).icon == Icons.arrow_back_rounded ||
              (widget.icon as Icon).icon == Icons.arrow_back),
    );
    expect(backButtons, findsOneWidget);
  });

  testWidgets('profile on mobile has exactly one back button', (tester) async {
    final router = await _pumpApp(tester, width: 390);
    router.go('/profile/hoangnam');
    await tester.pumpAndSettle();

    final backButtons = find.byWidgetPredicate(
      (widget) =>
          widget is IconButton &&
          widget.icon is Icon &&
          ((widget.icon as Icon).icon == Icons.arrow_back_rounded ||
              (widget.icon as Icon).icon == Icons.arrow_back),
    );
    expect(backButtons, findsOneWidget);
  });

  testWidgets('discover searches and filters articles and opens contributors', (
    tester,
  ) async {
    final router = await _pumpApp(tester);
    router.go('/discover');
    await tester.pumpAndSettle();
    expect(find.text('Bài viết nổi bật'), findsOneWidget);
    expect(find.text('Arch Linux'), findsOneWidget);
    expect(find.text('Hyprland'), findsOneWidget);
    expect(find.text('Trải nghiệm Arch Linux và Wayland'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'không có bài nào');
    await tester.pumpAndSettle();
    expect(find.text('Trải nghiệm Arch Linux và Wayland'), findsNothing);
    expect(find.text('Không có kết quả'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '');
    await tester.tap(find.text('Arch Linux'));
    await tester.pumpAndSettle();
    expect(find.text('Trải nghiệm Arch Linux và Wayland'), findsOneWidget);
    final contributor = find.text('Hoàng Nam').last;
    await tester.ensureVisible(contributor);
    await tester.pumpAndSettle();
    await tester.tap(contributor);
    await tester.pumpAndSettle();
    expect(
      router.routerDelegate.currentConfiguration.last.matchedLocation,
      '/profile/hoangnam',
    );
    expect(tester.takeException(), isNull);
  });
}

Future<GoRouter> _pumpApp(
  WidgetTester tester, {
  double width = 390,
  double textScale = 1,
  Widget app = const MainApp(),
}) async {
  tester.platformDispatcher.localesTestValue = const [Locale('vi')];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  tester.view.physicalSize = Size(width, 1100);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(app);
  await tester.pumpAndSettle();
  return tester.widget<MaterialApp>(find.byType(MaterialApp)).routerConfig!
      as GoRouter;
}

class _RecoveringFeedRepository implements FeedRepository {
  bool unavailable = true;

  @override
  Future<FeedPage> getFeed({
    String? cursor,
    String? type,
    bool refresh = false,
  }) async {
    if (unavailable) throw const TransportFailure();
    return FeedPage(
      items: const [
        FeedPost(
          id: 'retry-post',
          author: Author(
            username: 'retry',
            displayName: 'Thành viên khôi phục',
          ),
          excerpt: 'Bài viết đã tải lại',
          voteScore: 0,
          commentCount: 0,
        ),
      ],
    );
  }
}
