import 'direct_message_models.dart';

abstract interface class DirectMessageRepository {
  Future<List<DmConversation>> getConversations({bool refresh = false});

  Future<DmConversation> getConversation(
    String conversationId, {
    bool refresh = false,
  });

  Future<DmConversationOpenResult> openOrRequestConversation(
    String recipientUserId,
  );

  Future<void> acceptRequest(String conversationId);

  Future<void> declineRequest(String conversationId);

  Future<void> deleteConversation(String conversationId);

  Future<DmMessagePage> getMessages(
    String conversationId, {
    String? cursor,
    int limit = 50,
  });

  Future<DmContextWindow> getMessageContext(
    String conversationId, {
    required String aroundMessageId,
  });

  Future<DmSearchPage> searchMessages(
    String conversationId, {
    required String query,
    int limit = 20,
  });

  Future<DmMediaPage> getConversationMedia(
    String conversationId, {
    String? cursor,
  });

  Future<DmMessage?> sendMessage(
    String conversationId, {
    required String clientMessageId,
    required String content,
    String? replyToId,
    List<String> attachmentIds = const <String>[],
  });

  Future<DmReadReceipt> markRead(
    String conversationId, {
    String? lastReadMessageId,
  });

  Future<DmMessage?> editMessage(String messageId, String content);

  Future<void> deleteMessage(String messageId);

  Future<DmMessage?> reactToMessage(
    String messageId,
    String emoji, {
    bool remove = false,
  });

  Future<DmUploadedAsset> uploadAttachment(DmUploadFile file);

  Future<Uri> resolvePrivateMediaUrl(String downloadPath);

  Future<String> reportConversation(
    String conversationId, {
    required DmReportReason reason,
    String detail = '',
  });

  Future<void> blockUser(String userId);

  Future<void> unblockUser(String userId);
}
