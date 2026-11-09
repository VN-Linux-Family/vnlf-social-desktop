import 'dart:convert';

import '../../../core/api_client.dart';
import '../domain/password_reset.dart';

final class LivePasswordResetRepository implements PasswordResetRepository {
  LivePasswordResetRepository(this._client);
  final ApiClient _client;

  /// One request per tap; a failed request is never retried automatically.
  @override
  Future<void> requestReset(String email) => _client.request<void>(
    'POST',
    '/api/v1/auth/forgot-password',
    body: jsonEncode({'email': email}),
  );
}

/// Offline fixtures accept the request without sending anything.
final class FixturePasswordResetRepository implements PasswordResetRepository {
  const FixturePasswordResetRepository();
  @override
  Future<void> requestReset(String email) async {}
}
