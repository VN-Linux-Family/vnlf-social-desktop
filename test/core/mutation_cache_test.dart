import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/core/api_client.dart';
import 'package:vnlfsocialapp/src/core/io_api_transport.dart';

void main() {
  test('native writes encode Vietnamese JSON as UTF-8', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    String? received;
    server.listen((request) async {
      received = await utf8.decoder.bind(request).join();
      request.response.write('{}');
      await request.response.close();
    });
    final transport = IoApiTransport(
      Uri.parse('http://127.0.0.1:${server.port}'),
    );
    addTearDown(transport.close);
    const body = '{"content":"Tiếng Việt: ặ ữ ờ ẫ ệ"}';
    await transport.call(ApiRequest('/comment', method: 'POST', body: body));
    expect(received, body);
  });
  test(
    'successful writes invalidate cached reads and earlier pending reads',
    () async {
      var count = 0;
      final client = ApiClient(
        throttleInterval: Duration.zero,
        hostKey: Object(),
        transport: (request) async {
          if (request.method == 'POST') count++;
          return ApiResponse(
            statusCode: 200,
            body: jsonEncode({'count': count}),
          );
        },
      );
      expect(await client.get('/article', decode: (j) => j['count']), 0);
      await client.request<void>('POST', '/comment');
      expect(await client.get('/article', decode: (j) => j['count']), 1);
    },
  );
  test('explicit refresh bypasses cached GET data without affecting other cached paths', () async {
    final counts = <String, int>{};
    final client = ApiClient(
      hostKey: Object(),
      throttleInterval: Duration.zero,
      transport: (request) async {
        counts.update(request.path, (value) => value + 1, ifAbsent: () => 1);
        return ApiResponse(
          statusCode: 200,
          body: jsonEncode({'count': counts[request.path]}),
        );
      },
    );
    await client.get<Map<String, dynamic>>('/other');
    expect(await client.get('/messages', decode: (json) => json['count']), 1);
    expect(await client.get('/messages', decode: (json) => json['count']), 1);
    expect(
      await client.get(
        '/messages',
        refresh: true,
        decode: (json) => json['count'],
      ),
      2,
    );
    await client.get<Map<String, dynamic>>('/other');
    expect(counts['/other'], 1);
  });

  test(
    '204 acknowledgments succeed without attempting to decode empty JSON',
    () async {
      final client = ApiClient(
        throttleInterval: Duration.zero,
        hostKey: Object(),
        transport: (_) async => ApiResponse(statusCode: 204, body: ''),
      );
      await expectLater(client.request<void>('DELETE', '/comment'), completes);
    },
  );
  test(
    'native transport preserves path query and merges explicit query',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      Uri? requested;
      server.listen((request) async {
        requested = request.uri;
        request.response.write('{}');
        await request.response.close();
      });
      final transport = IoApiTransport(
        Uri.parse('http://127.0.0.1:${server.port}'),
      );
      addTearDown(transport.close);
      await transport.call(
        ApiRequest('/api/v1/search?q=linux&type=all', query: {'limit': '20'}),
      );
      expect(requested!.queryParameters, {
        'q': 'linux',
        'type': 'all',
        'limit': '20',
      });
    },
  );
}
