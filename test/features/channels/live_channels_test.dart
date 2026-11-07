import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vnlfsocialapp/src/app/providers.dart';
import 'package:vnlfsocialapp/src/domain/models.dart';
import 'package:vnlfsocialapp/src/core/api_client.dart';
import 'package:vnlfsocialapp/src/features/channels/data/live_channel_repository.dart';
import 'package:vnlfsocialapp/src/features/channels/domain/channel_models.dart';
import 'package:vnlfsocialapp/src/features/channels/domain/channel_repository.dart';
import 'package:vnlfsocialapp/src/features/channels/presentation/live_channel_state.dart';

void main() {
  test(
    'directory and history map confirmed fields and preserve cursor',
    () async {
      final requests = <ApiRequest>[];
      final repo = LiveChannelRepository(
        client((request) async {
          requests.add(request);
          return response(
            request.path == '/api/v1/channels'
                ? {
                    'items': [channelJson],
                  }
                : {
                    'items': [messageJson],
                    'nextCursor': 'before + tiếng Việt',
                  },
          );
        }),
      );
      final channels = await repo.getChannels();
      expect(channels.single.id, 'channel-id');
      expect(channels.single.slug, 'linux');
      expect(channels.single.unreadCount, 3);
      expect(channels.single.canPost('MEMBER'), isFalse);
      expect(channels.single.canPost('MODERATOR'), isTrue);
      expect(channels.single.canPost('future-role'), isFalse);
      final page = await repo.getMessages(
        'channel/id',
        cursor: 'before + tiếng Việt',
      );
      expect(requests.last.path, '/api/v1/channels/channel%2Fid/messages');
      expect(requests.last.query, {
        'limit': '50',
        'cursor': 'before + tiếng Việt',
      });
      expect(page.nextCursor, 'before + tiếng Việt');
      final message = page.items.single;
      expect(message.content, 'Tiếng Việt: ặ ữ ờ ẫ ệ');
      expect(message.author.displayName, 'Người thử');
      expect(message.replyTo?.content, 'Một tin nhắn');
      expect(message.reactions.single.viewerReacted, isTrue);
      expect(
        message.attachments.single.url,
        'https://example.invalid/image.png',
      );
    },
  );

  test(
    'mutations emit only confirmed payloads and accept empty confirmations',
    () async {
      final requests = <ApiRequest>[];
      final repo = LiveChannelRepository(
        client((request) async {
          requests.add(request);
          return ApiResponse(statusCode: 204, body: '');
        }),
      );
      await repo.send(
        'channel/id',
        clientMessageId: 'uuid',
        content: 'Nội dung',
        replyToId: 'parent',
      );
      await repo.edit('message/id', 'Đã sửa');
      await repo.delete('message/id');
      await repo.react('message/id', '👍');
      expect(requests.map((r) => '${r.method} ${r.path}'), [
        'POST /api/v1/channels/channel%2Fid/messages',
        'PATCH /api/v1/messages/message%2Fid',
        'DELETE /api/v1/messages/message%2Fid',
        'POST /api/v1/messages/message%2Fid/reactions',
      ]);
      expect(jsonDecode(requests[0].body!), {
        'clientMessageId': 'uuid',
        'content': 'Nội dung',
        'replyToId': 'parent',
      });
      expect(jsonDecode(requests[1].body!), {'content': 'Đã sửa'});
      expect(requests[2].body, isNull);
      expect(jsonDecode(requests[3].body!), {'emoji': '👍'});
    },
  );

  test(
    'selected reaction is removed through the observed DELETE endpoint',
    () async {
      final requests = <ApiRequest>[];
      final repository = LiveChannelRepository(
        client((request) async {
          requests.add(request);
          if (request.method == 'GET') {
            return response({
              'items': [messageJson],
            });
          }
          return ApiResponse(statusCode: 204, body: '');
        }),
      );
      final controller = ChannelTimelineController(repository, 'channel');
      addTearDown(controller.dispose);
      await controller.load();
      await controller.react('message', '👍');
      final writes = requests
          .where((request) => request.method != 'GET')
          .toList();
      expect(writes.single.method, 'DELETE');
      expect(
        writes.single.path,
        '/api/v1/messages/message/reactions/%F0%9F%91%8D',
      );
    },
  );

  test('private attachments retain the authenticated download path', () async {
    final repository = LiveChannelRepository(
      client(
        (_) async => response({
          'items': [
            {
              ...messageJson,
              'attachments': [
                {
                  'id': 'private-image',
                  'url': null,
                  'mime': 'image/png',
                  'downloadPath': '/api/v1/assets/private-image/download',
                },
              ],
            },
          ],
        }),
      ),
    );
    final page = await repository.getMessages('channel');
    expect(
      page.items.single.attachments.single.downloadPath,
      '/api/v1/assets/private-image/download',
    );
  });

  test('failed send is not retried by the transport', () async {
    var calls = 0;
    final repo = LiveChannelRepository(
      client((request) async {
        calls++;
        return ApiResponse(statusCode: 503, body: '{}');
      }),
    );
    await expectLater(
      repo.send('channel', clientMessageId: 'uuid', content: 'draft'),
      throwsA(isA<HttpFailure>()),
    );
    expect(calls, 1);
  });

  test('malformed identity and list shapes become typed failures', () async {
    final repo = LiveChannelRepository(
      client(
        (request) async => response({
          'items': [
            {'id': ''},
          ],
        }),
      ),
    );
    await expectLater(repo.getChannels(), throwsA(isA<ParseFailure>()));
    final wrongList = LiveChannelRepository(
      client((request) async => response({'items': 'wrong'})),
    );
    await expectLater(
      wrongList.getMessages('channel'),
      throwsA(isA<ParseFailure>()),
    );
  });

  test('a send is pending until confirmed and cannot submit twice', () async {
    final repo = ControlledRepository();
    final controller = ChannelTimelineController(repo, 'channel');
    addTearDown(controller.dispose);
    await controller.load();
    controller.updateDraft('  Giữ nội dung  ');
    final sending = controller.send();
    await controller.send();
    expect(repo.sends, hasLength(1));
    expect(repo.sends.single.content, 'Giữ nội dung');
    expect(
      RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      ).hasMatch(repo.sends.single.id),
      isTrue,
    );
    expect(controller.state.draft, '  Giữ nội dung  ');
    expect(controller.state.messages, isEmpty);
    repo.sendResult.complete();
    await sending;
    expect(controller.state.draft, isEmpty);
    expect(
      controller.state.messages,
      isEmpty,
    ); // no synthetic confirmation bubble
    expect(controller.state.sending, isFalse);
  });

  test(
    'send failure preserves draft and reply without optimistic messages',
    () async {
      final repo = ControlledRepository();
      final controller = ChannelTimelineController(repo, 'channel');
      addTearDown(controller.dispose);
      await controller.load();
      controller.updateDraft('Thử lại sau');
      controller.replyTo(message);
      final sending = controller.send();
      repo.sendResult.completeError(const HttpFailure(403));
      await sending;
      expect(controller.state.draft, 'Thử lại sau');
      expect(controller.state.reply?.id, 'message');
      expect(controller.state.operationFailure, isA<HttpFailure>());
      expect(controller.state.messages, isEmpty);
    },
  );

  test(
    'older pages deduplicate messages and refresh failures retain history',
    () async {
      final repo = ControlledRepository()
        ..pages.add(ChannelMessagePage(items: [message], nextCursor: 'older'))
        ..pages.add(
          ChannelMessagePage(items: [message, older], nextCursor: null),
        );
      final controller = ChannelTimelineController(repo, 'channel');
      addTearDown(controller.dispose);
      await controller.load();
      await controller.loadOlder();
      expect(controller.state.messages.map((m) => m.id), ['older', 'message']);
      expect(controller.state.nextCursor, isNull);
      repo.failure = const HttpFailure(401);
      await controller.refresh();
      expect(controller.state.messages, hasLength(2));
      expect(controller.state.failure, isA<HttpFailure>());
    },
  );
  test('confirmed send with failed history read clears draft without inviting resend', () async {
    final repo = ControlledRepository();
    final controller = ChannelTimelineController(repo, 'channel');
    addTearDown(controller.dispose);
    await controller.load();
    controller.updateDraft('Đã gửi');
    final sending = controller.send();
    repo.failure = const TransportFailure();
    repo.sendResult.complete();
    await sending;
    expect(controller.state.draft, isEmpty);
    expect(controller.state.operationFailure, isNull);
    expect(controller.state.confirmedRefreshFailed, isTrue);
    expect(repo.sends, hasLength(1));
  });

  test(
    'account change cancels pending channel state and hides prior drafts',
    () async {
      final repo = ControlledRepository();
      final container = ProviderContainer(
        overrides: [liveChannelRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        channelTimelineProvider('channel'),
        (_, next) {},
      );
      addTearDown(subscription.close);
      final previous = container.read(
        channelTimelineProvider('channel').notifier,
      );
      await Future<void>.delayed(Duration.zero);
      previous.updateDraft('Bản nháp riêng');
      final pending = previous.send();
      container.read(sessionStateProvider.notifier).state = const Session(
        userId: 'next',
        displayName: 'Khác',
        role: 'MEMBER',
      );
      final current = container.read(
        channelTimelineProvider('channel').notifier,
      );
      expect(identical(previous, current), isFalse);
      repo.sendResult.complete();
      await pending;
      expect(current.state.draft, isEmpty);
      expect(current.state.messages, isEmpty);
      expect(current.state.sending, isFalse);
    },
  );

  test('delete removes a message only after confirmation even when history omits it', () async {
    final repo = ControlledRepository()
      ..pages.add(ChannelMessagePage(items: [message]));
    final controller = ChannelTimelineController(repo, 'channel');
    addTearDown(controller.dispose);
    await controller.load();
    final deleting = controller.delete('message');
    expect(controller.state.messages, hasLength(1));
    repo.actionResult.complete();
    await deleting;
    expect(controller.state.messages, isEmpty);
  });

  test('message action prevents overlapping sends and failures leave history unchanged', () async {
    final repo = ControlledRepository()
      ..pages.add(ChannelMessagePage(items: [message]));
    final controller = ChannelTimelineController(repo, 'channel');
    addTearDown(controller.dispose);
    await controller.load();
    controller.updateDraft('Nội dung');
    final reacting = controller.react('message', '👍');
    final sending = controller.send();
    expect(repo.sends, isEmpty);
    await sending;
    repo.actionResult.completeError(const HttpFailure(403));
    await reacting;
    expect(controller.state.messages.single.content, 'mới');
    expect(controller.state.draft, 'Nội dung');
    expect(controller.state.operationFailure, isA<HttpFailure>());
    expect(controller.state.busyMessageId, isNull);
  });
}

