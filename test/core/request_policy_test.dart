import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/core/api_client.dart';
import 'package:vnlfsocialapp/src/core/io_api_transport.dart';

void main() {
  test('transport exposes status, headers and the undecoded body', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    server.listen((request) async {
      request.response.statusCode = 429;
      request.response.headers.set('Retry-After', '3');
      request.response.write('not json');
      await request.response.close();
    });
    final transport = IoApiTransport(
      Uri.parse('http://127.0.0.1:${server.port}'),
    );
    addTearDown(transport.close);
    final response = await transport.call(ApiRequest('/feed'));
    expect(response.statusCode, 429);
    expect(response.headers['retry-after'], '3');
    expect(response.body, 'not json');
  });

  test('honors Retry-After and caps it at one minute', () async {
    var count = 0;
    final delays = <Duration>[];
    final client = ApiClient(
      hostKey: Object(),
      transport: (_) async => ++count == 1
          ? ApiResponse(
              statusCode: 503,
              headers: {'Retry-After': '120'},
              body: '',
            )
          : ApiResponse(statusCode: 200, body: '{"ok":true}'),
      retryDelay: (delay) async => delays.add(delay),
      throttleInterval: Duration.zero,
    );
    expect(await client.get<Map<String, dynamic>>('/feed'), {'ok': true});
    expect(delays, [const Duration(seconds: 60)]);
  });

  test(
    'two consecutive rate limits stop requests during host cooldown',
    () async {
      var count = 0;
      final client = ApiClient(
        hostKey: Object(),
        transport: (_) async {
          count++;
          return ApiResponse(statusCode: 429, body: '');
        },
        retryDelay: (_) async {},
        throttleInterval: Duration.zero,
      );
      await expectLater(
        client.get<Map<String, dynamic>>('/one'),
        throwsA(isA<RateLimited>()),
      );
      await expectLater(
        client.get<Map<String, dynamic>>('/two'),
        throwsA(isA<RateLimited>()),
      );
      expect(count, 2);
    },
  );

  test('non-idempotent requests do not retry transient errors', () async {
    var count = 0;
    final client = ApiClient(
      hostKey: Object(),
      transport: (_) async {
        count++;
        return ApiResponse(statusCode: 503, body: '');
      },
      retryDelay: (_) async {},
      throttleInterval: Duration.zero,
    );
    for (final method in ['POST', 'PUT', 'PATCH', 'DELETE']) {
      await expectLater(
        client.request<Map<String, dynamic>>(method, '/write'),
        throwsA(isA<HttpFailure>()),
      );
    }
    expect(count, 4);
  });

  test('limits requests in flight to two', () async {
    var active = 0;
    var peak = 0;
    final release = Completer<void>();
    final client = ApiClient(
      hostKey: Object(),
      transport: (_) async {
        active++;
        if (active > peak) peak = active;
        await release.future;
        active--;
        return ApiResponse(statusCode: 200, body: '{}');
      },
      throttleInterval: Duration.zero,
    );
    final requests = [
      for (var i = 0; i < 3; i++) client.get<Map<String, dynamic>>('/$i'),
    ];
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(peak, 2);
    release.complete();
    await Future.wait(requests);
    expect(peak, 2);
  });
  test('clients for the same host share the cooldown', () async {
    final host = Object();
    var count = 0;
    Future<ApiResponse> limited(ApiRequest request) async {
      count++;
      return ApiResponse(statusCode: 429, body: '');
    }

    final first = ApiClient(
      hostKey: host,
      transport: limited,
      retryDelay: (_) async {},
      throttleInterval: Duration.zero,
    );
    final second = ApiClient(
      hostKey: host,
      transport: limited,
      retryDelay: (_) async {},
      throttleInterval: Duration.zero,
    );
    final before = DateTime.now();
    await expectLater(
      first.get<Map<String, dynamic>>('/a'),
      throwsA(
        isA<RateLimited>().having(
          (e) => e.retryAt.difference(before).inSeconds,
          'cooldown seconds',
          inInclusiveRange(299, 300),
        ),
      ),
    );
    await expectLater(
      second.get<Map<String, dynamic>>('/b'),
      throwsA(isA<RateLimited>()),
    );
    expect(count, 2);
  });

  test('honors an HTTP-date Retry-After header', () async {
    var count = 0;
    final delays = <Duration>[];
    final future = HttpDate.format(
      DateTime.now().toUtc().add(const Duration(seconds: 30)),
    );
    final client = ApiClient(
      hostKey: Object(),
      transport: (_) async => ++count == 1
          ? ApiResponse(
              statusCode: 503,
              headers: {'retry-after': future},
              body: '',
            )
          : ApiResponse(statusCode: 200, body: '{}'),
      retryDelay: (delay) async => delays.add(delay),
      throttleInterval: Duration.zero,
    );
    await client.get<Map<String, dynamic>>('/date');
    expect(delays.single.inSeconds, inInclusiveRange(28, 30));
  });

  test(
    'default interval spaces requests by at least 500 milliseconds',
    () async {
      final starts = <DateTime>[];
      final client = ApiClient(
        hostKey: Object(),
        transport: (_) async {
          starts.add(DateTime.now());
          return ApiResponse(statusCode: 200, body: '{}');
        },
      );
      await Future.wait([
        client.get<Map<String, dynamic>>('/a'),
        client.get<Map<String, dynamic>>('/b'),
      ]);
      expect(
        starts[1].difference(starts[0]),
        greaterThanOrEqualTo(const Duration(milliseconds: 500)),
      );
    },
  );
}
