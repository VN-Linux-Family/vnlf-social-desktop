import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/core/api_client.dart';
import 'package:vnlfsocialapp/src/core/io_api_transport.dart';

void main() {
  late HttpServer server;
  late IoApiTransport transport;
  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    transport = IoApiTransport(Uri.parse('http://127.0.0.1:${server.port}'));
  });
  tearDown(() async {
    transport.close();
    await server.close(force: true);
  });

  test(
    'retries 500 and 429 with exponential delays and sends user agent',
    () async {
      var requests = 0;
      final delays = <Duration>[];
      server.listen((request) async {
        requests++;
        expect(
          request.headers.value('user-agent'),
          'vlf-flutter-dev/0.1 (unofficial community client)',
        );
        request.response.statusCode = requests == 1
            ? 500
            : requests == 2
            ? 429
            : 200;
        request.response.write('{"ok":true}');
        await request.response.close();
      });
      final client = ApiClient(
        hostKey: Object(),
        transport: transport.call,
        random: Random(1),
        retryDelay: (delay) async => delays.add(delay),
        throttleInterval: Duration.zero,
      );
      expect(await client.get<Map<String, dynamic>>('/feed'), {'ok': true});
      expect(requests, 3);
      expect(delays[0].inMilliseconds, inInclusiveRange(200, 300));
      expect(delays[1].inMilliseconds, inInclusiveRange(400, 500));
    },
  );

  test(
    'caches successful results by query and keeps returned objects isolated',
    () async {
      var requests = 0;
      server.listen((request) async {
        requests++;
        request.response.write(
          jsonEncode({
            'items': [request.uri.queryParameters['q']],
          }),
        );
        await request.response.close();
      });
      final client = ApiClient(
        hostKey: Object(),
        transport: transport.call,
        throttleInterval: Duration.zero,
      );
      final first = await client.get<Map<String, dynamic>>(
        '/feed',
        query: {'q': 'a'},
      );
      (first['items'] as List).clear();
      final second = await client.get<Map<String, dynamic>>(
        '/feed',
        query: {'q': 'a'},
      );
      expect(second['items'], ['a']);
      await client.get<Map<String, dynamic>>('/feed', query: {'q': 'b'});
      expect(requests, 2);
    },
  );

  test('does not retry non-transient status and fails invalid JSON as parse failure', () async {
    var requests = 0;
    server.listen((request) async {
      requests++;
      request.response.statusCode = request.uri.path == '/missing' ? 404 : 200;
      request.response.write('not json');
      await request.response.close();
    });
    final client = ApiClient(
      hostKey: Object(),
      transport: transport.call,
      throttleInterval: Duration.zero,
    );
    await expectLater(
      client.get<Map<String, dynamic>>('/missing'),
      throwsA(isA<HttpFailure>().having((e) => e.statusCode, 'status', 404)),
    );
    await expectLater(
      client.get<Map<String, dynamic>>('/bad'),
      throwsA(isA<ParseFailure>()),
    );
    expect(requests, 2);
  });

  test('retries timeouts and returns typed failure after exhaustion', () async {
    var attempts = 0;
    final client = ApiClient(
      hostKey: Object(),
      transport: (_) async {
        attempts++;
        throw TimeoutException('timeout');
      },
      retryDelay: (_) async {},
      throttleInterval: Duration.zero,
    );
    await expectLater(
      client.get<Map<String, dynamic>>('/timeout'),
      throwsA(isA<TransportFailure>()),
    );
    expect(attempts, 3);
  });

  test('throttles concurrent cache misses', () async {
    final arrivals = <DateTime>[];
    server.listen((request) async {
      arrivals.add(DateTime.now());
      request.response.write('{}');
      await request.response.close();
    });
    final client = ApiClient(
      hostKey: Object(),
      transport: transport.call,
      throttleInterval: const Duration(milliseconds: 80),
    );
    await Future.wait([
      client.get<Map<String, dynamic>>('/a'),
      client.get<Map<String, dynamic>>('/b'),
    ]);
    expect(
      arrivals[1].difference(arrivals[0]).inMilliseconds,
      greaterThanOrEqualTo(60),
    );
  });
}
