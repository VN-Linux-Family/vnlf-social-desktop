import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/core/api_client.dart';
import 'package:vnlfsocialapp/src/features/direct_messages/data/direct_message_media_repository.dart';
import 'package:vnlfsocialapp/src/features/direct_messages/data/live_direct_message_repository.dart';
import 'package:vnlfsocialapp/src/features/direct_messages/domain/direct_message_models.dart';

void main() {
  test('inbox and message history parse confirmed fields, blocked peer redaction, and poll projection', () async {
    final requests = <ApiRequest>[];
    final repo = LiveDirectMessageRepository(
      _client((request) async {
        requests.add(request);
        if (request.path == '/api/v1/dm/conversations') {
          return _jsonResponse(<String, dynamic>{
            'items': <Map<String, dynamic>>[sampleConversationJson],
          });
        }
        return _jsonResponse(<String, dynamic>{
          'items': <Map<String, dynamic>>[
            sampleMessageJson,
            blockedPeerMessageJson,
          ],
          'nextCursor': 'cursor + tiếng Việt',
          'viewerState': 'ACTIVE',
        });
      }),
    );

    final conversations = await repo.getConversations();
    expect(conversations, hasLength(1));
    final conv = conversations.single;
    expect(conv.id, 'conv-1');
    expect(conv.status, DmConversationStatus.active);
    expect(conv.viewerState, DmViewerState.active);
    expect(conv.canSend, isTrue);
    expect(conv.unreadCount, 2);
    expect(conv.peer.displayName, 'Người thử nghiệm');
    expect(conv.peer.isOnline, isTrue);

    final page = await repo.getMessages(
      'conv/1',
      cursor: 'cursor + tiếng Việt',
    );
    expect(requests.last.path, '/api/v1/dm/conversations/conv%2F1/messages');
    expect(requests.last.query, <String, String>{
      'limit': '50',
      'cursor': 'cursor + tiếng Việt',
    });
    expect(page.nextCursor, 'cursor + tiếng Việt');
    expect(page.viewerState, DmViewerState.active);
    expect(page.items, hasLength(2));

    final first = page.items.first;
    expect(first.content, 'Tiếng Việt: ặ ữ ờ ẫ ệ');
    expect(first.replyTo?.name, 'Bạn đọc');
    expect(
      first.replyTo?.previewAttachment?.downloadPath,
      '/api/v1/assets/reply-asset/download',
    );
    expect(first.reactions.single.viewerReacted, isTrue);
    expect(
      first.attachments.single.downloadPath,
      '/api/v1/assets/private-asset/download',
    );
    expect(first.hasPoll, isTrue);
    expect(first.poll?['id'], 'poll-1');
    expect(first.poll?['viewerOptionId'], 'opt-a');

    // Blocked peer message omits nested author.id in dm.ts:97 while keeping top-level authorId.
    final redacted = page.items.last;
    expect(redacted.authorId, 'peer-blocked');
    expect(redacted.author.id, 'peer-blocked');
    expect(redacted.author.displayName, 'Người bạn đã chặn');
  });

  test('mutations emit confirmed payloads and require documented acknowledgments', () async {
    final requests = <ApiRequest>[];
    final repo = LiveDirectMessageRepository(
      _client((request) async {
        requests.add(request);
        if (request.path.endsWith('/report')) {
          return _jsonResponse(<String, dynamic>{'reportId': 'rep-99'});
        }
        if (request.path == '/api/v1/dm/conversations' &&
            request.method == 'POST') {
          return _jsonResponse(<String, dynamic>{
            'conversationId': 'conv-new',
            'status': 'REQUESTED',
          });
        }
        if (request.path.endsWith('/read')) {
          return _jsonResponse(<String, dynamic>{
            'ok': true,
            'changed': true,
            'lastReadMessageId': 'msg-1',
          });
        }
        if (request.path.endsWith('/messages') ||
            request.path.contains('/reactions') ||
            request.method == 'PATCH') {
          final body = request.body == null
              ? <String, dynamic>{}
              : jsonDecode(request.body!) as Map<String, dynamic>;
          final sending = request.path.endsWith('/messages');
          return _jsonResponse({
            ...sampleMessageJson,
            if (sending)
              'conversationId': Uri.decodeComponent(request.path.split('/')[5]),
            if (sending) 'clientMessageId': body['clientMessageId'],
            if (!sending) 'id': Uri.decodeComponent(request.path.split('/')[4]),
          });
        }
        return _jsonResponse({'ok': true});
      }),
    );

    final opened = await repo.openOrRequestConversation('user-2');
    expect(opened.conversationId, 'conv-new');
    expect(opened.status, DmConversationStatus.requested);

    await repo.acceptRequest('conv/1');
    await repo.declineRequest('conv/1');
    await repo.deleteConversation('conv/1');
    await repo.sendMessage(
      'conv/1',
      clientMessageId: 'client-uuid',
      content: '  Xin chào   \n\n\n\nBạn  ',
      replyToId: 'msg-0',
      attachmentIds: const <String>['asset-1'],
    );
    final receipt = await repo.markRead('conv/1', lastReadMessageId: 'msg-1');
    expect(receipt.changed, isTrue);
    expect(receipt.lastReadMessageId, 'msg-1');

    await repo.editMessage('msg/1', 'Đã chỉnh sửa');
    await repo.deleteMessage('msg/1');
    await repo.reactToMessage('msg/1', '❤️');
    await repo.reactToMessage('msg/1', '❤️', remove: true);
    final reportId = await repo.reportConversation(
      'conv/1',
      reason: DmReportReason.spam,
      detail: 'Tin nhắn quảng cáo',
    );
    expect(reportId, 'rep-99');
    await repo.blockUser('peer/1');
    await repo.unblockUser('peer/1');

    expect(requests.map((r) => '${r.method} ${r.path}').toList(), <String>[
      'POST /api/v1/dm/conversations',
      'POST /api/v1/dm/conversations/conv%2F1/accept',
      'POST /api/v1/dm/conversations/conv%2F1/decline',
      'DELETE /api/v1/dm/conversations/conv%2F1',
      'POST /api/v1/dm/conversations/conv%2F1/messages',
      'POST /api/v1/dm/conversations/conv%2F1/read',
      'PATCH /api/v1/messages/msg%2F1',
      'DELETE /api/v1/messages/msg%2F1',
      'POST /api/v1/messages/msg%2F1/reactions',
      'DELETE /api/v1/messages/msg%2F1/reactions/${Uri.encodeComponent('❤️')}',
      'POST /api/v1/dm/conversations/conv%2F1/report',
      'POST /api/v1/users/peer%2F1/block',
      'DELETE /api/v1/users/peer%2F1/block',
    ]);

    expect(jsonDecode(requests[4].body!), <String, dynamic>{
      'clientMessageId': 'client-uuid',
      'content': 'Xin chào   \n\n\nBạn',
      'replyToId': 'msg-0',
      'attachmentIds': <String>['asset-1'],
    });
    expect(jsonDecode(requests[10].body!), <String, dynamic>{
      'reason': 'SPAM',
      'detail': 'Tin nhắn quảng cáo',
    });
  });

  test(
    'failed non-idempotent DM send is never automatically retried',
    () async {
      var calls = 0;
      final repo = LiveDirectMessageRepository(
        _client((_) async {
          calls++;
          return ApiResponse(
            statusCode: 503,
            body: '{"code":"DM_REQUEST_PENDING"}',
          );
        }),
      );

      await expectLater(
        repo.sendMessage(
          'conv-1',
          clientMessageId: 'uuid-1',
          content: 'Thử gửi',
        ),
        throwsA(
          isA<HttpFailure>()
              .having((f) => f.statusCode, 'statusCode', 503)
              .having((f) => f.code, 'code', 'DM_REQUEST_PENDING'),
        ),
      );
      expect(calls, 1);
    },
  );

  test('private media resolver validates scoped downloadPath and upload strips session credentials', () async {
    final apiRequests = <ApiRequest>[];
    Uri? uploadedUri;
    Map<String, String>? uploadedHeaders;

    final mediaRepo = DirectMessageMediaRepository(
      _client((request) async {
        apiRequests.add(request);
        if (request.path == '/api/v1/assets/asset_1/download') {
          return _jsonResponse(<String, dynamic>{
            'assetId': 'asset_1',
            'downloadUrl': 'https://cdn.example.invalid/signed/asset_1.png',
            'expiresIn': 300,
          });
        }
        if (request.path == '/api/v1/dm/assets/presign') {
          return _jsonResponse(<String, dynamic>{
            'assetId': 'asset_2',
            'uploadUrl': 'https://r2.example.invalid/upload/asset_2',
            'expiresIn': 600,
            'headers': <String, dynamic>{
              'content-type': 'image/png',
              'Cookie': 'should_be_stripped=1',
              'Authorization': 'Bearer secret',
              'X-CSRF-Token': 'csrf',
            },
          });
        }
        return _jsonResponse(<String, dynamic>{
          'assetId': 'asset_2',
          'status': 'READY',
          'url': null,
        });
      }),
      upload: (url, file, headers) async {
        uploadedUri = url;
        uploadedHeaders = headers;
      },
    );

    final resolved = await mediaRepo.resolve('/api/v1/assets/asset_1/download');
    expect(
      resolved.toString(),
      'https://cdn.example.invalid/signed/asset_1.png',
    );

    // Untrusted paths are rejected before hitting transport.
    expect(
      () => mediaRepo.resolve('https://evil.example.invalid/steal'),
      throwsA(isA<ParseFailure>()),
    );
    expect(apiRequests, hasLength(1));

    final uploaded = await mediaRepo.upload(
      DmUploadFile(
        name: 'screenshot.png',
        mime: 'image/png',
        length: 4,
        openRead: () => Stream<List<int>>.value(const <int>[1, 2, 3, 4]),
      ),
    );
    expect(uploaded.assetId, 'asset_2');
    expect(uploaded.status, 'READY');
    expect(uploadedUri.toString(), 'https://r2.example.invalid/upload/asset_2');
    expect(uploadedHeaders, <String, String>{'content-type': 'image/png'});
  });

  test('malformed responses and invalid inputs become ParseFailure', () async {
    final repo = LiveDirectMessageRepository(
      _client((_) async => _jsonResponse(<String, dynamic>{'items': 'bad'})),
    );
    await expectLater(repo.getConversations(), throwsA(isA<ParseFailure>()));
    await expectLater(
      Future.sync(() => repo.searchMessages('conv-1', query: 'a')),
      throwsA(isA<ParseFailure>()),
    );
    await expectLater(
      Future.sync(
        () => repo.sendMessage('conv-1', clientMessageId: 'id', content: '   '),
      ),
      throwsA(isA<ParseFailure>()),
    );
  });
}

