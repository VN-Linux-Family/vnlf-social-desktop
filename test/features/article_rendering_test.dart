import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/data/feed_dto.dart';
import 'package:vnlfsocialapp/src/design_system/design_system.dart';
import 'package:vnlfsocialapp/src/domain/models.dart';
import 'package:vnlfsocialapp/src/features/feed/presentation/post_mapper.dart';

const document = <String, dynamic>{
  'type': 'doc',
  'content': [
    {
      'type': 'heading',
      'attrs': {'level': 2},
      'content': [
        {'type': 'text', 'text': 'Tiếng Việt: ặ ữ ờ ẫ ệ'},
      ],
    },
    {
      'type': 'paragraph',
      'content': [
        {
          'type': 'text',
          'text': 'Đậm',
          'marks': [
            {'type': 'bold'},
          ],
        },
        {'type': 'hardBreak'},
        {'type': 'text', 'text': 'Sau ngắt dòng'},
      ],
    },
    {
      'type': 'bulletList',
      'content': [
        {
          'type': 'listItem',
          'content': [
            {
              'type': 'paragraph',
              'content': [
                {'type': 'text', 'text': 'Mục danh sách'},
              ],
            },
          ],
        },
      ],
    },
    {
      'type': 'codeBlock',
      'content': [
        {'type': 'text', 'text': 'printf("hello");'},
      ],
    },
  ],
};

FeedPost postWith({List<ArticleAttachment> media = const []}) => FeedPost(
  id: 'render-test',
  author: const Author(username: 'synthetic', displayName: 'Thành viên thử'),
  excerpt: 'Tóm tắt không thay thế nội dung',
  contentJson: document,
  voteScore: 0,
  commentCount: 0,
  attachments: media,
);

void main() {
  test('inline image asset ids resolve against the server asset catalog', () {
    final post = FeedPostDto.fromJson({
      'id': 'inline-image',
      'contentJson': {
        'type': 'doc',
        'content': [
          {
            'type': 'image',
            'attrs': {'assetId': 'asset-1', 'alt': 'Ảnh nội dung'},
          },
        ],
      },
      'assets': [
        {'id': 'asset-1', 'url': 'https://example.invalid/inline.webp'},
      ],
    }).toDomain();
    final nodes = post.contentJson!['content'] as List;
    expect(
      (nodes.single as Map)['attrs']['src'],
      'https://example.invalid/inline.webp',
    );
  });

  testWidgets('post renders structured headings lists line breaks and code', (
    tester,
  ) async {
    await pumpPost(tester, postWith());
    expect(
      find.text('Tiếng Việt: ặ ữ ờ ẫ ệ', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.textContaining('Đậm\nSau ngắt dòng', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('Mục danh sách', findRichText: true), findsOneWidget);
    expect(find.byType(VnlfCodeBlock), findsOneWidget);
    final spans = <InlineSpan>[];
    for (final text in tester.widgetList<RichText>(find.byType(RichText))) {
      text.text.visitChildren((span) {
        spans.add(span);
        return true;
      });
    }
    expect(
      spans.whereType<TextSpan>().any(
        (span) =>
            span.text == 'Đậm' && span.style?.fontWeight == FontWeight.w700,
      ),
      isTrue,
    );
  });

  testWidgets('every attached image is shown and opens a zoomable viewer', (
    tester,
  ) async {
    await pumpPost(
      tester,
      postWith(
        media: const [
          ArticleAttachment(
            id: 'one',
            url: 'https://example.invalid/one.webp',
            mime: 'image/webp',
            alt: 'Ảnh một',
          ),
          ArticleAttachment(
            id: 'two',
            url: 'https://example.invalid/two.webp',
            mime: 'image/webp',
            alt: 'Ảnh hai',
          ),
        ],
      ),
    );
    expect(find.byType(Image), findsNWidgets(2));
    await tester.ensureVisible(find.byType(Image).first);
    await tester.tap(find.byType(Image).first);
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsWidgets);
  });

  testWidgets('video attachments offer playback instead of loading an image', (
    tester,
  ) async {
    await pumpPost(
      tester,
      postWith(
        media: const [
          ArticleAttachment(
            id: 'video',
            url: 'https://example.invalid/video.mp4',
            mime: 'video/mp4',
            alt: 'Video thử',
          ),
        ],
      ),
    );
    expect(find.byIcon(Icons.play_circle_fill_rounded), findsOneWidget);
    expect(
      tester
          .widgetList<Image>(find.byType(Image))
          .where(
            (i) =>
                i.image is NetworkImage &&
                (i.image as NetworkImage).url.endsWith('.mp4'),
          ),
      isEmpty,
    );
  });
}

Future<void> pumpPost(WidgetTester tester, FeedPost post) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: VnlfTheme.light(),
      home: Scaffold(
        body: SingleChildScrollView(
          child: VnlfPostCard(post: presentPost(post, english: false)),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
