import 'dart:convert';
import 'dart:io';

import 'package:vnlfsocialapp/src/core/api_client.dart';
import 'package:vnlfsocialapp/src/core/io_api_transport.dart';
import 'package:vnlfsocialapp/src/core/session_storage_contract.dart'
    show SessionStorage;
import 'package:vnlfsocialapp/src/data/live_auth_repository.dart';

Future<void> main() async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  server.listen((request) async {
    if (request.method != 'GET' || request.uri.path != '/api/v1/auth/session') {
      request.response.statusCode = 404;
      await request.response.close();
      return;
    }
    request.response.headers.contentType = ContentType.json;
    request.response.write(
      jsonEncode({
        'user': {
          'id': 'fixture-owner',
          'username': 'fixture-member',
          'displayName': 'Tiếng Việt: ặ ữ ờ ẫ ệ',
        },
      }),
    );
    await request.response.close();
  });
  final transport = IoApiTransport(
    Uri.parse('http://127.0.0.1:${server.port}'),
    storage: _Memory(),
  );
  try {
    final session = await LiveAuthRepository(
      ApiClient(transport: transport.call, hostKey: Object()),
    ).currentSession();
    if (session?.username != 'fixture-member' ||
        session?.displayName != 'Tiếng Việt: ặ ữ ờ ẫ ệ') {
      throw StateError('Fixture session did not round-trip');
    }
    stdout.writeln('Headless transport fixture session passed.');
  } finally {
    transport.close();
    await server.close(force: true);
  }
}

class _Memory implements SessionStorage {
  final data = <String, String>{};
  @override
  Future<String?> read(String key) async => data[key];
  @override
  Future<void> write(String key, String value) async {
    data[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    data.remove(key);
  }
}