ApiClient _client(ApiTransport transport) => ApiClient(
  transport: transport,
  throttleInterval: Duration.zero,
  cacheDuration: Duration.zero,
  hostKey: Object(),
);

ApiResponse _jsonResponse(Map<String, dynamic> json) =>
    ApiResponse(statusCode: 200, body: jsonEncode(json));

const Map<String, dynamic> sampleConversationJson = <String, dynamic>{
  'id': 'conv-1',
  'status': 'ACTIVE',
  'viewerState': 'ACTIVE',
  'canSend': true,
  'unreadCount': 2,
  'firstUnreadMessageId': 'msg-1',
  'lastReadMessageId': null,
  'peerLastReadMessageId': 'msg-1',
  'lastMessageId': 'msg-1',
  'lastMessage': 'Tiếng Việt: ặ ữ ờ ẫ ệ',
  'updatedAt': '2026-11-05T10:00:00Z',
  'peer': <String, dynamic>{
    'id': 'peer-1',
    'username': 'nguoithu',
    'displayName': 'Người thử nghiệm',
    'avatarUrl': null,
    'style': null,
    'presence': 'ONLINE',
  },
};

const Map<String, dynamic> sampleMessageJson = <String, dynamic>{
  'id': 'msg-1',
  'conversationId': 'conv-1',
  'authorId': 'peer-1',
  'clientMessageId': 'client-1',
  'replyToMessageId': 'msg-0',
  'replyTo': <String, dynamic>{
    'id': 'msg-0',
    'authorId': 'me',
    'name': 'Bạn đọc',
    'username': 'bandoc',
    'content': 'Tin nhắn gốc',
    'deleted': false,
    'hasGif': false,
    'previewAttachment': <String, dynamic>{
      'id': 'reply-asset',
      'url': null,
      'downloadPath': '/api/v1/assets/reply-asset/download',
      'mime': 'image/png',
    },
  },
  'mentions': <Object?>[],
  'attentionUserIds': <Object?>[],
  'content': 'Tiếng Việt: ặ ữ ờ ẫ ệ',
  'editedAt': null,
  'deletedAt': null,
  'createdAt': '2026-11-05T10:00:00Z',
  'author': <String, dynamic>{
    'id': 'peer-1',
    'username': 'nguoithu',
    'displayName': 'Người thử nghiệm',
    'avatarUrl': null,
    'style': null,
  },
  'reactions': <Map<String, dynamic>>[
    <String, dynamic>{'emoji': '❤️', 'count': 1, 'viewerReacted': true},
  ],
  'attachments': <Map<String, dynamic>>[
    <String, dynamic>{
      'id': 'private-asset',
      'mime': 'image/png',
      'size': 2048,
      'width': 100,
      'height': 80,
      'url': null,
      'downloadPath': '/api/v1/assets/private-asset/download',
    },
  ],
  'gif': null,
  'poll': <String, dynamic>{
    'id': 'poll-1',
    'question': 'Bản phân phối nào?',
    'viewerOptionId': 'opt-a',
  },
};

const Map<String, dynamic> blockedPeerMessageJson = <String, dynamic>{
  'id': 'msg-blocked',
  'conversationId': 'conv-1',
  'authorId': 'peer-blocked',
  'clientMessageId': 'client-blocked',
  'content': 'Tin nhắn cũ trước khi chặn',
  'createdAt': '2026-11-05T09:00:00Z',
  'author': <String, dynamic>{
    'username': '',
    'displayName': 'Người bạn đã chặn',
  },
  'reactions': <Object?>[],
  'attachments': <Object?>[],
};
