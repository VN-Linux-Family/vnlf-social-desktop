import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/core/api_client.dart';
import 'package:vnlfsocialapp/src/features/thread/mention/mention_candidates.dart';
import 'package:vnlfsocialapp/src/features/thread/mention/mention_controller.dart';

final class FakeCandidates implements MentionCandidatesRepository {
  final requests = <String, Completer<List<MentionCandidate>>>{};
  @override
  Future<List<MentionCandidate>> search(String articleId, String query) =>
      (requests[query] = Completer()).future;
}

void main() {
  const person = MentionCandidate(
    id: '1',
    username: 'dung',
    displayName: 'Dũng Lê',
  );
  test('token observes boundaries, Vietnamese names and query limit', () {
    expect(mentionToken('hello (@Dũng Lê', 15)?.query, 'Dũng Lê');
    expect(mentionToken('a@name', 6), isNull);
    expect(mentionToken('@${'a' * 31}', 32), isNull);
  });

  testWidgets('hides stale results and preserves suffix when selecting', (
    tester,
  ) async {
    final input = TextEditingController();
    final repository = FakeCandidates();
    final client = ApiClient(
      transport: (_) async => ApiResponse(statusCode: 200, body: '{}'),
    );
    final controller = MentionController(
      input: input,
      repository: repository,
      client: client,
      articleId: 'article',
      authenticated: true,
    );
    input.value = const TextEditingValue(
      text: '@a suffix',
      selection: TextSelection.collapsed(offset: 2),
    );
    await tester.pump(const Duration(milliseconds: 150));
    input.value = const TextEditingValue(
      text: '@ab suffix',
      selection: TextSelection.collapsed(offset: 3),
    );
    repository.requests['a']!.complete([person]);
    await tester.pump();
    expect(controller.items, isEmpty);
    await tester.pump(const Duration(milliseconds: 150));
    repository.requests['ab']!.complete([person]);
    await tester.pump();
    controller.pick(person);
    expect(input.text, '@dung  suffix');
    expect(input.selection.baseOffset, 6);
    controller.dispose();
    input.dispose();
  });

  testWidgets('session invalidation hides pending results', (tester) async {
    final input = TextEditingController();
    final repository = FakeCandidates();
    final client = ApiClient(
      transport: (_) async => ApiResponse(statusCode: 200, body: '{}'),
    );
    final controller = MentionController(
      input: input,
      repository: repository,
      client: client,
      articleId: 'article',
      authenticated: true,
    );
    input.value = const TextEditingValue(
      text: '@a',
      selection: TextSelection.collapsed(offset: 2),
    );
    await tester.pump(const Duration(milliseconds: 150));
    client.invalidateSession();
    repository.requests['a']!.complete([person]);
    await tester.pump();
    expect(controller.items, isEmpty);
    controller.dispose();
    input.dispose();
  });

  testWidgets('pointer selection waits for IME composition to finish', (
    tester,
  ) async {
    final input = TextEditingController();
    final repository = FakeCandidates();
    final client = ApiClient(
      transport: (_) async => ApiResponse(statusCode: 200, body: '{}'),
    );
    final controller = MentionController(
      input: input,
      repository: repository,
      client: client,
      articleId: 'article',
      authenticated: true,
    );
    input.value = const TextEditingValue(
      text: '@a',
      selection: TextSelection.collapsed(offset: 2),
    );
    await tester.pump(const Duration(milliseconds: 150));
    repository.requests['a']!.complete([person]);
    await tester.pump();
    input.value = input.value.copyWith(
      composing: const TextRange(start: 1, end: 2),
    );
    controller.pick(person);
    expect(input.text, '@a');
    input.value = input.value.copyWith(composing: TextRange.empty);
    controller.pick(person);
    expect(input.text, '@dung ');
    controller.dispose();
    input.dispose();
  });

  testWidgets('blur hides suggestions and invalidates a pending request', (
    tester,
  ) async {
    final input = TextEditingController();
    final focus = FocusNode();
    final repository = FakeCandidates();
    final client = ApiClient(
      transport: (_) async => ApiResponse(statusCode: 200, body: '{}'),
    );
    final controller = MentionController(
      input: input,
      focusNode: focus,
      repository: repository,
      client: client,
      articleId: 'article',
      authenticated: true,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TextField(controller: input, focusNode: focus),
        ),
      ),
    );
    focus.requestFocus();
    await tester.pump();
    input.value = const TextEditingValue(
      text: '@a',
      selection: TextSelection.collapsed(offset: 2),
    );
    await tester.pump(const Duration(milliseconds: 150));
    focus.unfocus();
    await tester.pump();
    repository.requests['a']!.complete([person]);
    await tester.pump();
    expect(controller.items, isEmpty);
    expect(controller.loading, isFalse);
    controller.dispose();
    await tester.pumpWidget(const SizedBox());
    focus.dispose();
    input.dispose();
  });
}
