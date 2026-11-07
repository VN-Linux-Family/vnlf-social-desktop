import '../../../core/api_client.dart';
import '../domain/profile_relationship.dart';

final class LiveProfileRelationshipRepository
    implements ProfileRelationshipRepository {
  const LiveProfileRelationshipRepository(this._client);
  final ApiClient _client;

  @override
  Future<void> setFollowing(String userId, {required bool following}) =>
      _send(following ? 'POST' : 'DELETE', userId, 'follow');

  @override
  Future<void> setBlocked(String userId, {required bool blocked}) =>
      _send(blocked ? 'POST' : 'DELETE', userId, 'block');

  Future<void> _send(String method, String userId, String relation) async {
    if (userId.isEmpty) throw const ParseFailure('user.id');
    await _client.request<bool>(
      method,
      '/api/v1/users/${Uri.encodeComponent(userId)}/$relation',
      decode: (json) {
        if (json['ok'] != true) throw ParseFailure('$relation.ok');
        return true;
      },
    );
  }
}
