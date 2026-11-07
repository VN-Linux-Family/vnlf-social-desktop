import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/core/api_client.dart';
import 'package:vnlfsocialapp/src/core/io_api_transport.dart';
import 'package:vnlfsocialapp/src/core/session_storage.dart';

void main() {
  test(
    'a delayed old-session read cannot consume the new session cache',
    () async {
      final entered = Completer<void>();
      final resume = Completer<void>();
      var interceptorCalls = 0;
      final client = ApiClient(
        hostKey: Object(),
        throttleInterval: Duration.zero,
        interceptors: [
          (request) async {
            if (++interceptorCalls == 1) {
              entered.complete();
              await resume.future;
            }
            return request;
          },
        ],
        transport: (_) async =>
            ApiResponse(statusCode: 200, body: '{"owner":"new"}'),
      );
      final oldRead = client.get<Map<String, dynamic>>('/private');
      final oldReadCheck = expectLater(oldRead, throwsA(isA<HttpFailure>()));
      await entered.future;
      client.invalidateSession();
      expect(await client.get<Map<String, dynamic>>('/private'), {
        'owner': 'new',
      });
      resume.complete();
      await oldReadCheck;
    },
  );

  test(
    'queued writes and old reads are rejected when the session changes',
    () async {
      final entered = Completer<void>();
      final response = Completer<ApiResponse>();
      final writes = <String>[];
      final client = ApiClient(
        transport: (r) {
          if (r.method != 'GET') {
            writes.add(r.path);
            return Future.value(ApiResponse(statusCode: 200, body: '{}'));
          }
          entered.complete();
          return response.future;
        },
        throttleInterval: Duration.zero,
        hostKey: Object(),
      );
      final reading = client.get<Object?>('/private');
      await entered.future;
      final writing = client.request<void>(
        'POST',
        '/comment',
        body: '{"content":"synthetic"}',
      );
      final readCheck = expectLater(reading, throwsA(isA<HttpFailure>()));
      final writeCheck = expectLater(writing, throwsA(isA<HttpFailure>()));
      client.invalidateSession();
      response.complete(ApiResponse(statusCode: 200, body: '{}'));
      await Future.wait([readCheck, writeCheck]);
      expect(writes, isEmpty);
    },
  );
  test(
    'a write waiting for cookie restoration cannot leave after logout',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      var writes = 0;
      server.listen((r) async {
        writes++;
        r.response.write('{}');
        await r.response.close();
      });
      final storage = _DelayedSession();
      final transport = IoApiTransport(
        Uri.parse('http://127.0.0.1:${server.port}'),
        storage: storage,
      );
      addTearDown(transport.close);
      final writing = transport.call(
        ApiRequest('/write', method: 'POST', body: '{}'),
      );
      await storage.entered.future;
      final check = expectLater(writing, throwsA(isA<HttpFailure>()));
      await transport.clearCookies();
      storage.cookie.complete('synthetic_session=old_account');
      await check;
      expect(writes, 0);
    },
  );
}

class _DelayedSession implements SessionStorage {
  final entered = Completer<void>();
  final cookie = Completer<String?>();
  @override
  Future<String?> read(String key) {
    entered.complete();
    return cookie.future;
  }

  @override
  Future<void> write(String key, String value) async {}
  @override
  Future<void> delete(String key) async {}
}
