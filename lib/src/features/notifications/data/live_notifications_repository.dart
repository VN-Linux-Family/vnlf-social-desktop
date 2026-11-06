import 'dart:convert';

import '../../../core/api_client.dart';
import '../../../data/field_reader.dart';
import '../../../data/profile_dto.dart';
import '../domain/notifications_repository.dart';

final class LiveNotificationsRepository implements NotificationsRepository {
  const LiveNotificationsRepository(this._client);
  final ApiClient _client;
  @override
  Future<NotificationsPage> load({
    String? cursor,
    bool unreadOnly = false,
  }) => _client.get(
    '/api/v1/notifications',
    refresh: cursor == null,
    query: {
      'limit': '20',
      'filter': unreadOnly ? 'unread' : 'all',
      'cursor': ?cursor,
    },
    decode: (json) => NotificationsPage(
      nextCursor: nullableString(
        json['nextCursor'],
        'notifications.nextCursor',
      ),
      unreadCount: intValue(json['unreadCount'], 'notifications.unreadCount'),
      unseenCount: intValue(json['unseenCount'], 'notifications.unseenCount'),
      items: objectList(json['items'], 'notifications.items').map((item) {
        final id = stringValue(item['id'], 'notification.id');
        if (id.isEmpty) throw const ParseFailure('notification.id');
        final summary =
            objectValue(item['targetSummary'], 'notification.summary') ?? {};
        final actors = objectList(item['actors'], 'notification.actors');
        return CommunityNotice(
          id: id,
          type: stringValue(item['type'], 'notification.type'),
          targetId: stringValue(item['targetId'], 'notification.targetId'),
          targetType: stringValue(
            item['targetType'],
            'notification.targetType',
          ),
          href: stringValue(item['href'], 'notification.href'),
          title: stringValue(summary['title'], 'notification.title'),
          excerpt: stringValue(summary['excerpt'], 'notification.excerpt'),
          actor: ProfileDto.fromJson(actors.isEmpty ? {} : actors.first)
              .toDomain(),
          unread: item['readAt'] == null,
        );
      }).toList(),
    ),
  );
  @override
  Future<void> seen() => _client.request<void>(
    'POST',
    '/api/v1/notifications/seen',
    decode: _confirmed,
  );
  @override
  Future<void> read({List<String>? ids}) => _client.request<void>(
    'POST',
    '/api/v1/notifications/read',
    body: jsonEncode({'ids': ?ids}),
    decode: _confirmed,
  );
}

void _confirmed(Map<String, dynamic> json) {
  if (json['ok'] != true) {
    throw const ParseFailure('notifications.acknowledgment');
  }
}
