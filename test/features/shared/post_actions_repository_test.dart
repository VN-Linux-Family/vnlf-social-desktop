import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/core/api_client.dart';
import 'package:vnlfsocialapp/src/features/shared/data/post_actions_repository.dart';

void main() {
  late List<ApiRequest> requests;

  LivePostActionsRepository repository({
    bool signedIn = true,
    ApiResponse? response,
  }) {
    requests = [];
    return LivePostActionsRepository(
      ApiClient(
        hostKey: Object(),
        throttleInterval: Duration.zero,
        transport: (request) async {
          requests.add(request);
          return response ??
              ApiResponse(statusCode: 200, body: jsonEncode({'ok': true}));
        },
      ),
      hasSession: () => signedIn,
    );
  }

  test('saving posts and unsaving deletes the bookmark', () async {
    final repo = repository();
    await repo.setBookmark('post-1', saved: true);
    await repo.setBookmark('post-1', saved: false);
    expect(requests.map((r) => '${r.method} ${r.path}'), [
      'POST /api/v1/articles/post-1/bookmark',
      'DELETE /api/v1/articles/post-1/bookmark',
    ]);
  });

  test('delete and hide call the website routes', () async {
    final repo = repository();
    await repo.deletePost('post-1');
    await repo.hidePost('post-2');
    expect(requests.map((r) => '${r.method} ${r.path}'), [
      'DELETE /api/v1/articles/post-1',
      'POST /api/v1/articles/post-2/hide',
    ]);
  });

  test('guests send nothing', () async {
    final repo = repository(signedIn: false);
    await expectLater(repo.hidePost('post-1'), throwsA(isA<HttpFailure>()));
    await expectLater(repo.deletePost('post-1'), throwsA(isA<HttpFailure>()));
    expect(requests, isEmpty);
  });

  test('a failed delete is not retried', () async {
    final repo = repository(
      response: ApiResponse(
        statusCode: 503,
        body: jsonEncode({
          'error': {'code': 'UNAVAILABLE', 'retryable': true},
        }),
      ),
    );
    await expectLater(repo.deletePost('post-1'), throwsA(isA<AppFailure>()));
    expect(requests, hasLength(1));
  });
}
