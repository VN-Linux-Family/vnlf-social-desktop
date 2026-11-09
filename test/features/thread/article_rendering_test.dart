import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/data/feed_dto.dart';
import 'package:vnlfsocialapp/src/design_system/design_system.dart';
import 'package:vnlfsocialapp/src/design_system/components/vnlf_media_gallery.dart';
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

  test('empty asset id preserves image URL and catalog dimensions survive', () {
    final post = FeedPostDto.fromJson({
      'id': 'assets',
      'contentJson': {
        'type': 'doc',
        'content': [
          {
            'type': 'image',
            'attrs': {
              'assetId': '',
              'src': 'https://example.invalid/kept.webp',
            },
          },
          {
            'type': 'image',
            'attrs': {'assetId': 'portrait'},
          },
        ],
      },
      'assets': [
        {
          'id': 'portrait',
          'url': 'https://example.invalid/portrait.webp',
          'width': 600,
          'height': 1200,
        },
      ],
    }).toDomain();
    final nodes = post.contentJson!['content'] as List;
    expect(nodes[0]['attrs']['src'], 'https://example.invalid/kept.webp');
    expect(nodes[1]['attrs']['width'], 600);
    expect(nodes[1]['attrs']['height'], 1200);
  });

  testWidgets(
    'processing video has a state message without a dead play action',
    (tester) async {
      final post = FeedPostDto.fromJson({
        'id': 'processing',
        'attachments': [
          {
            'id': 'video',
            'mime': 'video/mp4',
            'url': null,
            'state': 'PROCESSING',
          },
        ],
      }).toDomain();
      await pumpPost(tester, post);
      expect(find.text('Video đang được xử lý'), findsOneWidget);
      expect(find.byIcon(Icons.play_circle_fill_rounded), findsNothing);
    },
  );

  testWidgets('videos span the card above image thumbnails', (tester) async {
    await pumpPost(
      tester,
      postWith(
        media: const [
          ArticleAttachment(
            id: 'one',
            url: 'https://example.invalid/one.webp',
            mime: 'image/webp',
          ),
          ArticleAttachment(
            id: 'video',
            url: 'https://example.invalid/video.mp4',
            mime: 'video/mp4',
          ),
        ],
      ),
    );
    final video = find.byIcon(Icons.play_circle_fill_rounded);
    final image = find.byType(Image).first;
    expect(tester.getCenter(video).dy, lessThan(tester.getCenter(image).dy));
    final gallery = find.byType(VnlfMediaGallery);
    final ratios = find.descendant(
      of: gallery,
      matching: find.byType(AspectRatio),
    );
    expect(tester.getSize(ratios.first).width, tester.getSize(gallery).width);
  });

  testWidgets('POST headings inherit the website body size', (tester) async {
    await pumpPost(tester, postWith());
    final richText = tester.widget<RichText>(
      find.text('Tiếng Việt: ặ ữ ờ ẫ ệ', findRichText: true),
    );
    expect(richText.text.style!.fontSize, 13);
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
          child: VnlfPostCard(post: presentPost(post)),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
