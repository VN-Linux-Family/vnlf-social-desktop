import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vnlfsocialapp/src/app/providers.dart';
import 'package:vnlfsocialapp/src/domain/models.dart' show Session;
import 'package:vnlfsocialapp/src/features/thread/presentation/comments_providers.dart';
import 'package:vnlfsocialapp/src/core/api_client.dart';
import 'package:vnlfsocialapp/src/features/thread/data/comments_repository.dart';
import 'package:vnlfsocialapp/src/features/thread/presentation/comment_actions.dart';

void main() {
  test(
    'fresh reads replace acknowledged overrides while stale reads retain them',
    () async {
      final controller = CommentActionsController(
        LiveCommentsRepository(
          _client(
            (r) async => ApiResponse(
              statusCode: 200,
              body: '{"voteScore":8,"viewerVote":1}',
            ),
          ),
        ),
        'article',
      );
      addTearDown(controller.dispose);
      final root = commentFromJson(_json());
      final oldRead = controller.revision;
      await controller.vote(root, 1);
      controller.acceptFresh(oldRead);
      expect(controller.state.apply([root]).single.voteScore, 8);
      controller.acceptFresh(controller.revision);
      final fresh = commentFromJson({..._json(), 'voteScore': 9});
      expect(controller.state.apply([fresh]).single.voteScore, 9);
    },
  );
  test('replying to a surviving orphan uses a root mention rather than a deleted parent', () {
    final root = commentFromJson(_json());
    final child = commentFromJson({
      ..._json(),
      'id': 'child',
      'parentId': root.id,
    });
    expect(commentReplyParent(child, [root, child]), root.id);
    expect(commentReplyParent(child, [child]), isNull);
    expect(commentReplyParent(root, [child]), isNull);
  });
  test(
    'pinning moves only the acknowledged root ahead and never pins a reply',
    () async {
      var calls = 0;
      final repo = LiveCommentsRepository(
        _client((r) async {
          calls++;
          return ApiResponse(
            statusCode: 200,
            body: '{"pinnedCommentId":"second"}',
          );
        }),
      );
      final controller = CommentActionsController(repo, 'article');
      addTearDown(controller.dispose);
      final root = commentFromJson(_json());
      final second = commentFromJson({
        ..._json(),
        'id': 'second',
        'pinned': false,
      });
      final reply = commentFromJson({
        ..._json(),
        'id': 'reply',
        'parentId': 'second',
        'pinned': false,
      });
      expect(await controller.pin(second), isTrue);
      final list = controller.state.apply([root, second, reply]);
      expect(list.where((c) => c.pinned).map((c) => c.id), ['second']);
      expect(presentComments(list).first.id, 'second');
      expect(await controller.pin(reply), isFalse);
      expect(calls, 1);
    },
  );
  test('changing accounts replaces the mutation state and ignores the previous acknowledgment', () async {
    final response = Completer<ApiResponse>();
    final entered = Completer<void>();
    final repo = LiveCommentsRepository(
      _client((r) {
        entered.complete();
        return response.future;
      }),
    );
    final container = ProviderContainer(
      overrides: [commentsRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    final provider = commentActionsProvider('article');
    final subscription = container.listen(provider, (previous, next) {});
    addTearDown(subscription.close);
    final pending = container
        .read(provider.notifier)
        .vote(commentFromJson(_json()), 1);
    await entered.future;
    container.read(sessionStateProvider.notifier).state = const Session(
      userId: 'other',
      username: 'other',
      displayName: 'Other',
    );
    expect(container.read(provider).pending, isEmpty);
    response.complete(
      ApiResponse(statusCode: 200, body: '{"voteScore":99,"viewerVote":1}'),
    );
    expect(await pending, isFalse);
    expect(container.read(provider).changed, isEmpty);
  });
  test('comment DTO retains media, pin permissions and edit metadata', () {
    final comment = commentFromJson(_json());
    expect(comment.pinned, isTrue);
    expect(comment.canPin, isTrue);
    expect(comment.editedAt, DateTime.utc(2026, 11, 1));
    expect(comment.attachments.single.width, 640);
    expect(comment.gif!.title, 'Chim cánh cụt');
    expect(comment.gif!.hidden, isFalse);
  });

  test(
    'comment edits preserve media and await the confirmed server record',
    () async {
      final requests = <ApiRequest>[];
      final client = _client((request) async {
        requests.add(request);
        return ApiResponse(
          statusCode: 200,
          body: jsonEncode(_json(content: '')),
        );
      });
      final repo = LiveCommentsRepository(client);
      final edited = await repo.edit('comment/1', '');
      expect(requests.single.method, 'PATCH');
      expect(requests.single.path, '/api/v1/comments/comment%2F1');
      expect(jsonDecode(requests.single.body!), {'content': ''});
      expect(edited.content, '');
      expect(edited.attachments, hasLength(1));
    },
  );

  test('pin, vote and delete use the verified contract and require acknowledgments', () async {
    final requests = <ApiRequest>[];
    var invalid = false;
    final repo = LiveCommentsRepository(
      _client((request) async {
        requests.add(request);
        final body = invalid
            ? <String, dynamic>{}
            : switch (request.method) {
                'DELETE' => {'ok': true},
                _ when request.path.endsWith('/vote') => {
                  'voteScore': 9,
                  'viewerVote': -1,
                },
                _ => {'pinnedCommentId': null},
              };
        return ApiResponse(statusCode: 200, body: jsonEncode(body));
      }),
    );
    final vote = await repo.vote('c', -1);
    expect(vote.score, 9);
    expect(vote.value, -1);
    await repo.pin('article', null);
    await repo.delete('c');
    expect(requests.map((r) => '${r.method} ${r.path}'), [
      'PUT /api/v1/comments/c/vote',
      'PUT /api/v1/articles/article/pinned-comment',
      'DELETE /api/v1/comments/c',
    ]);
    expect(jsonDecode(requests[1].body!), {'commentId': null});
    invalid = true;
    await expectLater(repo.delete('c'), throwsA(isA<ParseFailure>()));
    await expectLater(repo.pin('article', 'c'), throwsA(isA<ParseFailure>()));
  });

  test(
    'failed writes never retry automatically or change confirmed comment',
    () async {
      var calls = 0;
      final repo = LiveCommentsRepository(
        _client((r) async {
          calls++;
          return ApiResponse(statusCode: 503, body: '{}');
        }),
      );
      final controller = CommentActionsController(repo, 'article');
      addTearDown(controller.dispose);
      final comment = commentFromJson(_json());
      await controller.edit(comment, 'new text');
      expect(calls, 1);
      expect(controller.state.changed, isEmpty);
      expect(controller.state.errors[comment.id], isA<HttpFailure>());
      expect(controller.state.pending, isEmpty);
    },
  );

  test('duplicate clicks serialize and late acknowledgments cannot survive disposal', () async {
    final response = Completer<ApiResponse>();
    var calls = 0;
    final repo = LiveCommentsRepository(
      _client((r) {
        calls++;
        return response.future;
      }),
    );
    final controller = CommentActionsController(repo, 'article');
    final comment = commentFromJson(_json());
    final pending = controller.vote(comment, 1);
    await controller.vote(comment, 1);
    expect(calls, 1);
    expect(controller.state.pending, contains(comment.id));
    controller.dispose();
    response.complete(
      ApiResponse(statusCode: 200, body: '{"voteScore":7,"viewerVote":1}'),
    );
    expect(await pending, isFalse);
  });

  test(
    'confirmed deletion hides only the removed root; replies remain available',
    () async {
      final controller = CommentActionsController(
        LiveCommentsRepository(
          _client(
            (r) async => ApiResponse(statusCode: 200, body: '{"ok":true}'),
          ),
        ),
        'article',
      );
      addTearDown(controller.dispose);
      final root = commentFromJson(_json());
      final child = commentFromJson({
        ..._json(),
        'id': 'child',
        'parentId': root.id,
      });
      await controller.delete(root);
      expect(controller.state.apply([root, child]).map((c) => c.id), ['child']);
    },
  );
}

ApiClient _client(ApiTransport transport) => ApiClient(
  transport: transport,
  throttleInterval: Duration.zero,
  hostKey: Object(),
);
Map<String, dynamic> _json({String content = 'Bình luận gốc'}) => {
  'id': 'root',
  'content': content,
  'author': {
    'id': 'owner',
    'username': 'synthetic',
    'displayName': 'Thử nghiệm',
  },
  'pinned': true,
  'canPin': true,
  'canEdit': true,
  'canDelete': true,
  'editedAt': '2026-11-01T00:00:00Z',
  'attachments': [
    {
      'id': 'image',
      'url': 'https://example.org/photo.png',
      'mime': 'image/png',
      'width': 640,
      'height': 480,
    },
  ],
  'gif': {
    'provider': 'VNLF',
    'url': 'https://example.org/sticker.webp',
    'title': 'Chim cánh cụt',
    'width': 120,
    'height': 120,
    'hidden': false,
  },
};
