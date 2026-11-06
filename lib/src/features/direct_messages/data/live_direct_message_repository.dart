import 'dart:convert';

import '../../../core/api_client.dart';
import '../../../data/field_reader.dart';
import '../domain/direct_message_models.dart';
import '../domain/direct_message_repository.dart';
import 'direct_message_dto.dart';
import 'direct_message_media_repository.dart';

final class LiveDirectMessageRepository implements DirectMessageRepository {
  LiveDirectMessageRepository(
    this._client, {
    DirectMessageMediaRepository? mediaRepository,
  }) : _mediaRepository =
           mediaRepository ?? DirectMessageMediaRepository(_client);

  final ApiClient _client;
  final DirectMessageMediaRepository _mediaRepository;

  @override
  Future<List<DmConversation>> getConversations({bool refresh = false}) =>
      _client.get<List<DmConversation>>(
        '/api/v1/dm/conversations',
        refresh: refresh,
        decode: DmConversationDto.parseList,
      );

  @override
  Future<DmConversation> getConversation(
    String conversationId, {
    bool refresh = false,
  }) {
    final encoded = _encodeId(conversationId, 'conversationId');
    return _client.get<DmConversation>(
      '/api/v1/dm/conversations/$encoded',
      refresh: refresh,
      decode: (json) => DmConversationDto(json).toDomain(),
    );
  }

  @override
  Future<DmConversationOpenResult> openOrRequestConversation(
    String recipientUserId,
  ) {
    final trimmed = recipientUserId.trim();
    if (trimmed.isEmpty) {
      throw const ParseFailure('recipientUserId');
    }
    return _client.request<DmConversationOpenResult>(
      'POST',
      '/api/v1/dm/conversations',
      body: jsonEncode(<String, Object?>{'recipientUserId': trimmed}),
      decode: (json) => DmConversationOpenResultDto(json).toDomain(),
    );
  }

  @override
  Future<void> acceptRequest(String conversationId) async {
    final encoded = _encodeId(conversationId, 'conversationId');
    await _client.request<Map<String, dynamic>>(
      'POST',
      '/api/v1/dm/conversations/$encoded/accept',
      body: jsonEncode(const <String, Object?>{}),
    );
  }

  @override
  Future<void> declineRequest(String conversationId) async {
    final encoded = _encodeId(conversationId, 'conversationId');
    await _client.request<Map<String, dynamic>>(
      'POST',
      '/api/v1/dm/conversations/$encoded/decline',
      body: jsonEncode(const <String, Object?>{}),
    );
  }

  @override
  Future<void> deleteConversation(String conversationId) async {
    final encoded = _encodeId(conversationId, 'conversationId');
    await _client.request<Map<String, dynamic>>(
      'DELETE',
      '/api/v1/dm/conversations/$encoded',
    );
  }

  @override
  Future<DmMessagePage> getMessages(
    String conversationId, {
    String? cursor,
    int limit = 50,
  }) {
    final encoded = _encodeId(conversationId, 'conversationId');
    final clampedLimit = limit.clamp(1, 100);
    final trimmedCursor = cursor?.trim();
    return _client.get<DmMessagePage>(
      '/api/v1/dm/conversations/$encoded/messages',
      refresh: true,
      query: <String, String>{
        'limit': '$clampedLimit',
        if (trimmedCursor != null && trimmedCursor.isNotEmpty)
          'cursor': trimmedCursor,
      },
      decode: (json) => DmMessagePageDto(json).toDomain(),
    );
  }

  @override
  Future<DmContextWindow> getMessageContext(
    String conversationId, {
    required String aroundMessageId,
  }) {
    final encoded = _encodeId(conversationId, 'conversationId');
    final around = aroundMessageId.trim();
    if (around.isEmpty) {
      throw const ParseFailure('aroundMessageId');
    }
    return _client.get<DmContextWindow>(
      '/api/v1/dm/conversations/$encoded/messages/context',
      refresh: true,
      query: <String, String>{'around': around},
      decode: (json) => DmContextWindowDto(json).toDomain(),
    );
  }

  @override
  Future<DmSearchPage> searchMessages(
    String conversationId, {
    required String query,
    int limit = 20,
  }) {
    final encoded = _encodeId(conversationId, 'conversationId');
    final trimmedQuery = query.trim();
    if (trimmedQuery.length < 2 || trimmedQuery.length > 100) {
      throw const ParseFailure('search.query');
    }
    final clampedLimit = limit.clamp(1, 50);
    return _client.get<DmSearchPage>(
      '/api/v1/dm/conversations/$encoded/messages/search',
      refresh: true,
      query: <String, String>{'q': trimmedQuery, 'limit': '$clampedLimit'},
      decode: (json) => DmSearchPageDto(json).toDomain(),
    );
  }

  @override
  Future<DmMediaPage> getConversationMedia(
    String conversationId, {
    String? cursor,
  }) {
    final encoded = _encodeId(conversationId, 'conversationId');
    final trimmedCursor = cursor?.trim();
    return _client.get<DmMediaPage>(
      '/api/v1/dm/conversations/$encoded/media',
      refresh: true,
      query: <String, String>{
        if (trimmedCursor != null && trimmedCursor.isNotEmpty)
          'cursor': trimmedCursor,
      },
      decode: (json) => DmMediaPageDto(json).toDomain(),
    );
  }

