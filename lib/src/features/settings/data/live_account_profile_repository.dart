import 'dart:convert';

import '../../../core/api_client.dart';
import '../../../data/field_reader.dart';
import '../domain/account_profile.dart';
import '../domain/account_profile_repository.dart';

/// `GET /api/v1/users/:username` and `PATCH /api/v1/me/profile`.
///
/// The repository is bound to the account that was signed in when it was
/// created; once the session changes every call fails with a 401 instead of
/// reaching the next account.
final class LiveAccountProfileRepository implements AccountProfileRepository {
  LiveAccountProfileRepository(this._client, {this.expectedUserId})
    : _scope = _client.captureSession();

  final ApiClient _client;
  final String? expectedUserId;
  final ApiSessionScope _scope;

  @override
  Future<AccountProfile> load(String username) async {
    _scope.ensureCurrent();
    return _client.get(
      '/api/v1/users/${Uri.encodeComponent(username)}',
      refresh: true,
      decode: (json) {
        if (expectedUserId != null && json['id'] != expectedUserId) {
          throw const ParseFailure('profile.owner');
        }
        final name = stringValue(json['username'], 'profile.username');
        if (name.isEmpty) throw const ParseFailure('profile.username');
        return AccountProfile(
          username: name,
          displayName: stringValue(json['displayName'], 'profile.displayName'),
          bio: nullableString(json['bio'], 'profile.bio') ?? '',
          website: nullableString(json['website'], 'profile.website') ?? '',
        );
      },
    );
  }

  @override
  Future<void> save(ProfilePatch patch) async {
    _scope.ensureCurrent();
    if (patch.isEmpty) throw const ParseFailure('profile.patch');
    await _client.request<void>(
      'PATCH',
      '/api/v1/me/profile',
      body: jsonEncode({
        for (final entry in patch.fields.entries) entry.key.name: entry.value,
      }),
      decode: (json) {
        if (json['ok'] != true) throw const ParseFailure('profile.ok');
      },
    );
  }
}
