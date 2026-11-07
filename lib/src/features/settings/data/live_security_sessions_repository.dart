import '../../../core/api_client.dart';
import '../../../data/field_reader.dart';
import '../domain/security_sessions.dart';

final class LiveSecuritySessionsRepository implements SecuritySessionsRepository {
  LiveSecuritySessionsRepository(this._client) : _scope = _client.captureSession();
  final ApiClient _client;
  final ApiSessionScope _scope;

  @override
  Future<List<SecuritySession>> load() async {
    _scope.ensureCurrent();
    return _client.get('/api/v1/auth/sessions', refresh: true, decode: (json) {
      if (json['items'] is! List) throw const ParseFailure('sessions.items');
      final rows = objectList(json['items'], 'sessions.items');
      final sessions = rows.map((row) {
        final id = stringValue(row['id'], 'sessions.id');
        if (id.isEmpty || row['current'] is! bool) throw const ParseFailure('sessions.identity');
        return SecuritySession(id: id, current: row['current'] as bool, deviceName: nullableString(row['deviceName'], 'sessions.deviceName'), userAgent: nullableString(row['userAgent'], 'sessions.userAgent'), lastSeenAt: dateValue(row['lastSeenAt'], 'sessions.lastSeenAt'));
      }).toList(growable: false);
      if (sessions.where((s) => s.current).length != 1 || sessions.map((s) => s.id).toSet().length != sessions.length) throw const ParseFailure('sessions.current');
      return List.unmodifiable(sessions);
    });
  }

  @override
  Future<void> revoke(SecuritySession session) async {
    _scope.ensureCurrent();
    if (session.current || session.id.isEmpty) throw const ParseFailure('sessions.target');
    await _client.request<void>('DELETE', '/api/v1/auth/sessions/${Uri.encodeComponent(session.id)}', decode: (json) {
      if (json['ok'] != true || json['currentSessionRevoked'] != false) throw const ParseFailure('sessions.ack');
    });
  }

  @override
  Future<void> revokeOthers() async {
    _scope.ensureCurrent();
    await _client.request<void>('POST', '/api/v1/auth/logout-others', decode: (json) {
      if (json['ok'] != true) throw const ParseFailure('sessions.ack');
    });
  }
}