ApiClient client(ApiTransport transport) => ApiClient(
  transport: transport,
  throttleInterval: Duration.zero,
  cacheDuration: Duration.zero,
  hostKey: Object(),
);
ApiResponse response(Map<String, dynamic> json) =>
    ApiResponse(statusCode: 200, body: jsonEncode(json));

const channelJson = <String, dynamic>{
  'id': 'channel-id',
  'slug': 'linux',
  'name': 'Linux',
  'description': 'Hỏi đáp',
  'type': 'TEXT',
  'position': 1,
  'isArchived': false,
  'minRoleToView': 'MEMBER',
  'minRoleToPost': 'MODERATOR',
  'slowModeSeconds': 10,
  'unreadCount': 3,
  'unreadAttentionCount': 1,
  'lastReadMessageId': null,
  'firstUnreadMessageId': null,
  'lastMessageId': null,
  'lastMessageAt': null,
  'future': true,
};
const messageJson = <String, dynamic>{
  'id': 'message',
  'channelId': 'channel-id',
  'conversationId': null,
  'authorId': 'author',
  'clientMessageId': 'client-id',
  'replyToMessageId': 'parent',
  'replyTo': {
    'id': 'parent',
    'authorId': 'other',
    'name': 'Bạn khác',
    'username': 'khac',
    'content': 'Một tin nhắn',
    'deleted': false,
  },
  'mentions': <Object?>[],
  'attentionUserIds': <Object?>[],
  'content': 'Tiếng Việt: ặ ữ ờ ẫ ệ',
  'editedAt': null,
  'deletedAt': null,
  'createdAt': '2026-11-05T10:00:00Z',
  'author': {
    'id': 'author',
    'username': 'thu',
    'displayName': 'Người thử',
    'avatarUrl': null,
    'style': null,
  },
  'reactions': [
    {'emoji': '👍', 'count': 2, 'viewerReacted': true},
  ],
  'attachments': [
    {
      'id': 'asset',
      'mime': 'image/png',
      'size': 123,
      'width': 20,
      'height': 20,
      'url': 'https://example.invalid/image.png',
    },
  ],
  'gif': null,
  'poll': null,
};
final message = ChannelMessage(
  id: 'message',
  author: const ChannelAuthor(id: 'me', username: 'toi', displayName: 'Tôi'),
  content: 'mới',
  createdAt: DateTime.utc(2026, 11, 5, 10),
);
final older = ChannelMessage(
  id: 'older',
  author: const ChannelAuthor(id: 'other', username: 'ban', displayName: 'Bạn'),
  content: 'cũ',
  createdAt: DateTime.utc(2026, 11, 5, 9),
);

class ControlledRepository implements ChannelRepository {
  final sendResult = Completer<void>();
  final actionResult = Completer<void>();
  final sends = <({String id, String content})>[];
  final pages = <ChannelMessagePage>[];
  AppFailure? failure;
  @override
  Future<List<ChatChannel>> getChannels() async => [];
  @override
  Future<ChannelMessagePage> getMessages(String id, {String? cursor}) async {
    if (failure case final f?) throw f;
    return pages.isEmpty ? ChannelMessagePage(items: []) : pages.removeAt(0);
  }

  @override
  Future<void> send(
    String channelId, {
    required String clientMessageId,
    required String content,
    String? replyToId,
  }) {
    sends.add((id: clientMessageId, content: content));
    return sendResult.future;
  }

  @override
  Future<void> edit(String messageId, String content) => actionResult.future;
  @override
  Future<void> delete(String messageId) => actionResult.future;
  @override
  Future<void> react(String messageId, String emoji, {bool remove = false}) =>
      actionResult.future;
}
