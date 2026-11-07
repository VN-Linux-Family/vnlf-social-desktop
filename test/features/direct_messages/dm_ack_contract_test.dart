import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/features/direct_messages/data/direct_message_media_repository.dart';
import 'package:vnlfsocialapp/src/features/direct_messages/domain/direct_message_models.dart';

import 'direct_message_repository_test.dart' show sampleMessageJson;

import 'package:vnlfsocialapp/src/core/api_client.dart';
import 'package:vnlfsocialapp/src/features/direct_messages/data/live_direct_message_repository.dart';

void main() {
  test(
    'private upload stops reading file chunks after its account changes',
    () async {
      var bytesSent = 0;
      var completes = 0;
      final client = _client((r) async {
        if (r.path.endsWith('/complete')) completes++;
        return ApiResponse(
          statusCode: 200,
          body: jsonEncode({
            'assetId': 'image',
            'uploadUrl': 'https://example.org/upload',
            'headers': {'content-type': 'image/png'},
          }),
        );
      });
      final media = DirectMessageMediaRepository(
        client,
        upload: (url, file, headers) async {
          await for (final chunk in file.openRead()) {
            bytesSent += chunk.length;
            client.invalidateSession();
          }
        },
      );
      await expectLater(
        media.upload(
          DmUploadFile(
            name: 'test.png',
            mime: 'image/png',
            length: 4,
            openRead: () => Stream.fromIterable([
              [1, 2],
              [3, 4],
            ]),
          ),
        ),
        throwsA(isA<HttpFailure>()),
      );
      expect(bytesSent, 2);
      expect(completes, 0);
    },
  );
  test(
    'a private upload cannot complete under an account that changed during PUT',
    () async {
      var completes = 0;
      final client = _client((r) async {
        if (r.path.endsWith('/complete')) completes++;
        return ApiResponse(
          statusCode: 200,
          body: jsonEncode(
            r.path.endsWith('/presign')
                ? {
                    'assetId': 'expected-asset',
                    'uploadUrl': 'https://example.org/upload',
                    'headers': {'content-type': 'image/png'},
                  }
                : {'assetId': 'expected-asset', 'status': 'READY'},
          ),
        );
      });
      final media = DirectMessageMediaRepository(
        client,
        upload: (url, file, headers) async {
          client.invalidateSession();
        },
      );
      await expectLater(
        media.upload(
          DmUploadFile(
            name: 'test.png',
            mime: 'image/png',
            length: 4,
            openRead: () => Stream.value([1, 2, 3, 4]),
          ),
        ),
        throwsA(isA<HttpFailure>()),
      );
      expect(completes, 0);
    },
  );
  test('DM send acknowledgments must identify the requested conversation and client message', () async {
    for (final change in [
      {'conversationId': 'another-conversation'},
      {'clientMessageId': 'another-attempt'},
    ]) {
      final repo = LiveDirectMessageRepository(
        _client(
          (r) async => ApiResponse(
            statusCode: 200,
            body: jsonEncode({
              ...sampleMessageJson,
              'conversationId': 'conv-1',
              'clientMessageId': 'stable',
              ...change,
            }),
          ),
        ),
      );
      await expectLater(
        repo.sendMessage(
          'conv-1',
          clientMessageId: 'stable',
          content: 'Bản nháp',
        ),
        throwsA(isA<ParseFailure>()),
      );
    }
  });
  test(
    'edit and reaction acknowledgments cannot replace a different message',
    () async {
      final repo = LiveDirectMessageRepository(
        _client(
          (r) async => ApiResponse(
            statusCode: 200,
            body: jsonEncode({...sampleMessageJson, 'id': 'different-message'}),
          ),
        ),
      );
      await expectLater(
        repo.editMessage('expected-message', 'Bản sửa'),
        throwsA(isA<ParseFailure>()),
      );
      await expectLater(
        repo.reactToMessage('expected-message', '👍'),
        throwsA(isA<ParseFailure>()),
      );
    },
  );
  test(
    'private image completion must acknowledge the presigned asset',
    () async {
      final media = DirectMessageMediaRepository(
        _client(
          (r) async => ApiResponse(
            statusCode: 200,
            body: jsonEncode(
              r.path.endsWith('/presign')
                  ? {
                      'assetId': 'expected-asset',
                      'uploadUrl': 'https://example.org/upload',
                      'headers': {'content-type': 'image/png'},
                    }
                  : {'assetId': 'different-asset', 'status': 'READY'},
            ),
          ),
        ),
        upload: (url, file, headers) async {},
      );
      await expectLater(
        media.upload(
          DmUploadFile(
            name: 'test.png',
            mime: 'image/png',
            length: 4,
            openRead: () => Stream.value([1, 2, 3, 4]),
          ),
        ),
        throwsA(isA<ParseFailure>()),
      );
    },
  );
  test('unsupported private image types are rejected before requesting upload credentials', () async {
    var calls = 0;
    final media = DirectMessageMediaRepository(
      _client((r) async {
        calls++;
        return ApiResponse(statusCode: 200, body: '{}');
      }),
    );
    await expectLater(
      media.upload(
        DmUploadFile(
          name: 'test.avif',
          mime: 'image/avif',
          length: 4,
          openRead: () => Stream.value([1, 2, 3, 4]),
        ),
      ),
      throwsA(isA<ParseFailure>()),
    );
    expect(calls, 0);
  });
  for (final empty in ['{}', '{"ok":false}']) {
    test(
      'an incomplete DM acknowledgment cannot confirm any write: $empty',
      () async {
        final repo = LiveDirectMessageRepository(
          ApiClient(
            transport: (r) async => ApiResponse(statusCode: 200, body: empty),
            throttleInterval: Duration.zero,
            hostKey: Object(),
          ),
        );
        final mutations = <Future<Object?> Function()>[
          () => repo.sendMessage(
            'conversation',
            clientMessageId: 'stable',
            content: 'Giữ bản nháp',
          ),
          () => repo.editMessage('message', 'Giữ bản sửa'),
          () => repo.reactToMessage('message', '👍'),
          () => repo.reactToMessage('message', '👍', remove: true),
          () => repo.deleteMessage('message'),
          () => repo.acceptRequest('conversation'),
          () => repo.declineRequest('conversation'),
          () => repo.deleteConversation('conversation'),
          () => repo.blockUser('peer'),
          () => repo.unblockUser('peer'),
          () => repo.markRead('conversation'),
        ];
        for (final mutation in mutations) {
          await expectLater(mutation(), throwsA(isA<ParseFailure>()));
        }
      },
    );
  }
}

ApiClient _client(ApiTransport transport) => ApiClient(
  transport: transport,
  throttleInterval: Duration.zero,
  hostKey: Object(),
);
