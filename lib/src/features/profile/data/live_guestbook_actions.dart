import 'dart:convert';

import '../../../core/api_client.dart';
import '../../../data/field_reader.dart';
import '../../../data/profile_dto.dart';
import '../domain/public_profile.dart';

final class LiveGuestbookActions {
  const LiveGuestbookActions(this.client);
  final ApiClient client;

  Future<GuestbookEntry> write(String username, String content) =>
      client.request(
        'POST',
        '/api/v1/profiles/${Uri.encodeComponent(username)}/guestbook',
        body: jsonEncode({'content': content}),
        decode: (json) {
          final status = switch (json['status']) {
            'VISIBLE' => GuestbookStatus.visible,
            'HIDDEN' => GuestbookStatus.hidden,
            _ => throw const ParseFailure('guestbook.entry.status'),
          };
          final entry = GuestbookEntry(
            id: stringValue(json['id'], 'guestbook.entry.id'),
            author: ProfileDto.fromJson(
              objectValue(json['author'], 'guestbook.entry.author') ?? const {},
            ).toDomain(),
            content: stringValue(json['content'], 'guestbook.entry.content'),
            createdAt: dateValue(
              json['createdAt'],
              'guestbook.entry.createdAt',
            ),
            status: status,
            mine: boolValue(json['mine'], 'guestbook.entry.mine'),
          );
          if (entry.id.isEmpty ||
              !entry.mine ||
              entry.status != GuestbookStatus.visible) {
            throw const ParseFailure('guestbook.entry');
          }
          return entry;
        },
      );

  Future<void> status(String id, GuestbookStatus status) => _ack(
    'PATCH',
    '/api/v1/guestbook/${Uri.encodeComponent(id)}',
    body: jsonEncode({
      'status': status == GuestbookStatus.hidden ? 'HIDDEN' : 'VISIBLE',
    }),
  );
  Future<void> delete(String id) =>
      _ack('DELETE', '/api/v1/guestbook/${Uri.encodeComponent(id)}');
  Future<void> block(String id) =>
      _ack('POST', '/api/v1/users/${Uri.encodeComponent(id)}/block');

  Future<void> _ack(String method, String path, {String? body}) async {
    await client.request<bool>(
      method,
      path,
      body: body,
      decode: (json) {
        if (json['ok'] != true) throw const ParseFailure('guestbook.ok');
        return true;
      },
    );
  }
}
