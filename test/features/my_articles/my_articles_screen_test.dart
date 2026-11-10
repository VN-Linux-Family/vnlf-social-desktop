import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vnlfsocialapp/src/app/providers.dart';
import 'package:vnlfsocialapp/src/design_system/design_system.dart';
import 'package:vnlfsocialapp/src/domain/models.dart';
import 'package:vnlfsocialapp/src/features/my_articles/domain/my_articles.dart';
import 'package:vnlfsocialapp/src/features/my_articles/presentation/my_articles_providers.dart';
import 'package:vnlfsocialapp/src/features/my_articles/presentation/my_articles_screen.dart';
import 'package:vnlfsocialapp/src/features/shared/domain/post_actions.dart';
import 'package:vnlfsocialapp/src/features/shared/presentation/post_interactions.dart';

FeedPost _post(String id, String status, {String title = ''}) => FeedPost(
  id: id,
  slug: 'bai-$id',
  title: title.isEmpty ? null : title,
  excerpt: 'Tóm tắt $id',
  voteScore: 0,
  commentCount: 0,
  status: status,
  updatedAt: DateTime.utc(2026, 11, 8, 15, 4, 5),
  author: const Author(id: 'me', username: 'toi', displayName: 'Tôi'),
);

void main() {
  late _Articles articles;
  late _Actions actions;

  setUp(() {
    articles = _Articles();
    actions = _Actions(articles);
  });

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: '/my/articles',
      routes: [
        GoRoute(
          path: '/my/articles',
          builder: (context, state) => const Scaffold(body: MyArticlesScreen()),
        ),
        for (final path in [
          '/compose',
          '/compose/:id',
          '/a/:slug',
          '/profile/:id',
        ])
          GoRoute(
            path: path,
            builder: (context, state) => Text('route ${state.uri}'),
          ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionStateProvider.overrideWith(
            (ref) => const Session(
              userId: 'me',
              displayName: 'Tôi',
              username: 'toi',
            ),
          ),
          myArticlesRepositoryProvider.overrideWithValue(articles),
          postActionsRepositoryProvider.overrideWithValue(actions),
        ],
        child: MaterialApp.router(
          theme: VnlfTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('drafts come first, with counts for every tab', (tester) async {
    articles.items = [
      _post('d1', 'DRAFT', title: 'Nháp về Wayland'),
      _post('p1', 'PUBLISHED', title: 'Cài CachyOS'),
      _post('p2', 'PUBLISHED'),
      _post('x1', 'REMOVED'),
      _post('a1', 'ARCHIVED', title: 'Bài cũ'),
    ];
    await pump(tester);
    expect(find.text('Nháp (1)'), findsOneWidget);
    expect(find.text('Đã đăng (2)'), findsOneWidget);
    expect(find.text('Lưu trữ (1)'), findsOneWidget);
    expect(find.text('Nháp về Wayland'), findsOneWidget);
    expect(find.text('Cài CachyOS'), findsNothing);

    await tester.tap(find.text('Đã đăng (2)'));
    await tester.pumpAndSettle();
    expect(find.text('Cài CachyOS'), findsOneWidget);
    expect(find.text('Lưu trữ'), findsNWidgets(2));
  });

  testWidgets('archiving asks first, then moves the post', (tester) async {
    articles.items = [_post('p1', 'PUBLISHED', title: 'Cài CachyOS')];
    await pump(tester);
    await tester.tap(find.text('Đã đăng (1)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lưu trữ').last);
    await tester.pumpAndSettle();
    expect(find.text('Lưu trữ bài này?'), findsOneWidget);
    await tester.tap(find.text('Lưu trữ').last);
    await tester.pumpAndSettle();
    expect(articles.log, ['archive p1']);
    expect(find.text('Đã lưu trữ bài'), findsOneWidget);
    expect(find.text('Đã đăng (0)'), findsOneWidget);
    expect(find.text('Lưu trữ (1)'), findsOneWidget);
    // Let the toast close.
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('a draft is deleted after its own question', (tester) async {
    articles.items = [_post('d1', 'DRAFT', title: 'Nháp về Wayland')];
    await pump(tester);
    await tester.tap(find.text('Xóa'));
    await tester.pumpAndSettle();
    expect(find.text('Xóa bản nháp này?'), findsOneWidget);
    expect(find.textContaining('“Nháp về Wayland”'), findsOneWidget);
    await tester.tap(find.text('Xóa').last);
    await tester.pumpAndSettle();
    expect(actions.deleted, ['d1']);
    expect(find.text('Đã xóa bản nháp'), findsOneWidget);
    expect(find.text('Mục này chưa có bài nào'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('editing opens the composer on the post', (tester) async {
    articles.items = [_post('d1', 'DRAFT')];
    await pump(tester);
    await tester.tap(find.text('Sửa'));
    await tester.pumpAndSettle();
    expect(find.text('route /compose/d1'), findsOneWidget);
  });
}

class _Articles implements MyArticlesRepository {
  List<FeedPost> items = [];
  final log = <String>[];

  @override
  Future<List<FeedPost>> drafts() async => [
    for (final item in items)
      if (item.status == 'DRAFT') item,
  ];

  @override
  Future<List<FeedPost>> all() async => items;

  FeedPost _with(FeedPost post, String status) =>
      _post(post.id, status, title: post.title ?? '');

  @override
  Future<void> archive(String id) async {
    log.add('archive $id');
    items = [
      for (final item in items) item.id == id ? _with(item, 'ARCHIVED') : item,
    ];
  }

  @override
  Future<void> restore(String id) async {
    log.add('restore $id');
    items = [
      for (final item in items) item.id == id ? _with(item, 'PUBLISHED') : item,
    ];
  }
}

class _Actions implements PostActionsRepository {
  _Actions(this.articles);

  final _Articles articles;
  final deleted = <String>[];

  @override
  Future<void> deletePost(String id) async {
    deleted.add(id);
    articles.items = [
      for (final item in articles.items)
        if (item.id != id) item,
    ];
  }

  @override
  Future<int> setVote(String id, int value) async => value;

  @override
  Future<void> setBookmark(String id, {required bool saved}) async {}

  @override
  Future<void> hidePost(String id) async {}
}
