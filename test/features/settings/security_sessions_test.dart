import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/core/api_client.dart';
import 'package:vnlfsocialapp/src/features/settings/data/live_security_sessions_repository.dart';
import 'package:vnlfsocialapp/src/features/settings/domain/security_sessions.dart';

void main() {
  test('requires a current session and explicit revoke acknowledgment', () async {
    final requests = <ApiRequest>[];
    final client = ApiClient(throttleInterval: Duration.zero, transport: (request) async {
      requests.add(request);
      return ApiResponse(statusCode: 200, body: jsonEncode(request.method == 'GET' ? {'items': [{'id': 'current', 'current': true}, {'id': 'other', 'current': false}]} : {'ok': true}));
    });
    final repository = LiveSecuritySessionsRepository(client);
    final sessions = await repository.load();
    expect(sessions.length, 2);
    await expectLater(repository.revoke(sessions.first), throwsA(isA<ParseFailure>()));
    await expectLater(repository.revoke(sessions.last), throwsA(isA<ParseFailure>()));
    expect(requests.where((r) => r.method == 'DELETE').length, 1);
    client.invalidateSession();
    await expectLater(repository.revoke(const SecuritySession(id: 'other', current: false)), throwsA(isA<HttpFailure>()));
    expect(requests.length, 2);
  });
}
