import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/core/api_client.dart';

void main() {
  test(
    'version conflict preserves the server error code without retrying',
    () async {
      var calls = 0;
      final client = ApiClient(
        throttleInterval: Duration.zero,
        hostKey: Object(),
        transport: (_) async {
          calls++;
          return ApiResponse(
            statusCode: 409,
            body: '{"code":"ARTICLE_VERSION_CONFLICT","message":"synthetic detail"}',
          );
        },
      );
      await expectLater(
        client.request<void>('PATCH', '/api/v1/articles/synthetic'),
        throwsA(
          isA<HttpFailure>().having(
            (error) => error.code,
            'server code',
            'ARTICLE_VERSION_CONFLICT',
          ),
        ),
      );
      expect(calls, 1);
    },
  );
  test('HTML error page still becomes an HTTP failure', () async {
    final client = ApiClient(
      throttleInterval: Duration.zero,
      hostKey: Object(),
      transport: (_) async => ApiResponse(
        statusCode: 403,
        body: '<html>synthetic proxy failure</html>',
      ),
    );
    await expectLater(
      client.get<Object>('/synthetic'),
      throwsA(
        isA<HttpFailure>()
            .having((error) => error.statusCode, 'status', 403)
            .having((error) => error.code, 'code', isNull),
      ),
    );
  });
}
