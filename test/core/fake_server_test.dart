import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/core/api_client.dart';
import 'package:vnlfsocialapp/src/data/fixture_repositories.dart';

void main() {
  test(
    'fake server starts from environment port and serves only fixtures',
    () async {
      final probe = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final port = probe.port;
      await probe.close();
      final process = await Process.start(
        'dart',
        ['run', 'test/fixtures/fake_server.dart'],
        environment: {
          ...Platform.environment,
          'VNLF_FAKE_SERVER_PORT': '$port',
        },
      );
      addTearDown(() async {
        process.kill();
        await process.exitCode;
      });
      final line = await process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .first
          .timeout(const Duration(seconds: 20));
      expect(line, 'Fixture server listening on 127.0.0.1:$port');
      final client = HttpClient();
      addTearDown(() => client.close(force: true));
      final request = await client.getUrl(
        Uri.parse('http://127.0.0.1:$port/api/v1/feed'),
      );
      final response = await request.close();
      expect(response.statusCode, 200);
      final json = jsonDecode(
        await utf8.decoder.bind(response).join(),
      ) as Map<String, dynamic>;
      expect(json, await fixtureTransport(ApiRequest('/api/v1/feed')));
      expect(json['items'], isA<List<dynamic>>());
      expect(json['nextCursor'], isNull);
      final unknown = await (await client.getUrl(
        Uri.parse('http://127.0.0.1:$port/api/v1/unknown'),
      )).close();
      expect(unknown.statusCode, 404);
    },
  );
}
