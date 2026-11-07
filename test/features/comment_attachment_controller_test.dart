import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/core/api_client.dart';
import 'package:vnlfsocialapp/src/core/session_storage_contract.dart';
import 'package:vnlfsocialapp/src/features/thread/data/comment_pending_store.dart';
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
      return ApiResponse(statusCode: bodies.length == 1 ? 500 : 200, body: bodies.length == 1 ? '{}' : '{"id":"comment","content":"","attachments":[{"id":"asset"}],"author":{}}');
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
  test('uncertain creation freezes the original payload and identity', () async {
    final bodies = <Map<String, dynamic>>[];
    final client = ApiClient(hostKey: Object(), throttleInterval: Duration.zero, transport: (request) async {
      bodies.add(jsonDecode(request.body!) as Map<String, dynamic>);
      return ApiResponse(statusCode: bodies.length == 1 ? 500 : 200,
          body: bodies.length == 1 ? '{}' : '{"id":"comment","content":"first","author":{}}');
    });
    final draft = CommentAttachmentController('article', CommentMediaRepository(client), LiveCommentsRepository(client), client);
    await expectLater(draft.submit('first'), throwsA(isA<AppFailure>()));
    expect(draft.submissionPending, isTrue);
    expect(() => draft.add(file), throwsStateError);
    await expectLater(draft.submit('changed'), throwsStateError);
    expect(bodies, hasLength(1));
    await draft.submit('first');
    expect(bodies[0]['clientCommentId'], bodies[1]['clientCommentId']);
    expect(draft.submissionPending, isFalse);
  });

  test('a first source-confirmed rejection unlocks, but a later one does not', () async {
    var attempt = 0;
    final client = ApiClient(hostKey: Object(), throttleInterval: Duration.zero, transport: (_) async {
      attempt++;
      if (attempt == 2) return ApiResponse(statusCode: 500, body: '{}');
      return ApiResponse(statusCode: 400, body: '{"code":"COMMENT_REPLY_DEPTH"}');
    });
    final draft = CommentAttachmentController('article', CommentMediaRepository(client), LiveCommentsRepository(client), client);
    await expectLater(draft.submit('first'), throwsA(isA<HttpFailure>()));
    expect(draft.submissionPending, isFalse);
    await expectLater(draft.submit('changed'), throwsA(isA<HttpFailure>()));
    expect(draft.submissionPending, isTrue);
    await expectLater(draft.submit('changed'), throwsA(isA<HttpFailure>()));
    expect(draft.submissionPending, isTrue);
    await expectLater(draft.submit('different'), throwsStateError);
    expect(attempt, 3);
  });

  test('pending create recovers by owner and article after controller disposal', () async {
    final storage = _Storage();
    final bodies = <Map<String, dynamic>>[];
    final client = ApiClient(hostKey: Object(), throttleInterval: Duration.zero, transport: (request) async {
      bodies.add(jsonDecode(request.body!) as Map<String, dynamic>);
      return ApiResponse(statusCode: bodies.length == 1 ? 500 : 200, body: bodies.length == 1 ? '{}' : '{"id":"comment","content":"first","author":{}}');
    });
    CommentAttachmentController make(String owner) => CommentAttachmentController('article', CommentMediaRepository(client), LiveCommentsRepository(client), client, store: CommentPendingStore(storage), ownerId: owner);
    final first = make('owner');
    await expectLater(first.submit('first'), throwsA(isA<HttpFailure>()));
    final other = make('other');
    await other.initialize();
    expect(other.pending, isNull);
    final restored = make('owner');
    await restored.initialize();
    expect(restored.pending!.content, 'first');
    expect(restored.pending!.parentId, isNull);
    await expectLater(restored.submit('different'), throwsStateError);
    await restored.submit('first');
    expect(bodies.first['clientCommentId'], bodies.last['clientCommentId']);
    expect((await CommentPendingStore(storage).read('owner', 'article'))!.confirmedCommentId, 'comment');
    await restored.dismissConfirmation();
    expect(await CommentPendingStore(storage).read('owner', 'article'), isNull);
  });

  test('session invalidation during receipt write preserves confirmation for owner', () async {
    final storage = _BlockingReceiptStorage();
    var sends = 0;
    final client = ApiClient(hostKey: Object(), throttleInterval: Duration.zero, transport: (_) async {
      sends++;
      return ApiResponse(statusCode: 200, body: '{"id":"confirmed","content":"first","author":{}}');
    });
    CommentAttachmentController make(String owner) => CommentAttachmentController('article', CommentMediaRepository(client), LiveCommentsRepository(client), client, store: CommentPendingStore(storage), ownerId: owner);
    final first = make('owner');
    final submission = first.submit('first');
    await storage.started.future;
    client.invalidateSession();
    storage.resume.complete();
    await expectLater(submission, throwsA(isA<HttpFailure>()));
    final other = make('other');
    await other.initialize();
    expect(other.pending, isNull);
    final restored = make('owner');
    await restored.initialize();
    expect(restored.pending!.confirmedCommentId, 'confirmed');
    await expectLater(restored.submit('first'), throwsStateError);
    expect(sends, 1);
    await restored.dismissConfirmation();
    expect(await CommentPendingStore(storage).read('owner', 'article'), isNull);
  });

  test('late receipt dismissal cannot remove a newer identity', () async {
    final store = CommentPendingStore(_Storage());
    const first = PendingComment(identity: 'a', content: 'first', parentId: null, attachmentIds: []);
    const newer = PendingComment(identity: 'b', content: 'second', parentId: null, attachmentIds: []);
    await store.write('owner', 'article', first);
    final receipt = await store.confirm('owner', 'article', first, 'comment');
    await store.clear('owner', 'article', receipt);
    await store.write('owner', 'article', newer);
    await expectLater(store.clear('owner', 'article', receipt), throwsA(isA<ParseFailure>()));
    expect((await store.read('owner', 'article'))!.identity, 'b');
  });

  test('failed storage write cannot lead to an unreserved POST', () async {
    final storage = _FailingStorage();
    var sends = 0;
    final client = ApiClient(hostKey: Object(), throttleInterval: Duration.zero, transport: (_) async {
      sends++;
      return ApiResponse(statusCode: 200, body: '{"id":"c","content":"first","author":{}}');
    });
    final draft = CommentAttachmentController('article', CommentMediaRepository(client), LiveCommentsRepository(client), client, store: CommentPendingStore(storage), ownerId: 'owner');
    await expectLater(draft.submit('first'), throwsA(isA<StateError>()));
    await expectLater(draft.submit('first'), throwsA(isA<StateError>()));
    expect(sends, 0);
    storage.fail = false;
    await draft.submit('first');
    expect(sends, 1);
  });

  test('competing controllers reserve at most one payload', () async {
    final storage = _Storage();
    final started = Completer<void>();
    final reply = Completer<ApiResponse>();
    var sends = 0;
    final client = ApiClient(hostKey: Object(), throttleInterval: Duration.zero, transport: (_) {
      sends++;
      started.complete();
      return reply.future;
    });
    CommentAttachmentController make() => CommentAttachmentController('article', CommentMediaRepository(client), LiveCommentsRepository(client), client, store: CommentPendingStore(storage), ownerId: 'owner');
    final first = make();
    final second = make();
    await Future.wait([first.initialize(), second.initialize()]);
    final pending = first.submit('first');
    await started.future;
    await expectLater(second.submit('second'), throwsA(isA<ParseFailure>()));
    expect(sends, 1);
    reply.complete(ApiResponse(statusCode: 200, body: '{"id":"c","content":"first","author":{}}'));
    await pending;
  });

  test('late acknowledgment cannot clear a newer reservation', () async {
    final store = CommentPendingStore(_Storage());
    const a = PendingComment(identity: 'a', content: 'first', parentId: null, attachmentIds: []);
    const c = PendingComment(identity: 'c', content: 'new', parentId: null, attachmentIds: []);
    await store.write('owner', 'article', a);
    await store.clear('owner', 'article', a);
    await store.write('owner', 'article', c);
    await expectLater(store.clear('owner', 'article', a), throwsA(isA<ParseFailure>()));
    expect((await store.read('owner', 'article'))!.identity, 'c');
  });

}


final class _Storage implements SessionStorage {
  final values = <String, String>{};
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async { values[key] = value; }
  @override
  Future<void> delete(String key) async { values.remove(key); }
}

final class _FailingStorage implements SessionStorage {
  final values = <String, String>{};
  bool fail = true;
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async {
    if (fail) throw StateError('storage unavailable');
    values[key] = value;
  }
  @override
  Future<void> delete(String key) async { values.remove(key); }
}

final class _BlockingReceiptStorage implements SessionStorage {
  final values = <String, String>{};
  final started = Completer<void>();
  final resume = Completer<void>();
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async {
    if (value.contains('confirmedCommentId')) {
      started.complete();
      await resume.future;
    }
    values[key] = value;
  }
  @override
  Future<void> delete(String key) async { values.remove(key); }
}
