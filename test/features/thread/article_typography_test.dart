import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/design_system/components/vnlf_rich_content.dart';

void main() {
  testWidgets(
    'empty article paragraphs collapse without adding blank text lines',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VnlfRichContent(
              articleDetail: true,
              document: {
                'type': 'doc',
                'content': [
                  {
                    'type': 'paragraph',
                    'content': [
                      {'type': 'text', 'text': 'Trước đoạn trống'},
                    ],
                  },
                  {'type': 'paragraph'},
                  {'type': 'paragraph'},
                  {
                    'type': 'paragraph',
                    'content': [
                      {'type': 'text', 'text': 'Sau đoạn trống'},
                    ],
                  },
                ],
              },
            ),
          ),
        ),
      );
      final before = tester.getRect(
        find.text('Trước đoạn trống', findRichText: true),
      );
      final after = tester.getRect(
        find.text('Sau đoạn trống', findRichText: true),
      );
      expect(after.top - before.bottom, 12);
    },
  );
  for (final width in [1440.0, 430.0]) {
    testWidgets(
      'article paragraphs and headings collapse adjacent margins at $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: VnlfRichContent(
                articleDetail: true,
                document: {
                  'type': 'doc',
                  'content': [
                    {
                      'type': 'paragraph',
                      'content': [
                        {'type': 'text', 'text': 'Đoạn văn trước tiêu đề'},
                      ],
                    },
                    {
                      'type': 'heading',
                      'attrs': {'level': 2},
                      'content': [
                        {'type': 'text', 'text': 'Tiêu đề sau đoạn văn'},
                      ],
                    },
                  ],
                },
              ),
            ),
          ),
        );
        final before = tester.getRect(
          find.text('Đoạn văn trước tiêu đề', findRichText: true),
        );
        final after = tester.getRect(
          find.text('Tiêu đề sau đoạn văn', findRichText: true),
        );
        expect(after.top - before.bottom, width <= 840 ? 12 : 19);
      },
    );
    testWidgets(
      'article detail matches live typography and spacing at $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: VnlfRichContent(
                articleDetail: true,
                document: {
                  'type': 'doc',
                  'content': [
                    {
                      'type': 'heading',
                      'attrs': {'level': 2},
                      'content': [
                        {'type': 'text', 'text': 'Tiêu đề nội dung'},
                      ],
                    },
                    {
                      'type': 'paragraph',
                      'content': [
                        {'type': 'text', 'text': 'Tiếng Việt: ặ ữ ờ ẫ ệ'},
                      ],
                    },
                  ],
                },
              ),
            ),
          ),
        );
        final heading = tester.widget<RichText>(
          find.text('Tiêu đề nội dung', findRichText: true),
        );
        final paragraph = tester.widget<RichText>(
          find.text('Tiếng Việt: ặ ữ ờ ẫ ệ', findRichText: true),
        );
        expect(heading.text.style!.fontSize, 13);
        expect(heading.text.style!.height, 1.08);
        expect(heading.text.style!.fontWeight, FontWeight.w700);
        expect(paragraph.text.style!.fontSize, 13);
        expect(paragraph.text.style!.height, 1.7);
        // The heading's bottom margin separates it from the paragraph; the
        // first top and last bottom margins collapse into the page's spacing.
        final gap =
            tester
                .getRect(find.text('Tiếng Việt: ặ ữ ờ ẫ ệ', findRichText: true))
                .top -
            tester
                .getRect(find.text('Tiêu đề nội dung', findRichText: true))
                .bottom;
        expect(gap, width <= 840 ? 7 : 10);
      },
    );
  }
}
