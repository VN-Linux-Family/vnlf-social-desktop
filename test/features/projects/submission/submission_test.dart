import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/core/api_client.dart';
import 'package:vnlfsocialapp/src/features/projects/submission/project_submission.dart';

void main() {
  ProjectSubmissionInput valid() => const ProjectSubmissionInput(
    name: 'Dự án', tagline: 'Một dự án', intro: 'Giới thiệu dự án dài hơn ba mươi ký tự.',
    type: 'TOOL', relation: 'AUTHOR', repoUrl: '', noRepo: true,
    links: [ProjectSubmissionLink('WEBSITE', 'https://example.org')],
  );

  test('requires an introduction and a link without a repository', () {
    final errors = const ProjectSubmissionInput(
      name: '', tagline: '', intro: 'ngắn', type: '', relation: '',
      repoUrl: '', noRepo: true,
    ).validate();
    expect(errors.keys, containsAll(['name', 'tagline', 'intro', 'type', 'relation', 'links']));
    expect(valid().validate(), isEmpty);
  });

  test('strict acknowledgement accepts only a pending project identity', () async {
    var response = '{"id":"550e8400-e29b-41d4-a716-446655440000","slug":"du-an","status":"PENDING"}';
    final client = ApiClient(transport: (_) async => ApiResponse(statusCode: 201, body: response), throttleInterval: Duration.zero, hostKey: Object());
    final repository = LiveProjectSubmissionRepository(client);
    expect((await repository.create(valid())).slug, 'du-an');
    response = '{"slug":"du-an","status":"APPROVED"}';
    await expectLater(repository.create(valid()), throwsA(isA<ParseFailure>()));
  });

  test('uncertain response locks repeat submission and keeps draft', () async {
    var calls = 0;
    final client = ApiClient(transport: (_) async { calls++; throw TimeoutException('lost'); }, throttleInterval: Duration.zero, hostKey: Object());
    final controller = ProjectSubmissionController(repository: LiveProjectSubmissionRepository(client), ownerId: 'one', currentOwner: () => 'one');
    controller.input = valid();
    await controller.submit();
    await controller.submit();
    expect(calls, 1);
    expect(controller.uncertain, isTrue);
    expect(controller.input.name, 'Dự án');
  });

  test('account switch during send cannot expose acknowledgement or resend', () async {
    final response = Completer<ApiResponse>();
    var owner = 'one';
    final client = ApiClient(transport: (_) => response.future, throttleInterval: Duration.zero, hostKey: Object());
    final controller = ProjectSubmissionController(repository: LiveProjectSubmissionRepository(client), ownerId: 'one', currentOwner: () => owner);
    controller.input = valid();
    final pending = controller.submit();
    await Future<void>.delayed(Duration.zero);
    owner = 'two';
    client.invalidateSession();
    response.complete(ApiResponse(statusCode: 201, body: jsonEncode({'id': '550e8400-e29b-41d4-a716-446655440000', 'slug': 'du-an', 'status': 'PENDING'})));
    await pending;
    expect(controller.receipt, isNull);
    expect(controller.uncertain, isTrue);
  });
}
