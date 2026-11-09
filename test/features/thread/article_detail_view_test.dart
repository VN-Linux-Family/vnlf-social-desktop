import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vnlfsocialapp/src/app/providers.dart';
import 'package:vnlfsocialapp/src/design_system/design_system.dart';
import 'package:vnlfsocialapp/src/domain/models.dart';
import 'package:vnlfsocialapp/src/features/feed/presentation/post_mapper.dart';
import 'package:vnlfsocialapp/src/features/shared/domain/post_actions.dart';
import 'package:vnlfsocialapp/src/features/shared/presentation/post_interactions.dart';
import 'package:vnlfsocialapp/src/features/thread/presentation/article_detail_view.dart';
import 'package:vnlfsocialapp/src/features/thread/presentation/post_detail_view.dart';

const article = FeedPost(
  id: 'synthetic-article',
  slug: 'bai-viet-co-tieu-de',
  author: Author(
    id: 'author',
    username: 'synthetic',
    displayName: 'Thành viên thử',
  ),
  title: 'Bài viết có tiêu đề',
  excerpt: 'Mô tả bài viết',
  format: 'ARTICLE',
  contentText: 'Nội dung bài viết',
  contentJson: {
    'type': 'doc',
    'content': [
      {
        'type': 'paragraph',
        'content': [
          {'type': 'text', 'text': 'Nội dung bài viết'},
        ],
      },
    ],
  },
  voteScore: 3,
  commentCount: 2,
);

final post = FeedPost(
  id: 'synthetic-post',
  slug: 'bai-thuong',
  author: article.author,
  excerpt: '',
  format: 'POST',
  contentText: 'Một bài ngắn',
  voteScore: 1,
  commentCount: 0,
  viewCount: 1234,
);

const reader = Session(
  userId: 'reader',
  displayName: 'Bạn đọc',
  role: 'MEMBER',
);
const owner = Session(
  userId: 'author',
  displayName: 'Thành viên thử',
  role: 'MEMBER',
);

Future<RecordingActions> _pump(
  WidgetTester tester,
  FeedPost source, {
  Session? session = reader,
  double width = 1280,
}) async {
  tester.view.physicalSize = Size(width, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final actions = RecordingActions();
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, _) => const Scaffold(body: Text('Bảng tin thử')),
      ),
      GoRoute(
        path: '/detail',
        builder: (context, _) => Scaffold(
          body: Consumer(
            builder: (context, ref, _) {
              final detail = ref
                  .watch(postInteractionProvider(source.id))
                  .apply(presentPost(source, fullContent: true));
              return SingleChildScrollView(
                child: source.format == 'ARTICLE'
                    ? ArticleDetailView(
                        post: source,
                        detail: detail,
                        onComment: () {},
                        comments: const SizedBox.shrink(),
                      )
                    : PostDetailView(
                        post: source,
                        detail: detail,
                        onComment: () {},
                        comments: const SizedBox.shrink(),
                      ),
              );
            },
          ),
        ),
      ),
    ],
    initialLocation: '/detail',
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sessionStateProvider.overrideWith((ref) => session),
        postActionsRepositoryProvider.overrideWithValue(actions),
      ],
      child: MaterialApp.router(theme: VnlfTheme.light(), routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return actions;
}

void main() {
  testWidgets('article title, excerpt and author precede the native document', (
    tester,
  ) async {
    await _pump(tester, article);
    expect(find.text('Article'), findsOneWidget);
    expect(find.text('2 phút đọc'), findsOneWidget);
    double top(Finder finder) => tester.getTopLeft(finder).dy;
    final author = find.text('Thành viên thử');
    expect(top(find.text('Bài viết có tiêu đề')), lessThan(top(author)));
    expect(top(find.text('Mô tả bài viết')), lessThan(top(author)));
    expect(
      top(author),
      lessThan(top(find.text('Nội dung bài viết', findRichText: true))),
    );
  });

  testWidgets('saving, sharing and reporting use the website flows', (
    tester,
  ) async {
    final actions = await _pump(tester, article);
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();
    expect(actions.bookmarks, [true]);
    expect(find.text('Đã lưu'), findsOneWidget);

    await tester.tap(find.text('Chia sẻ'));
    await tester.pumpAndSettle();
    expect(find.text('Chia sẻ bài này'), findsOneWidget);
    expect(find.text('Telegram'), findsOneWidget);
    expect(
      find.text('vietnamlinuxfamily.net/a/bai-viet-co-tieu-de'),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('Đóng hộp thoại'));
    await tester.pumpAndSettle();

    expect(find.text('Báo cáo'), findsOneWidget);
  });

  testWidgets('the author sees edit and delete, never report or hide', (
    tester,
  ) async {
    final actions = await _pump(tester, article, session: owner);
    expect(find.text('Báo cáo'), findsNothing);
    await tester.tap(find.bySemanticsLabel('Mở menu bài'));
    await tester.pumpAndSettle();
    expect(find.text('Sửa bài'), findsOneWidget);
    expect(find.text('Ẩn bài'), findsNothing);

    await tester.tap(find.text('Xóa bài'));
    await tester.pumpAndSettle();
    expect(find.text('Xóa bài này?'), findsOneWidget);
    expect(
      find.textContaining('“Bài viết có tiêu đề” sẽ biến mất'),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Xóa'));
    await tester.pumpAndSettle();
    expect(actions.deleted, ['synthetic-article']);
    expect(find.text('Bảng tin thử'), findsOneWidget);
    expect(find.text('Đã xóa bài'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('a reader can hide the post from the menu', (tester) async {
    final actions = await _pump(tester, post);
    await tester.tap(find.bySemanticsLabel('Mở menu bài'));
    await tester.pumpAndSettle();
    expect(find.text('Sửa bài'), findsNothing);
    await tester.tap(find.text('Ẩn bài'));
    await tester.pumpAndSettle();
    expect(actions.hidden, ['synthetic-post']);
  });

  testWidgets('a post shows its header and the author sees views', (
    tester,
  ) async {
    await _pump(tester, post, session: owner);
    expect(find.text('Quay lại bảng tin'), findsOneWidget);
    expect(find.text('Bài viết'), findsOneWidget);
    expect(find.text('1.234 lượt xem'), findsOneWidget);
    expect(find.text('Một bài ngắn', findRichText: true), findsOneWidget);
  });

  testWidgets('phones show the post without the header title', (tester) async {
    await _pump(tester, post, width: 390);
    expect(find.text('Bài viết'), findsNothing);
    expect(find.text('Quay lại bảng tin'), findsNothing);
    expect(find.bySemanticsLabel('Quay lại bảng tin'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class RecordingActions implements PostActionsRepository {
  final bookmarks = <bool>[];
  final deleted = <String>[];
  final hidden = <String>[];

  @override
  Future<int> setVote(String id, int value) async => value;

  @override
  Future<void> setBookmark(String id, {required bool saved}) async =>
      bookmarks.add(saved);

  @override
  Future<void> deletePost(String id) async => deleted.add(id);

  @override
  Future<void> hidePost(String id) async => hidden.add(id);
}
