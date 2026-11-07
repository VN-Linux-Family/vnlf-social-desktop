import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/core/api_client.dart';
import 'package:vnlfsocialapp/src/core/io_api_transport.dart';
import 'package:vnlfsocialapp/src/data/fixture_repositories.dart';

void main() {
  test('fake server ignores other port environment variables', () async {
    final environment = Map<String, String>.from(Platform.environment)
      ..remove('VNLF_FAKE_SERVER_PORT')
      ..['PORT'] = '0'
      ..['FAKE_SERVER_PORT'] = '0';
    final process = await Process.start('dart', [
      '--packages=.dart_tool/package_config.json',
      'test/fixtures/fake_server.dart',
    ], environment: environment);
    addTearDown(() => process.kill());
    expect(await process.exitCode.timeout(const Duration(seconds: 3)), 64);
  });

  test(
    'fake server starts from environment port and serves only fixtures',
    () async {
      final probe = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final port = probe.port;
      await probe.close();
      final process = await Process.start(
        'dart',
        [
          '--packages=.dart_tool/package_config.json',
          'test/fixtures/fake_server.dart',
        ],
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
      expect(
        json,
        jsonDecode((await fixtureTransport(ApiRequest('/api/v1/feed'))).body),
      );
      expect(json['items'], isA<List<dynamic>>());
      expect(json['nextCursor'], isNull);
      final transport = IoApiTransport(Uri.parse('http://127.0.0.1:$port'));
      addTearDown(transport.close);
      final api = ApiClient(
        hostKey: Object(),
        transport: transport.call,
        throttleInterval: Duration.zero,
      );
      final page = await api.get<Map<String, dynamic>>('/api/v1/feed');
      expect(page['items'], isA<List<dynamic>>());
      await expectLater(
        api.get<Map<String, dynamic>>('/api/v1/unknown'),
        throwsA(isA<HttpFailure>().having((e) => e.statusCode, 'status', 404)),
      );
      final unknown = await (await client.getUrl(
        Uri.parse('http://127.0.0.1:$port/api/v1/unknown'),
      )).close();
      expect(unknown.statusCode, 404);
    },
  );
}
