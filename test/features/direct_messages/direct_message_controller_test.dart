import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/app/providers.dart';
import 'package:vnlfsocialapp/src/domain/models.dart';
import 'package:vnlfsocialapp/src/features/direct_messages/domain/direct_message_models.dart';
import 'package:vnlfsocialapp/src/features/direct_messages/domain/direct_message_repository.dart';
import 'package:vnlfsocialapp/src/features/direct_messages/presentation/direct_message_state.dart';

void main() {
  test(
    'send is single-flight, preserves draft/reply/clientMessageId on failure, and clears after confirmation',
    () async {
      final repo = ControlledDmRepository();
      final controller = DmTimelineController(
        repo,
        conversationId: 'conv-1',
      );
      addTearDown(controller.dispose);
      await controller.load();

      controller.updateDraft('  Giữ bản nháp khi lỗi  ');
      controller.setReplyTarget(sampleDmMessage);

      // Start first send; overlapping send must be ignored.
      final firstSend = controller.send();
      await controller.send();
      expect(repo.sends, hasLength(1));
      expect(repo.sends.single.content, 'Giữ bản nháp khi lỗi');
      final firstClientId = repo.sends.single.clientMessageId;
      expect(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ).hasMatch(firstClientId),
        isTrue,
      );

      // Fail first attempt: draft, replyTarget, and clientMessageId are retained.
      repo.sendCompleter.completeError(
        const HttpFailure(503, code: 'DM_REQUEST_PENDING'),
      );
      await firstSend;
      expect(controller.state.draft, '  Giữ bản nháp khi lỗi  ');
      expect(controller.state.replyTarget?.id, sampleDmMessage.id);
      expect(controller.state.operationFailure, isA<HttpFailure>());
      expect(controller.state.sending, isFalse);

      // Manual retry reuses the same clientMessageId for server deduplication.
      repo.sendCompleter = Completer<DmMessage?>();
      final retrySend = controller.send();
      expect(repo.sends, hasLength(2));
      expect(repo.sends.last.clientMessageId, firstClientId);
      repo.sendCompleter.complete(null);
      await retrySend;

      expect(controller.state.draft, isEmpty);
      expect(controller.state.replyTarget, isNull);
      expect(controller.state.operationFailure, isNull);
      expect(controller.state.sending, isFalse);
    },
  );

  test(
    'confirmed send with failed follow-up refresh clears draft and sets confirmedRefreshFailed',
    () async {
      final repo = ControlledDmRepository();
      final controller = DmTimelineController(
        repo,
        conversationId: 'conv-1',
      );
      addTearDown(controller.dispose);
      await controller.load();

      controller.updateDraft('Tin nhắn đã gửi');
      final sending = controller.send();
      repo.readFailure = const TransportFailure();
      repo.sendCompleter.complete(null);
      await sending;

      expect(controller.state.draft, isEmpty);
      expect(controller.state.operationFailure, isNull);
      expect(controller.state.confirmedRefreshFailed, isTrue);
      expect(repo.sends, hasLength(1));
    },
  );

  test(
    'account switch cancels pending DM state, hides prior drafts, and resets selection',
    () async {
      final repo = ControlledDmRepository();
      final container = ProviderContainer(
        overrides: <Override>[
          directMessageRepositoryProvider.overrideWithValue(repo),
          sessionStateProvider.overrideWith(
            (ref) => const Session(
              userId: 'user-a',
              displayName: 'Người A',
              role: 'MEMBER',
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final sub = container.listen(
        dmTimelineProvider('conv-1'),
        (_, _) {},
      );
      addTearDown(sub.close);

      container.read(selectedDmConversationIdProvider.notifier).state =
          'conv-1';
      final previous = container.read(dmTimelineProvider('conv-1').notifier);
      await Future<void>.delayed(Duration.zero);

      previous.updateDraft('Bản nháp mật của A');
      final pendingSend = previous.send();

      // Switch to user-b while user-a's send is still in flight.
      container.read(sessionStateProvider.notifier).state = const Session(
        userId: 'user-b',
        displayName: 'Người B',
        role: 'MEMBER',
      );

      expect(container.read(selectedDmConversationIdProvider), isNull);
      final current = container.read(dmTimelineProvider('conv-1').notifier);
      expect(identical(previous, current), isFalse);
      expect(current.state.draft, isEmpty);

      // Completing user-a's in-flight request does not leak into user-b's timeline.
      repo.sendCompleter.complete(
        DmMessage(
          id: 'leaked-msg',
          authorId: 'user-a',
          author: const Author(
            id: 'user-a',
            username: 'usera',
            displayName: 'Người A',
          ),
          content: 'Bản nháp mật của A',
        ),
      );
      await pendingSend;

      expect(current.state.draft, isEmpty);
      expect(
        current.state.messages.where((m) => m.id == 'leaked-msg'),
        isEmpty,
      );
    },
  );

  test(
    'realtime poll update preserves recipient viewerOptionId instead of adopting sender choice',
    () async {
      final initialWithPoll = DmMessage(
        id: 'msg-poll',
        authorId: 'peer-1',
        author: const Author(
          id: 'peer-1',
          username: 'nguoithu',
          displayName: 'Người thử nghiệm',
        ),
        content: 'Bình chọn distro',
        poll: const <String, dynamic>{
          'id': 'poll-1',
          'totalVotes': 1,
          'viewerOptionId': 'opt-recipient',
        },
        createdAt: DateTime.utc(2026, 11, 5, 10),
      );
      final repo = ControlledDmRepository()
        ..pages.add(DmMessagePage(items: <DmMessage>[initialWithPoll]));
      final controller = DmTimelineController(
        repo,
        conversationId: 'conv-1',
      );
      addTearDown(controller.dispose);
      await controller.load();

      // Incoming broadcast from sender has sender's viewerOptionId ('opt-sender').
      final incomingBroadcast = DmMessage(
        id: 'msg-poll',
        authorId: 'peer-1',
        author: const Author(
          id: 'peer-1',
          username: 'nguoithu',
          displayName: 'Người thử nghiệm',
        ),
        content: 'Bình chọn distro',
        poll: const <String, dynamic>{
          'id': 'poll-1',
          'totalVotes': 2,
          'viewerOptionId': 'opt-sender',
        },
        createdAt: DateTime.utc(2026, 11, 5, 10),
      );

      controller.applyRealtimeMessage(incomingBroadcast);

      final updatedPoll = controller.state.messages.single.poll!;
      expect(updatedPoll['totalVotes'], 2);
      expect(updatedPoll['viewerOptionId'], 'opt-recipient');
    },
  );

  test(
    'message action lock prevents concurrent sends and marks deleted message on confirmation',
    () async {
      final repo = ControlledDmRepository()
        ..pages.add(DmMessagePage(items: <DmMessage>[sampleDmMessage]));
      final controller = DmTimelineController(
        repo,
        conversationId: 'conv-1',
      );
      addTearDown(controller.dispose);
      await controller.load();

      controller.updateDraft('Đang chờ');
      final reacting = controller.toggleReaction(sampleDmMessage.id, '❤️');
      expect(controller.state.busyMessageId, sampleDmMessage.id);

      // Send attempted while message mutation is busy must not fire.
      await controller.send();
      expect(repo.sends, isEmpty);

      repo.mutationCompleter.complete(null);
      await reacting;
      expect(controller.state.busyMessageId, isNull);

      // Delete marks message deleted locally even before history omits it.
      repo.mutationCompleter = Completer<DmMessage?>();
      final deleting = controller.deleteMessage(sampleDmMessage.id);
      repo.mutationCompleter.complete(null);
      await deleting;
      expect(controller.state.messages.single.isDeleted, isTrue);
    },
  );
}

final DmMessage sampleDmMessage = DmMessage(
  id: 'msg-1',
  conversationId: 'conv-1',
  authorId: 'test-user',
  author: const Author(
    id: 'test-user',
    username: 'toi',
    displayName: 'Tôi',
  ),
  content: 'Xin chào cộng đồng Linux',
  createdAt: DateTime.utc(2026, 11, 5, 10),
  reactions: const <DmReaction>[
    DmReaction(emoji: '❤️', count: 1, viewerReacted: true),
  ],
);

const DmConversation sampleConversation = DmConversation(
  id: 'conv-1',
  status: DmConversationStatus.active,
  viewerState: DmViewerState.active,
  canSend: true,
  peer: DmPeer(
    id: 'peer-1',
    username: 'nguoithu',
    displayName: 'Người thử nghiệm',
    presence: DmPeerPresence.online,
  ),
);

class ControlledDmRepository implements DirectMessageRepository {
  Completer<DmMessage?> sendCompleter = Completer<DmMessage?>();
  Completer<DmMessage?> mutationCompleter = Completer<DmMessage?>();
  final List<({String clientMessageId, String content})> sends =
      <({String clientMessageId, String content})>[];
  final List<DmMessagePage> pages = <DmMessagePage>[];
  DmConversation conversation = sampleConversation;
  AppFailure? readFailure;

  @override
  Future<List<DmConversation>> getConversations({bool refresh = false}) async {
    if (readFailure case final f?) throw f;
    return <DmConversation>[conversation];
  }

  @override
  Future<DmConversation> getConversation(
    String conversationId, {
    bool refresh = false,
  }) async {
    if (readFailure case final f?) throw f;
    return conversation;
  }

  @override
  Future<DmConversationOpenResult> openOrRequestConversation(
    String recipientUserId,
  ) async => const DmConversationOpenResult(
    conversationId: 'conv-1',
    status: DmConversationStatus.requested,
  );

  @override
  Future<void> acceptRequest(String conversationId) async {}

  @override
  Future<void> declineRequest(String conversationId) async {}

  @override
  Future<void> deleteConversation(String conversationId) async {}

  @override
  Future<DmMessagePage> getMessages(
    String conversationId, {
    String? cursor,
    int limit = 50,
  }) async {
    if (readFailure case final f?) throw f;
    return pages.isEmpty
        ? DmMessagePage(items: const <DmMessage>[])
        : pages.removeAt(0);
  }

  @override
  Future<DmContextWindow> getMessageContext(
    String conversationId, {
    required String aroundMessageId,
  }) async => DmContextWindow(
    items: <DmMessage>[sampleDmMessage],
    targetMessageId: aroundMessageId,
  );

  @override
  Future<DmSearchPage> searchMessages(
    String conversationId, {
    required String query,
    int limit = 20,
  }) async => DmSearchPage(items: const <DmSearchResult>[]);

  @override
  Future<DmMediaPage> getConversationMedia(
    String conversationId, {
    String? cursor,
  }) async => DmMediaPage(items: const <DmMediaItem>[]);

  @override
  Future<DmMessage?> sendMessage(
    String conversationId, {
    required String clientMessageId,
    required String content,
    String? replyToId,
    List<String> attachmentIds = const <String>[],
  }) {
    sends.add((clientMessageId: clientMessageId, content: content));
    return sendCompleter.future;
  }

  @override
  Future<DmReadReceipt> markRead(
    String conversationId, {
    String? lastReadMessageId,
  }) async => DmReadReceipt(
    changed: true,
    lastReadMessageId: lastReadMessageId,
  );

  @override
  Future<DmMessage?> editMessage(String messageId, String content) =>
      mutationCompleter.future;

  @override
  Future<void> deleteMessage(String messageId) =>
      mutationCompleter.future.then((_) {});

  @override
  Future<DmMessage?> reactToMessage(
    String messageId,
    String emoji, {
    bool remove = false,
  }) => mutationCompleter.future;

  @override
  Future<DmUploadedAsset> uploadAttachment(DmUploadFile file) async =>
      const DmUploadedAsset(
        assetId: 'asset-1',
        status: 'READY',
        mime: 'image/png',
        size: 128,
      );

  @override
  Future<Uri> resolvePrivateMediaUrl(String downloadPath) async =>
      Uri.parse('https://cdn.example.invalid/signed.png');

  @override
  Future<String> reportConversation(
    String conversationId, {
    required DmReportReason reason,
    String detail = '',
  }) async => 'report-1';

  @override
  Future<void> blockUser(String userId) async {}

  @override
  Future<void> unblockUser(String userId) async {}
}