  @override
  Future<DmMessage?> sendMessage(
    String conversationId, {
    required String clientMessageId,
    required String content,
    String? replyToId,
    List<String> attachmentIds = const <String>[],
  }) {
    final encoded = _encodeId(conversationId, 'conversationId');
    final trimmedClientId = clientMessageId.trim();
    if (trimmedClientId.isEmpty || trimmedClientId.length > 100) {
      throw const ParseFailure('message.clientMessageId');
    }
    final tidiedContent = tidyDmMessageText(content);
    final cleanAttachments = attachmentIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
    if (cleanAttachments.length > 4) {
      throw const ParseFailure('message.attachmentIds');
    }
    if (tidiedContent.isEmpty && cleanAttachments.isNotEmpty == false) {
      throw const ParseFailure('message.content');
    }
    if (tidiedContent.length > 4000) {
      throw const ParseFailure('message.content');
    }
    final trimmedReplyTo = replyToId?.trim();
    return _client.request<DmMessage?>(
      'POST',
      '/api/v1/dm/conversations/$encoded/messages',
      body: jsonEncode(<String, Object?>{
        'clientMessageId': trimmedClientId,
        'content': tidiedContent,
        if (trimmedReplyTo != null && trimmedReplyTo.isNotEmpty)
          'replyToId': trimmedReplyTo,
        if (cleanAttachments.isNotEmpty) 'attachmentIds': cleanAttachments,
      }),
      decode: DmMessageDto.tryParseMutationResponse,
    );
  }

  @override
  Future<DmReadReceipt> markRead(
    String conversationId, {
    String? lastReadMessageId,
  }) {
    final encoded = _encodeId(conversationId, 'conversationId');
    final trimmedLastRead = lastReadMessageId?.trim();
    return _client.request<DmReadReceipt>(
      'POST',
      '/api/v1/dm/conversations/$encoded/read',
      body: jsonEncode(<String, Object?>{
        if (trimmedLastRead != null && trimmedLastRead.isNotEmpty)
          'lastReadMessageId': trimmedLastRead,
      }),
      decode: (json) => DmReadReceiptDto(json).toDomain(),
    );
  }

  @override
  Future<DmMessage?> editMessage(String messageId, String content) {
    final encoded = _encodeId(messageId, 'messageId');
    final tidied = tidyDmMessageText(content);
    if (tidied.isEmpty || tidied.length > 4000) {
      throw const ParseFailure('message.content');
    }
    return _client.request<DmMessage?>(
      'PATCH',
      '/api/v1/messages/$encoded',
      body: jsonEncode(<String, Object?>{'content': tidied}),
      decode: DmMessageDto.tryParseMutationResponse,
    );
  }

  @override
  Future<void> deleteMessage(String messageId) async {
    final encoded = _encodeId(messageId, 'messageId');
    await _client.request<Map<String, dynamic>>(
      'DELETE',
      '/api/v1/messages/$encoded',
    );
  }

  @override
  Future<DmMessage?> reactToMessage(
    String messageId,
    String emoji, {
    bool remove = false,
  }) {
    final encodedId = _encodeId(messageId, 'messageId');
    final trimmedEmoji = emoji.trim();
    if (trimmedEmoji.isEmpty || trimmedEmoji.length > 32) {
      throw const ParseFailure('reaction.emoji');
    }
    if (remove) {
      final encodedEmoji = Uri.encodeComponent(trimmedEmoji);
      return _client.request<DmMessage?>(
        'DELETE',
        '/api/v1/messages/$encodedId/reactions/$encodedEmoji',
        decode: DmMessageDto.tryParseMutationResponse,
      );
    }
    return _client.request<DmMessage?>(
      'POST',
      '/api/v1/messages/$encodedId/reactions',
      body: jsonEncode(<String, Object?>{'emoji': trimmedEmoji}),
      decode: DmMessageDto.tryParseMutationResponse,
    );
  }

  @override
  Future<DmUploadedAsset> uploadAttachment(DmUploadFile file) =>
      _mediaRepository.upload(file);

  @override
  Future<Uri> resolvePrivateMediaUrl(String downloadPath) =>
      _mediaRepository.resolve(downloadPath);

  @override
  Future<String> reportConversation(
    String conversationId, {
    required DmReportReason reason,
    String detail = '',
  }) {
    final encoded = _encodeId(conversationId, 'conversationId');
    final trimmedDetail = detail.trim();
    if (trimmedDetail.length > 2000) {
      throw const ParseFailure('report.detail');
    }
    return _client.request<String>(
      'POST',
      '/api/v1/dm/conversations/$encoded/report',
      body: jsonEncode(<String, Object?>{
        'reason': reason.wireValue,
        if (trimmedDetail.isNotEmpty) 'detail': trimmedDetail,
      }),
      decode: (json) {
        final reportId = stringValue(json['reportId'], 'report.reportId');
        if (reportId.isEmpty) {
          throw const ParseFailure('report.reportId');
        }
        return reportId;
      },
    );
  }

  @override
  Future<void> blockUser(String userId) async {
    final encoded = _encodeId(userId, 'userId');
    await _client.request<Map<String, dynamic>>(
      'POST',
      '/api/v1/users/$encoded/block',
      body: jsonEncode(const <String, Object?>{}),
    );
  }

  @override
  Future<void> unblockUser(String userId) async {
    final encoded = _encodeId(userId, 'userId');
    await _client.request<Map<String, dynamic>>(
      'DELETE',
      '/api/v1/users/$encoded/block',
    );
  }

  String _encodeId(String raw, String field) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      throw ParseFailure(field);
    }
    return Uri.encodeComponent(trimmed);
  }
}
