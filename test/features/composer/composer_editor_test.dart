import 'package:fleather/fleather.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/features/composer/presentation/composer_editor.dart';

void main() {
  testWidgets('post editor uses the website canvas typography', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ComposerEditor(
            document: const {
              'type': 'doc',
              'content': [
                {'type': 'paragraph'},
              ],
            },
            assets: const {},
            postStyle: true,
            onChanged: (_) {},
          ),
        ),
      ),
    );
    final style = FleatherTheme.of(
      tester.element(find.byType(FleatherEditor)),
    )!;
    expect(style.paragraph.style.fontSize, 13);
    expect(style.paragraph.style.height, 1.6);
    expect(style.heading2.style.fontSize, 13);
    expect(style.heading2.style.fontWeight, FontWeight.w700);
    expect(style.heading3.style.fontSize, 13);
  });
  testWidgets(
    'native rich editor formats Vietnamese and emits server content',
    (tester) async {
      Map<String, dynamic>? changed;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ComposerEditor(
              document: const {
                'type': 'doc',
                'content': [
                  {'type': 'paragraph'},
                ],
              },
              assets: const {},
              onChanged: (value) => changed = value,
            ),
          ),
        ),
      );
      final editor = tester.widget<FleatherEditor>(find.byType(FleatherEditor));
      const text = 'Tiếng Việt: ặ ữ ờ ẫ ệ';
      editor.controller.replaceText(
        0,
        0,
        text,
        selection: TextSelection(baseOffset: 0, extentOffset: text.length),
      );
      await tester.pump();
      await tester.tap(find.byTooltip('Đậm'));
      await tester.pump();
      expect(changed!['content'][0]['content'][0]['marks'], [
        {'type': 'bold'},
      ]);
      expect(
        changed!['content'][0]['content'][0]['text'],
        'Tiếng Việt: ặ ữ ờ ẫ ệ',
      );
    },
  );
  testWidgets('read-only mode disables formatting and document input', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ComposerEditor(
            document: const {
              'type': 'doc',
              'content': [
                {'type': 'paragraph'},
              ],
            },
            assets: const {},
            readOnly: true,
            onChanged: (_) => fail('Unexpected change'),
          ),
        ),
      ),
    );
    expect(
      tester.widget<FleatherEditor>(find.byType(FleatherEditor)).readOnly,
      isTrue,
    );
    final bold = tester.widget<IconButton>(
      find.byWidgetPredicate(
        (widget) => widget is IconButton && widget.tooltip == 'Đậm',
      ),
    );
    expect(bold.onPressed, isNull);
  });
}
