import 'dart:convert';

import '../core/api_client.dart';
import '../domain/models.dart';
import '../domain/repositories.dart';
import 'field_reader.dart';

final class LiveAuthRepository implements AuthRepository {
  LiveAuthRepository(this._client, {this.onSessionChanged, this.onLogout});

  final ApiClient _client;
  final void Function(Session?)? onSessionChanged;
  final void Function()? onLogout;

  @override
  Future<Session?> currentSession() async {
    try {
      final session = await _client.get<Session?>(
        '/api/v1/auth/session',
        decode: (json) {
          final user = json['user'] is Map<String, dynamic>
              ? json['user'] as Map<String, dynamic>
              : json;
          final id = user['id'] as String? ?? json['id'] as String? ?? '';
          if (id.isEmpty) return null;
          return Session(
            userId: id,
            displayName:
                user['displayName'] as String? ??
                user['username'] as String? ??
                '',
            username: user['username'] as String? ?? '',
            email: user['email'] as String? ?? '',
            avatarUrl: user['avatarUrl'] as String? ?? '',
            role: user['role'] as String? ?? '',
            style: styleValue(user['style'], 'user.style'),
          );
        },
      );
      onSessionChanged?.call(session);
      return session;
    } catch (e) {
      if (e is HttpFailure && (e.statusCode == 401 || e.statusCode == 403)) {
        onSessionChanged?.call(null);
        return null;
      }
      return null;
    }
  }

  @override
  Future<Session> login(String login, String password) async {
    final session = await _client.request<Session>(
      'POST',
      '/api/v1/auth/login',
      body: jsonEncode({'login': login.trim(), 'password': password}),
      decode: (json) {
        final user = json['user'] is Map<String, dynamic>
            ? json['user'] as Map<String, dynamic>
            : json;
        return Session(
          userId: user['id'] as String? ?? json['id'] as String? ?? '',
          displayName:
              user['displayName'] as String? ??
              user['username'] as String? ??
              '',
          username: user['username'] as String? ?? '',
          email: user['email'] as String? ?? '',
          avatarUrl: user['avatarUrl'] as String? ?? '',
          role: user['role'] as String? ?? '',
          style: styleValue(user['style'], 'user.style'),
        );
      },
    );
    onSessionChanged?.call(session);
    return session;
  }

  @override
  Future<Session> register(
    String email,
    String username,
    String password,
  ) async {
    final session = await _client.request<Session>(
      'POST',
      '/api/v1/auth/register',
      body: jsonEncode({
        'email': email.trim(),
        'username': username.trim(),
        'password': password,
      }),
      decode: (json) {
        final user = json['user'] is Map<String, dynamic>
            ? json['user'] as Map<String, dynamic>
            : json;
        return Session(
          userId: user['id'] as String? ?? json['id'] as String? ?? '',
          displayName:
              user['displayName'] as String? ??
              user['username'] as String? ??
              username,
          username: user['username'] as String? ?? username,
          email: user['email'] as String? ?? email,
          avatarUrl: user['avatarUrl'] as String? ?? '',
          role: user['role'] as String? ?? '',
          style: styleValue(user['style'], 'user.style'),
        );
      },
    );
    onSessionChanged?.call(session);
    return session;
  }

  @override
  Future<void> logout() async {
    try {
      await _client.request<void>('POST', '/api/v1/auth/logout');
    } catch (_) {}
    onLogout?.call();
    onSessionChanged?.call(null);
  }
}
