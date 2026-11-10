import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vnlfsocialapp/src/design_system/design_system.dart';
import 'package:vnlfsocialapp/src/domain/models.dart';
import 'package:vnlfsocialapp/src/features/tags/domain/tag_articles.dart';
import 'package:vnlfsocialapp/src/features/tags/presentation/tag_providers.dart';
import 'package:vnlfsocialapp/src/features/tags/presentation/tag_screen.dart';

FeedPost _post(String id, {String? title, int likes = 0}) => FeedPost(
  id: id,
  slug: 'bai-$id',
  title: title,
  excerpt: 'Tóm tắt bài $id',
  voteScore: likes,
  commentCount: 0,
  likeCount: likes,
  author: const Author(id: 'a', username: 'tran.lan', displayName: 'Trần Lan'),
);

void main() {
  late _Tags tags;

  setUp(() => tags = _Tags());

  Future<void> pump(WidgetTester tester, String location) async {
    tester.view.physicalSize = const Size(1440, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: location,
      routes: [
        GoRoute(
          path: '/t/:slug',
          builder: (context, state) => Scaffold(
            body: TagScreen(
              slug: state.pathParameters['slug']!,
              cursor: state.uri.queryParameters['cursor'],
            ),
          ),
        ),
        for (final path in ['/a/:slug', '/discover', '/', '/search', '/login'])
          GoRoute(
            path: path,
            builder: (context, state) => Text('route ${state.uri}'),
          ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [tagArticlesRepositoryProvider.overrideWithValue(tags)],
        child: MaterialApp.router(
          theme: VnlfTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a topic lists its posts as rows and pages on', (tester) async {
    tags.pages[('linux', null)] = TagArticlesPage(
      name: 'Linux',
      total: 31,
      items: [
        _post('1', title: 'Cài Arch', likes: 4),
        _post('2'),
      ],
      nextCursor: 'trang-2',
    );
    tags.pages[('linux', 'trang-2')] = TagArticlesPage(
      name: 'Linux',
      items: [_post('3')],
    );
    await pump(tester, '/t/linux');
    expect(find.text('Chủ đề #linux'), findsOneWidget);
    expect(find.text('#Linux'), findsOneWidget);
    expect(find.text('31 bài công khai trong cộng đồng.'), findsOneWidget);
    expect(find.text('Cài Arch'), findsOneWidget);
    // A post without a title shows its excerpt; initials, never the photo.
    expect(find.text('Tóm tắt bài 2'), findsOneWidget);
    expect(find.text('Trần Lan · 4 lượt thích'), findsOneWidget);
    expect(find.text('TL'), findsNWidgets(2));
    expect(find.byType(VnlfVoteCapsule), findsNothing);

    await tester.tap(find.text('Xem bài cũ hơn'));
    await tester.pumpAndSettle();
    // The next page stands alone; without a total it counts its own rows.
    expect(find.text('1 bài công khai trong cộng đồng.'), findsOneWidget);
    expect(find.text('Tóm tắt bài 3'), findsOneWidget);
    expect(find.text('Xem bài cũ hơn'), findsNothing);

    await tester.tap(find.text('Tóm tắt bài 3'));
    await tester.pumpAndSettle();
    expect(find.text('route /a/bai-3'), findsOneWidget);
  });

  testWidgets('a tag nobody used says so and points to Khám phá', (
    tester,
  ) async {
    await pump(tester, '/t/khong-co');
    expect(find.text('#khong-co'), findsOneWidget);
    expect(
      find.textContaining('Chưa có bài nào gắn #khong-co.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Khám phá chủ đề khác'));
    await tester.pumpAndSettle();
    expect(find.text('route /discover'), findsOneWidget);
  });

  testWidgets('a malformed slug is the not-found page', (tester) async {
    await pump(tester, '/t/Khong_Hop_Le');
    expect(find.text('Không tìm thấy trang.'), findsOneWidget);
    expect(tags.requests, isEmpty);
  });

  test('slugs follow the website', () {
    expect(isTagSlug('linux'), isTrue);
    expect(isTagSlug('open-source'), isTrue);
    expect(isTagSlug('Linux'), isFalse);
    expect(isTagSlug('a--b'), isFalse);
  });
}

class _Tags implements TagArticlesRepository {
  final pages = <(String, String?), TagArticlesPage>{};
  final requests = <(String, String?)>[];

  @override
  Future<TagArticlesPage?> page(String slug, {String? cursor}) async {
    requests.add((slug, cursor));
    return pages[(slug, cursor)];
  }
}
