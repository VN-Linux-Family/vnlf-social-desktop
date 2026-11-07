import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/core/api_client.dart';
import 'package:vnlfsocialapp/src/features/thread/data/comment_media_repository.dart';
import 'package:vnlfsocialapp/src/features/thread/data/comments_repository.dart';
import 'package:vnlfsocialapp/src/features/thread/domain/comment_upload.dart';

void main() {
  final file = CommentUploadFile(name: 'photo.png', mime: 'image/png', length: 3,
      openRead: () => Stream.value([1, 2, 3]));

  test('uploads to the signed URL and completes the article asset', () async {
    final requests = <ApiRequest>[];
    final client = ApiClient(hostKey: Object(), throttleInterval: Duration.zero,
        transport: (request) async {
      requests.add(request);
      return ApiResponse(statusCode: 200, body: requests.length == 1
          ? '{"assetId":"asset-1","uploadUrl":"https://storage.example/put","headers":{"content-type":"image/png","cookie":"secret"}}'
          : '{"assetId":"asset-1","status":"READY"}');
    });
    final repo = CommentMediaRepository(client, upload: (uri, file, headers) async {
      expect(uri.host, 'storage.example');
      expect(headers, {'content-type': 'image/png'});
      expect(await file.openRead().toList(), [[1, 2, 3]]);
    });
    final result = await repo.upload('article', file);
    expect(result.assetId, 'asset-1');
    expect(requests.map((r) => r.path), [
      '/api/v1/articles/article/comment-assets/presign',
      '/api/v1/articles/article/comment-assets/asset-1/complete',
    ]);
    expect(jsonDecode(requests.first.body!), {'fileName': 'photo.png', 'mime': 'image/png', 'size': 3});
  });

  test('account change during upload prevents completion', () async {
    final requests = <ApiRequest>[];
    late ApiClient client;
    client = ApiClient(hostKey: Object(), throttleInterval: Duration.zero,
        transport: (request) async {
      requests.add(request);
      return ApiResponse(statusCode: 200, body: '{"assetId":"asset-1","uploadUrl":"https://storage.example/put"}');
    });
    final repo = CommentMediaRepository(client, upload: (_, _, _) async {
      client.invalidateSession();
    });
    await expectLater(repo.upload('article', file), throwsA(isA<HttpFailure>()));
    expect(requests.length, 1);
  });

  test('media-only comment sends asset IDs and stable identity', () async {
    late ApiRequest sent;
    final client = ApiClient(hostKey: Object(), throttleInterval: Duration.zero,
        transport: (request) async {
      sent = request;
      return ApiResponse(statusCode: 200, body: '{"id":"comment","content":"","author":{}}');
    });
    await LiveCommentsRepository(client).create('article', '',
        attachmentIds: ['asset-1'], clientCommentId: 'identity');
    expect(jsonDecode(sent.body!), {'content': '', 'attachmentIds': ['asset-1'], 'clientCommentId': 'identity'});
  });
}
