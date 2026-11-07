import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/core/api_client.dart';
import 'package:vnlfsocialapp/src/core/io_api_transport.dart';
import 'package:vnlfsocialapp/src/core/session_storage_contract.dart';
import 'package:vnlfsocialapp/src/features/realtime/data/io_community_connection.dart';

void main() {
  late HttpServer server;
  late IoApiTransport transport;
  late ApiClient client;
  late _Storage storage;
  late Completer<HttpRequest> arrived;
  late Completer<void> upgradeGate;
  final peers = <WebSocket>[];
  final paths = <String>[];
  var redirectUpgrade = false;
  setUp(() async {
    paths.clear();
    redirectUpgrade = false;
    peers.clear();
    arrived = Completer<HttpRequest>();
    upgradeGate = Completer<void>();
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      paths.add(request.uri.path);
      if (!arrived.isCompleted) arrived.complete(request);
      await upgradeGate.future;
      if (redirectUpgrade && request.uri.path == '/ws/community') {
        request.response.statusCode = HttpStatus.found;
        request.response.persistentConnection = false;
        request.response.headers.set(
          HttpHeaders.locationHeader,
          '/other-socket',
        );
        await request.response.close();
        return;
      }
      try {
        final socket = await WebSocketTransformer.upgrade(request);
        peers.add(socket);
        socket.listen(socket.add, onError: (_) {}, onDone: () {});
      } catch (_) {
        await request.response.close().catchError((_) {});
      }
    });
    storage = _Storage()..value = 'fixture_cookie=fixture';
    transport = IoApiTransport(
      Uri.parse('http://127.0.0.1:${server.port}'),
      storage: storage,
    );
    client = ApiClient(transport: transport.call, hostKey: Object());
  });
  tearDown(() async {
    transport.close();
    if (!upgradeGate.isCompleted) upgradeGate.complete();
    for (final peer in peers) {
      await peer.close();
    }
    await server.close(force: true);
  });
  test(
    'upgrade uses the original origin, restored cookie and clear user agent',
    () async {
      upgradeGate.complete();
      final connection = await IoCommunityConnection.connect(
        transport,
        client.captureSession(),
      );
      final request = await arrived.future;
      expect(request.uri.path, '/ws/community');
      expect(
        request.headers.value(HttpHeaders.cookieHeader),
        'fixture_cookie=fixture',
      );
      expect(
        request.headers.value(HttpHeaders.userAgentHeader),
        ApiClient.userAgent,
      );
      expect(
        request.headers.value('origin'),
        'http://127.0.0.1:${server.port}',
      );
      final echoed = connection.frames.first;
      connection.send('{"synthetic":true}');
      expect(await echoed, '{"synthetic":true}');
      await connection.close();
      expect(() => connection.send('{}'), throwsA(isA<TransportFailure>()));
    },
  );
  test('missing session cookie refuses an authenticated upgrade', () async {
    storage.value = null;
    upgradeGate.complete();
    await expectLater(
      transport.openCommunitySocket(client.captureSession()),
      throwsA(isA<HttpFailure>()),
    );
    expect(arrived.isCompleted, isFalse);
  });
  test(
    'an authenticated upgrade refuses redirects to another endpoint',
    () async {
      redirectUpgrade = true;
      upgradeGate.complete();
      await expectLater(
        transport.openCommunitySocket(client.captureSession()),
        throwsA(isA<TransportFailure>()),
      );
      expect(paths, ['/ws/community']);
    },
  );
  test(
    'clearing cookies during restoration cannot open a stale session',
    () async {
      storage.readGate = Completer<String?>();
      final pending = transport.openCommunitySocket(client.captureSession());
      await storage.readEntered.future;
      await transport.clearCookies();
      storage.readGate!.complete('fixture_cookie=stale');
      await expectLater(pending, throwsA(isA<HttpFailure>()));
      expect(arrived.isCompleted, isFalse);
    },
  );
  test(
    'account change during upgrade closes the eventual stale connection',
    () async {
      final pending = transport.openCommunitySocket(client.captureSession());
      await arrived.future;
      client.invalidateSession();
      upgradeGate.complete();
      await expectLater(pending, throwsA(isA<HttpFailure>()));
    },
  );
  test('cookie cleanup closes already connected sockets', () async {
    upgradeGate.complete();
    final socket = await transport.openCommunitySocket(client.captureSession());
    final closed = Completer<void>();
    socket.listen((_) {}, onError: (_) {}, onDone: closed.complete);
    await transport.clearCookies();
    await closed.future.timeout(const Duration(seconds: 2));
    expect(socket.readyState, WebSocket.closed);
  });
  test('closing transport interrupts pending upgrades', () async {
    final pending = transport.openCommunitySocket(client.captureSession());
    await arrived.future;
    transport.close();
    await expectLater(
      pending.timeout(const Duration(seconds: 2)),
      throwsA(isA<AppFailure>()),
    );
  });
  test('an upgrade timeout releases its pending network request', () async {
    transport.close();
    transport = IoApiTransport(
      Uri.parse('http://127.0.0.1:${server.port}'),
      storage: storage,
      timeout: const Duration(milliseconds: 80),
    );
    client = ApiClient(transport: transport.call, hostKey: Object());
    await expectLater(
      transport.openCommunitySocket(client.captureSession()),
      throwsA(isA<TransportFailure>()),
    );
    expect(arrived.isCompleted, isTrue);
  });
}

class _Storage implements SessionStorage {
  String? value;
  Completer<String?>? readGate;
  final readEntered = Completer<void>();
  @override
  Future<String?> read(String key) async {
    if (!readEntered.isCompleted) readEntered.complete();
    return readGate == null ? value : readGate!.future;
  }

  @override
  Future<void> write(String key, String next) async {
    value = next;
  }

  @override
  Future<void> delete(String key) async {
    value = null;
  }
}
