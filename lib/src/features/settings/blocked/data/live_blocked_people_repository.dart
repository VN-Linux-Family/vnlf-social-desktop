import '../../../../core/api_client.dart';
import '../domain/blocked_people.dart';

final class LiveBlockedPeopleRepository implements BlockedPeopleRepository {
  LiveBlockedPeopleRepository(this._client, this.ownerId, this._currentOwner)
    : _scope = _client.captureSession();
  final ApiClient _client;
  final String ownerId;
  final String? Function() _currentOwner;
  final ApiSessionScope _scope;

  void _guard() {
    _scope.ensureCurrent();
    if (ownerId.isEmpty || _currentOwner() != ownerId) {
      throw const HttpFailure(401);
    }
  }

  @override
  Future<List<BlockedPerson>> load() async {
    _guard();
    final people = await _client.get<List<BlockedPerson>>(
      '/api/v1/me/blocks',
      refresh: true,
      decode: (json) {
        final items = json['items'];
        if (items is! List) throw const ParseFailure('blocks.items');
        final result = <BlockedPerson>[];
        final ids = <String>{};
        for (final item in items) {
          if (item is! Map ||
              item['id'] is! String ||
              (item['id'] as String).isEmpty ||
              !ids.add(item['id'] as String)) {
            throw const ParseFailure('blocks.identity');
          }
          String text(String key) {
            final value = item[key];
            if (value == null) return '';
            if (value is! String) throw ParseFailure('blocks.$key');
            return value;
          }

          final avatar = item['avatarUrl'];
          if (avatar != null && avatar is! String) {
            throw const ParseFailure('blocks.avatarUrl');
          }
          final date = item['blockedAt'];
          if (date != null &&
              (date is! String || DateTime.tryParse(date) == null)) {
            throw const ParseFailure('blocks.blockedAt');
          }
          result.add(
            BlockedPerson(
              id: item['id'] as String,
              username: text('username'),
              displayName: text('displayName'),
              bio: text('bio'),
              avatarUrl: avatar as String?,
              blockedAt: date == null ? null : DateTime.parse(date as String),
            ),
          );
        }
        return List.unmodifiable(result);
      },
    );
    _guard();
    return people;
  }

  @override
  Future<void> unblock(String id) async {
    _guard();
    if (id.isEmpty || id == ownerId) throw const ParseFailure('blocks.target');
    await _client.request<void>(
      'DELETE',
      '/api/v1/users/${Uri.encodeComponent(id)}/block',
      decode: (json) {
        if (json['ok'] != true) throw const ParseFailure('blocks.ack');
      },
    );
    _guard();
  }
}
