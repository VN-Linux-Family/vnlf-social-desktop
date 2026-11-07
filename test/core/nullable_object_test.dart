import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/core/api_client.dart';

void main() {
  test(
    'nullable object reads cache null and invalidate it with the session',
    () async {
      var requests = 0;
      final client = ApiClient(
        hostKey: Object(),
        throttleInterval: Duration.zero,
        transport: (_) async {
          requests++;
          return ApiResponse(
            statusCode: 200,
            body: requests == 1 ? 'null' : '{"enabled":true}',
          );
        },
      );

      expect(await client.getNullableObject('/preferences'), isNull);
      expect(await client.getNullableObject('/preferences'), isNull);
      expect(requests, 1);
      await expectLater(
        client.get<Map<String, dynamic>>('/preferences'),
        throwsA(isA<ParseFailure>()),
      );
      client.invalidateSession();
      expect(await client.getNullableObject('/preferences'), {'enabled': true});
      expect(requests, 2);
    },
  );

  test('nullable object reads reject malformed and non-object JSON', () async {
    for (final body in ['[1]', 'false', 'invalid']) {
      final client = ApiClient(
        hostKey: Object(),
        throttleInterval: Duration.zero,
        transport: (_) async => ApiResponse(statusCode: 200, body: body),
      );
      await expectLater(
        client.getNullableObject('/preferences'),
        throwsA(isA<ParseFailure>()),
      );
    }
  });

  test('refresh bypasses a cached null', () async {
    var requests = 0;
    final client = ApiClient(
      hostKey: Object(),
      throttleInterval: Duration.zero,
      transport: (_) async => ApiResponse(
        statusCode: 200,
        body: ++requests == 1 ? 'null' : '{"enabled":true}',
      ),
    );
    expect(await client.getNullableObject('/preferences'), isNull);
    expect(await client.getNullableObject('/preferences', refresh: true), {
      'enabled': true,
    });
    expect(await client.getNullableObject('/preferences'), {'enabled': true});
    expect(requests, 2);
  });

  test(
    'nullable object read rejects a response from a previous session',
    () async {
      final response = Completer<ApiResponse>();
      final requested = Completer<void>();
      final client = ApiClient(
        hostKey: Object(),
        throttleInterval: Duration.zero,
        transport: (_) {
          requested.complete();
          return response.future;
        },
      );
      final result = client.getNullableObject('/preferences');
      await requested.future;
      client.invalidateSession();
      response.complete(ApiResponse(statusCode: 200, body: 'null'));
      await expectLater(
        result,
        throwsA(isA<HttpFailure>().having((e) => e.statusCode, 'status', 401)),
      );
    },
  );
}
