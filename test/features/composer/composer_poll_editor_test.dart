import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/features/composer/domain/composer_draft.dart';
import 'package:vnlfsocialapp/src/features/composer/domain/composer_poll.dart';
import 'package:vnlfsocialapp/src/features/composer/presentation/composer_poll_editor.dart';

void main() {
  testWidgets(
    'native poll authoring preserves unfinished input and bounds choices',
    (tester) async {
      var draft = const ComposerDraft(id: '', version: 0);
      await tester.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, setState) {
              return ComposerPollEditor(
                draft: draft,
                onChanged: (value) {
                  setState(() {
                    draft = value;
                  });
                },
              );
            },
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('composer-add-poll')));
      await tester.pump();
      expect(draft.pollDraft!.options, ['', '']);
      await tester.enterText(
        find.descendant(
          of: find.byKey(const Key('composer-poll-question')),
          matching: find.byType(TextField),
        ),
        'Bạn dùng gì?',
      );
      expect(draft.pollDraft!.question, 'Bạn dùng gì?');
      expect(draft.pollChanged, isTrue);
      expect(draft.pollDraft!.validated, isNull);
      for (var i = 0; i < 4; i++) {
        await tester.ensureVisible(
          find.byKey(const Key('composer-poll-add-choice')),
        );
        await tester.tap(find.byKey(const Key('composer-poll-add-choice')));
        await tester.pump();
      }
      expect(draft.pollDraft!.options.length, 6);
      expect(
        tester
            .widget<TextButton>(
              find.byKey(const Key('composer-poll-add-choice')),
            )
            .onPressed,
        isNull,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('poll fields use UTF16 counters without splitting emoji', (
    tester,
  ) async {
    var draft = ComposerDraft(
      id: '',
      version: 0,
      pollDraft: ComposerPollDraft('', ['', '']),
    );
    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (context, setState) {
            return ComposerPollEditor(
              draft: draft,
              onChanged: (value) {
                setState(() {
                  draft = value;
                });
              },
            );
          },
        ),
      ),
    );
    final field = find.descendant(
      of: find.byKey(const Key('composer-poll-question')),
      matching: find.byType(TextField),
    );
    await tester.enterText(field, '${'a' * 199}😀');
    await tester.pump();
    expect(draft.pollDraft!.question, 'a' * 199);
    expect(find.text('199/200'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('published poll cannot be replaced through the composer', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ComposerPollEditor(
            draft: ComposerDraft(
              id: 'saved',
              version: 2,
              status: 'PUBLISHED',
              pollDraft: ComposerPollDraft('Chọn', ['Linux', 'BSD']),
            ),
            onChanged: (_) => fail('Published poll changed'),
          ),
        ),
      ),
    );
    expect(find.text('Remove poll'), findsNothing);
    expect(find.byKey(const Key('composer-add-poll')), findsNothing);
    for (final field in tester.widgetList<TextField>(find.byType(TextField))) {
      expect(field.readOnly, isTrue);
    }
    expect(tester.takeException(), isNull);
  });
}

Widget _app(Widget child) => MaterialApp(
  home: Scaffold(body: SingleChildScrollView(child: child)),
);
