import 'dart:convert';

import '../../../core/api_client.dart';
import '../../../data/field_reader.dart';
import '../domain/channel_models.dart';
import '../domain/channel_repository.dart';
import 'channel_dto.dart';

final class LiveChannelRepository implements ChannelRepository {
  const LiveChannelRepository(this._client);
  final ApiClient _client;

  @override
  Future<List<ChatChannel>> getChannels() => _client.get(
    '/api/v1/channels',
    decode: (json) => List.unmodifiable(
      objectList(
        json['items'],
        'items',
      ).map((item) => ChatChannelDto(item).toDomain()),
    ),
  );

  @override
  Future<ChannelMessagePage> getMessages(String channelId, {String? cursor}) =>
      _client.get(
        '/api/v1/channels/${Uri.encodeComponent(channelId)}/messages',
        refresh: true,
        query: {'limit': '50', 'cursor': ?cursor},
        decode: (json) => ChannelMessagePage(
          items: objectList(
            json['items'],
            'items',
          ).map((item) => ChannelMessageDto(item).toDomain()).toList(),
          nextCursor: nullableString(json['nextCursor'], 'nextCursor'),
        ),
      );

  // The web client ignores mutation bodies and reloads history after confirmation.
  // This deliberately avoids assuming an undocumented response envelope.
  @override
  Future<void> send(
    String channelId, {
    required String clientMessageId,
    required String content,
    String? replyToId,
  }) => _write(
    'POST',
    '/api/v1/channels/${Uri.encodeComponent(channelId)}/messages',
    {
      'clientMessageId': clientMessageId,
      'content': content,
      'replyToId': ?replyToId,
    },
  );

  @override
  Future<void> edit(String messageId, String content) => _write(
    'PATCH',
    '/api/v1/messages/${Uri.encodeComponent(messageId)}',
    {'content': content},
  );
  @override
  Future<void> delete(String messageId) =>
      _write('DELETE', '/api/v1/messages/${Uri.encodeComponent(messageId)}');
  @override
  Future<void> react(String messageId, String emoji, {bool remove = false}) =>
      remove
      ? _write(
          'DELETE',
          '/api/v1/messages/${Uri.encodeComponent(messageId)}/reactions/${Uri.encodeComponent(emoji)}',
        )
      : _write(
          'POST',
          '/api/v1/messages/${Uri.encodeComponent(messageId)}/reactions',
          {'emoji': emoji},
        );

  @override
  Future<void> markRead(String channelId, {String? lastReadMessageId}) async {
    final encoded = Uri.encodeComponent(channelId);
    final trimmed = lastReadMessageId?.trim();
    await _write(
      'POST',
      '/api/v1/channels/$encoded/read',
      trimmed != null && trimmed.isNotEmpty
          ? <String, dynamic>{'lastReadMessageId': trimmed}
          : <String, dynamic>{},
    );
    _client.clearCache();
  }

  Future<void> _write(
    String method,
    String path, [
    Map<String, dynamic>? body,
  ]) async {
    await _client.request<Map<String, dynamic>>(
      method,
      path,
      body: body == null ? null : jsonEncode(body),
    );
  }
}
