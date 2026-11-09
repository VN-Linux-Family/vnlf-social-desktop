import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/design_system/design_system.dart';
import 'package:vnlfsocialapp/src/domain/models.dart';
import 'package:vnlfsocialapp/src/features/feed/presentation/post_mapper.dart';
import 'package:vnlfsocialapp/src/features/thread/presentation/article_detail_card.dart';

const article = FeedPost(
  id: 'synthetic-article',
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
void main() {
  testWidgets('article title, excerpt and author precede the native document', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: VnlfTheme.light(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: ArticleDetailCard(
              source: article,
              post: presentPost(article, english: true, fullContent: true),
            ),
          ),
        ),
      ),
    );
    expect(find.text('2 min read'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Bài viết có tiêu đề')).dy,
      lessThan(tester.getTopLeft(find.text('Thành viên thử')).dy),
    );
    expect(
      tester.getTopLeft(find.text('Mô tả bài viết')).dy,
      lessThan(tester.getTopLeft(find.text('Thành viên thử')).dy),
    );
    expect(
      tester.getTopLeft(find.text('Thành viên thử')).dy,
      lessThan(
        tester
            .getTopLeft(find.text('Nội dung bài viết', findRichText: true))
            .dy,
      ),
    );
  });
  testWidgets(
    'article controls invoke their real callbacks and honor pending state',
    (tester) async {
      var saves = 0;
      var shares = 0;
      var reports = 0;
      Future<void> pump({bool pending = false}) => tester.pumpWidget(
        MaterialApp(
          theme: VnlfTheme.light(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: ArticleDetailCard(
                source: article,
                post: presentPost(article, english: true, fullContent: true)
                    .copyWith(
                      actionPending: pending,
                      actionError: pending ? 'Synthetic save error' : null,
                    ),
                onBookmark: () => saves++,
                onShare: () => shares++,
                onReport: () => reports++,
              ),
            ),
          ),
        ),
      );
      await pump();
      await tester.tap(find.text('Save'));
      await tester.tap(find.text('Share'));
      await tester.tap(find.text('Report'));
      expect([saves, shares, reports], [1, 1, 1]);
      await pump(pending: true);
      await tester.tap(find.text('Save'));
      expect(saves, 1);
      expect(find.text('Synthetic save error'), findsOneWidget);
    },
  );
}
