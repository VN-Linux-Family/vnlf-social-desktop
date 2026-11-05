import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/app/providers.dart';
import 'package:vnlfsocialapp/src/core/api_client.dart';
import 'package:vnlfsocialapp/src/core/io_api_transport.dart';
import 'package:vnlfsocialapp/src/core/session_storage.dart';
import 'package:vnlfsocialapp/src/data/live_auth_repository.dart';
import 'package:vnlfsocialapp/src/domain/models.dart';

void main() {
  test('changed auth cookies surface storage failure and can be persisted on retry', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final storage = _Storage()..writeFailure = true;
    StorageFailure? failure;
    final transport = IoApiTransport(
      Uri.parse('http://127.0.0.1:${server.port}'),
      storage: storage,
      onStorageFailure: (value) => failure = value,
    );
    addTearDown(transport.close);
    addTearDown(() => server.close(force: true));
    server.listen((request) async {
      request.response.cookies.add(Cookie('synthetic_session', 'renewed'));
      request.response.write('{}');
      await request.response.close();
    });

    await expectLater(
      transport.call(ApiRequest('/session-fixture')),
      throwsA(isA<StorageFailure>()),
    );
    expect(failure, isA<StorageFailure>());
    storage.writeFailure = false;
    await transport.call(ApiRequest('/session-fixture'));
    expect(storage.value, 'synthetic_session=renewed');
    expect(failure, isNull);
  });

  test(
    'public responses do not rewrite an unchanged restored session',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final storage = _Storage()..writeFailure = true;
      final transport = IoApiTransport(
        Uri.parse('http://127.0.0.1:${server.port}'),
        storage: storage,
      );
      addTearDown(transport.close);
      addTearDown(() => server.close(force: true));
      final incomingCookie = Completer<String?>();
      server.listen((request) async {
        incomingCookie.complete(request.headers.value('cookie'));
        request.response.write('{}');
        await request.response.close();
      });

      final response = await transport.call(ApiRequest('/public'));
      expect(response.statusCode, 200);
      expect(await incomingCookie.future, 'synthetic_session=fixture');
    },
  );

  test('unavailable secure storage allows anonymous browsing and records a failure', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final storage = _Storage()..readFailure = true;
    StorageFailure? failure;
    final transport = IoApiTransport(
      Uri.parse('http://127.0.0.1:${server.port}'),
      storage: storage,
      onStorageFailure: (value) => failure = value,
    );
    addTearDown(transport.close);
    addTearDown(() => server.close(force: true));
    final incomingCookie = Completer<String?>();
    server.listen((request) async {
      incomingCookie.complete(request.headers.value('cookie'));
      request.response.write('{}');
      await request.response.close();
    });

    final response = await transport.call(ApiRequest('/public'));
    expect(response.statusCode, 200);
    expect(await incomingCookie.future, isNull);
    expect(failure, isA<StorageFailure>());
  });

  test(
    'logout invalidates a pending session response before another restore',
    () async {
      final pending = Completer<ApiResponse>();
      final started = Completer<void>();
      var sessionReads = 0;
      final client = ApiClient(
        transport: (request) async {
          if (request.method == 'POST' &&
              request.path == '/api/v1/auth/logout') {
            return ApiResponse(statusCode: 200, body: '{}');
          }
          if (request.method == 'GET' &&
              request.path == '/api/v1/auth/session') {
            if (++sessionReads == 1) {
              started.complete();
              return pending.future;
            }
            return ApiResponse(statusCode: 401, body: '{}');
          }
          throw StateError('Unexpected fixture request');
        },
        throttleInterval: Duration.zero,
        hostKey: Object(),
      );
      final repository = LiveAuthRepository(client);
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      final controller = container.read(authControllerProvider.notifier);
      await started.future;
      await controller.logout();
      pending.complete(
        ApiResponse(
          statusCode: 200,
          body: '{"user":{"id":"synthetic-member","username":"thanhvienthu"}}',
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(container.read(sessionStateProvider), isNull);
      await controller.refreshSession();

      expect(container.read(authControllerProvider).valueOrNull, isNull);
      expect(container.read(sessionProvider).valueOrNull, isNull);
      expect(sessionReads, 2);
    },
  );

  test('live logout awaits cleanup even when the request fails', () async {
    final cleanup = Completer<void>();
    final client = ApiClient(
      transport: (_) async => ApiResponse(statusCode: 500, body: '{}'),
      throttleInterval: Duration.zero,
      hostKey: Object(),
    );
    final repository = LiveAuthRepository(
      client,
      onLogout: () => cleanup.future,
    );
    var completed = false;
    final logout = repository.logout();
    final expectation = expectLater(logout, throwsA(isA<HttpFailure>()));
    unawaited(
      logout.then(
        (_) => completed = true,
        onError: (Object _) => completed = true,
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(completed, isFalse);
    cleanup.complete();
    await expectation;
  });

  test('clearing cookies waits for secure deletion before returning', () async {
    final storage = _Storage()..deletion = Completer<void>();
    final transport = IoApiTransport(
      Uri.parse('http://localhost'),
      storage: storage,
    );
    addTearDown(transport.close);
    var completed = false;
    final clearing = Future<void>.sync(transport.clearCookies)
        .then((_) => completed = true);
    await Future<void>.delayed(Duration.zero);
    expect(completed, isFalse);
    storage.deletion!.complete();
    await clearing;
    expect(storage.value, isNull);
  });

  test(
    'secure deletion failure is typed and cookies stay cleared in memory',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final storage = _Storage()..deletionFailure = true;
      final transport = IoApiTransport(
        Uri.parse('http://127.0.0.1:${server.port}'),
        storage: storage,
      );
      addTearDown(transport.close);
      addTearDown(() => server.close(force: true));
      final incomingCookie = Completer<String?>();
      server.listen((request) async {
        incomingCookie.complete(request.headers.value('cookie'));
        request.response.write('{}');
        await request.response.close();
      });

      await expectLater(
        transport.clearCookies(),
        throwsA(isA<StorageFailure>()),
      );
      await transport.call(ApiRequest('/public'));
      expect(await incomingCookie.future, isNull);
      storage.deletionFailure = false;
      await transport.clearCookies();
      expect(storage.value, isNull);
    },
  );

  test(
    'a response arriving after cookie cleanup cannot persist a session',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final storage = _Storage();
      final transport = IoApiTransport(
        Uri.parse('http://127.0.0.1:${server.port}'),
        storage: storage,
      );
      addTearDown(transport.close);
      addTearDown(() => server.close(force: true));
      final requestArrived = Completer<HttpRequest>();
      server.listen(requestArrived.complete);

      final response = transport.call(ApiRequest('/pending'));
      final request = await requestArrived.future;
      await Future<void>.sync(transport.clearCookies);
      request.response.cookies.add(Cookie('synthetic_session', 'fixture'));
      request.response.write('{}');
      await request.response.close();
      await response;

      expect(storage.value, isNull);
    },
  );

  test(
    'clearing before the first request prevents restoring stored cookies',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final storage = _Storage()..deletion = Completer<void>();
      final transport = IoApiTransport(
        Uri.parse('http://127.0.0.1:${server.port}'),
        storage: storage,
      );
      addTearDown(transport.close);
      addTearDown(() => server.close(force: true));
      final incomingCookie = Completer<String?>();
      server.listen((request) async {
        incomingCookie.complete(request.headers.value('cookie'));
        request.response.write('{}');
        await request.response.close();
      });

      final clearing = Future<void>.sync(transport.clearCookies);
      await transport.call(ApiRequest('/public'));
      expect(await incomingCookie.future, isNull);
      storage.deletion!.complete();
      await clearing;
    },
  );
}

class _Storage implements SessionStorage {
  String? value = 'synthetic_session=fixture';
  Completer<void>? deletion;
  bool deletionFailure = false;
  bool readFailure = false;
  bool writeFailure = false;

  @override
  Future<String?> read(String key) async {
    if (readFailure) throw const StorageFailure();
    return value;
  }

  @override
  Future<void> write(String key, String value) async {
    if (writeFailure) throw const StorageFailure();
    this.value = value;
  }

  @override
  Future<void> delete(String key) async {
    await deletion?.future;
    if (deletionFailure) throw StateError('synthetic storage failure');
    value = null;
  }
}
