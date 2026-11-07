import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/core/api_client.dart';
import 'package:vnlfsocialapp/src/features/thread/data/comment_attachment_controller.dart';
import 'package:vnlfsocialapp/src/features/thread/data/comment_media_repository.dart';
import 'package:vnlfsocialapp/src/features/thread/data/comments_repository.dart';
import 'package:vnlfsocialapp/src/features/thread/domain/comment_upload.dart';

void main() {
  final file = CommentUploadFile(name: 'a.png', mime: 'image/png', length: 1, openRead: () => Stream.value([1]));
  test('retains ready ID and identity across explicit comment retry', () async {
    final bodies = <Map<String, dynamic>>[];
    var completeCount = 0;
    final client = ApiClient(hostKey: Object(), throttleInterval: Duration.zero, transport: (r) async {
      if (r.path.endsWith('/presign')) return ApiResponse(statusCode: 200, body: '{"assetId":"asset","uploadUrl":"https://storage.example/put"}');
      if (r.path.endsWith('/complete')) {
        completeCount++;
        return ApiResponse(statusCode: completeCount == 1 ? 500 : 200, body: completeCount == 1 ? '{}' : '{"assetId":"asset","status":"READY"}');
      }
      bodies.add(jsonDecode(r.body!) as Map<String, dynamic>);
      return ApiResponse(statusCode: bodies.length == 1 ? 500 : 200, body: bodies.length == 1 ? '{}' : '{"id":"comment","content":"","author":{}}');
    });
    final controller = CommentAttachmentController('article', CommentMediaRepository(client, upload: (_, _, _) async {}), LiveCommentsRepository(client), client);
    final item = controller.add(file);
    await expectLater(controller.upload(item), throwsA(isA<AppFailure>()));
    expect(item.assetId, 'asset');
    expect(item.state, CommentAttachmentState.completeFailed);
    await controller.retryCompletion(item);
    expect(controller.readyIds, ['asset']);
    await expectLater(controller.submit(''), throwsA(isA<AppFailure>()));
    expect(controller.readyIds, ['asset']);
    await controller.submit('');
    expect(bodies[0]['clientCommentId'], bodies[1]['clientCommentId']);
    expect(bodies[1]['attachmentIds'], ['asset']);
    expect(controller.attachments, isEmpty);
  });

  test('unknown upload outcome cannot be automatically resent', () async {
    var puts = 0;
    final client = ApiClient(hostKey: Object(), throttleInterval: Duration.zero, transport: (_) async => ApiResponse(statusCode: 200, body: '{"assetId":"asset","uploadUrl":"https://storage.example/put"}'));
    final controller = CommentAttachmentController('article', CommentMediaRepository(client, upload: (_, _, _) async { puts++; throw const TransportFailure(); }), LiveCommentsRepository(client), client);
    final item = controller.add(file);
    await expectLater(controller.upload(item), throwsA(isA<TransportFailure>()));
    expect(item.assetId, 'asset');
    await expectLater(controller.upload(item), throwsStateError);
    expect(puts, 1);
    controller.remove(item);
    expect(controller.attachments, isEmpty);
  });

  test('limits draft to ten and invalidates the draft with its session', () {
    final client = ApiClient(hostKey: Object(), throttleInterval: Duration.zero, transport: (_) async => ApiResponse(statusCode: 500, body: '{}'));
    final controller = CommentAttachmentController('article', CommentMediaRepository(client), LiveCommentsRepository(client), client);
    for (var i = 0; i < 10; i++) { controller.add(file); }
    expect(() => controller.add(file), throwsStateError);
    client.invalidateSession();
    expect(() => controller.remove(controller.attachments.first), throwsA(isA<HttpFailure>()));
  });
}
