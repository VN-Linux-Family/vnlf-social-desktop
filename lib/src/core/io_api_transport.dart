import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../domain/models.dart' show StorageFailure;
import 'api_client.dart';
import 'non_redirecting_http_client.dart';
import 'session_storage_contract.dart';

/// Native HTTP transport with persistent, revision-guarded session cookies.
final class IoApiTransport {
  IoApiTransport(
    this.baseUri, {
    this.timeout = const Duration(seconds: 10),
    this.storage,
    this.onStorageFailure,
  }) : _client = HttpClient();

  final Uri baseUri;
  final Duration timeout;
  final HttpClient _client;
  final SessionStorage? storage;
  final void Function(StorageFailure?)? onStorageFailure;
  String? _sessionCookie;
  Future<void>? _cookieInitialization;
  Future<void> _cookieOperations = Future.value();
  int _cookieRevision = 0;
  bool _cookiePersistenceFailed = false;
  bool _closed = false;
  final _communitySockets = <WebSocket>{};
  final _pendingUpgrades = <HttpClient>{};

  Future<void> _initCookie() => _cookieInitialization ??= _readCookie();

  Future<void> _readCookie() async {
    final revision = _cookieRevision;
    if (storage != null) {
      try {
        final cookie = await storage!.read('vnlf_session_cookie');
        if (revision == _cookieRevision) _sessionCookie = cookie;
      } catch (_) {
        if (revision == _cookieRevision) {
          onStorageFailure?.call(const StorageFailure());
        }
      }
    }
  }

  Future<void> clearCookies() {
    final revision = ++_cookieRevision;
    _sessionCookie = null;
    _cookieInitialization = Future.value();
    _closeCommunitySockets();
    return _persistCookie(null, revision);
  }

  /// Upgrades only this server's confirmed endpoint; session material stays here.
  Future<WebSocket> openCommunitySocket(ApiSessionScope scope) async {
    scope.ensureCurrent();
    if (_closed) throw const TransportFailure();
    final revision = _cookieRevision;
    await _initCookie();
    scope.ensureCurrent();
    if (revision != _cookieRevision || _sessionCookie?.isNotEmpty != true) {
      throw const HttpFailure(401);
    }
    if (_closed) throw const TransportFailure();
    final uri = baseUri
        .resolve('/ws/community')
        .replace(scheme: baseUri.scheme == 'https' ? 'wss' : 'ws');
    final client = NonRedirectingHttpClient(HttpClient())
      ..userAgent = ApiClient.userAgent;
    _pendingUpgrades.add(client);
    Future<WebSocket>? upgrade;
    var accepted = false;
    try {
      upgrade = WebSocket.connect(
        uri.toString(),
        headers: {HttpHeaders.cookieHeader: _sessionCookie!},
        customClient: client,
        maxPayloadLength: 1024 * 1024,
      );
      final socket = await upgrade.timeout(timeout);
      accepted = true;
      try {
        scope.ensureCurrent();
        if (revision != _cookieRevision) throw const HttpFailure(401);
        if (_closed) throw const TransportFailure();
      } catch (_) {
        unawaited(socket.close().then<void>((_) {}, onError: (Object _) {}));
        rethrow;
      }
      _communitySockets.add(socket);
      unawaited(
        socket.done.then<void>(
          (_) {
            _communitySockets.remove(socket);
          },
          onError: (Object _) {
            _communitySockets.remove(socket);
          },
        ),
      );
      return socket;
    } on HttpFailure {
      rethrow;
    } catch (_) {
      scope.ensureCurrent();
      if (revision != _cookieRevision) throw const HttpFailure(401);
      throw const TransportFailure();
    } finally {
      if (!accepted && upgrade != null) {
        // The timeout may race a detached upgrade. Close even that late socket.
        unawaited(
          upgrade
              .then<void>((socket) async {
                await socket.close();
              }, onError: (Object _) {})
              .catchError((Object _) {}),
        );
      }
      _pendingUpgrades.remove(client);
      client.close(force: true);
    }
  }

  void _closeCommunitySockets() {
    for (final client in _pendingUpgrades.toList()) {
      client.close(force: true);
    }
    _pendingUpgrades.clear();
    for (final socket in _communitySockets.toList()) {
      unawaited(socket.close().then<void>((_) {}, onError: (Object _) {}));
    }
    _communitySockets.clear();
  }

  Future<void> _persistCookie(String? cookie, int revision) {
    final operation = _cookieOperations.then((_) async {
      if (revision != _cookieRevision) return;
      try {
        if (cookie == null) {
          await storage?.delete('vnlf_session_cookie');
        } else {
          await storage?.write('vnlf_session_cookie', cookie);
        }
        if (revision == _cookieRevision) {
          _cookiePersistenceFailed = false;
          onStorageFailure?.call(null);
        }
      } catch (_) {
        _cookiePersistenceFailed = true;
        onStorageFailure?.call(const StorageFailure());
        throw const StorageFailure();
      }
    });
    // Keep the queue usable after surfacing a failure to the operation's caller.
    _cookieOperations = operation.catchError((Object _) {});
    return operation;
  }

  Future<ApiResponse> call(ApiRequest request) async {
    final cookieRevision = _cookieRevision;
    await _initCookie();
    if (cookieRevision != _cookieRevision) throw const HttpFailure(401);
    final cookie = _sessionCookie;
    final path = Uri.parse(request.path);
    if (path.hasScheme || path.hasAuthority || !path.path.startsWith('/')) {
      throw const TransportFailure();
    }
    final uri = baseUri
        .resolveUri(path)
        .replace(
          queryParameters: {...path.queryParameters, ...request.query}.isEmpty
              ? null
              : {...path.queryParameters, ...request.query},
        );
    final outgoing = await _client
        .openUrl(request.method, uri)
        .timeout(timeout);
    if (cookieRevision != _cookieRevision) {
      unawaited(outgoing.done.then<void>((_) {}, onError: (Object _) {}));
      outgoing.abort();
      throw const HttpFailure(401);
    }
    outgoing.followRedirects = false;
    request.headers.forEach(outgoing.headers.set);

    if (cookie != null &&
        cookie.isNotEmpty &&
        !request.headers.containsKey('Cookie')) {
      outgoing.headers.set('Cookie', cookie);
    }

    if (request.body != null) {
      if (!request.headers.containsKey('Content-Type')) {
        outgoing.headers.set('Content-Type', 'application/json');
      }
      final bytes = utf8.encode(request.body!);
      outgoing.contentLength = bytes.length;
      outgoing.add(bytes);
    }
    final response = await outgoing.close().timeout(timeout);

    final cookies = response.cookies;
    final setCookies = response.headers['set-cookie'];
    final cookieMap = <String, String>{};
    if (_sessionCookie != null && _sessionCookie!.isNotEmpty) {
      for (final pair in _sessionCookie!.split(';')) {
        final idx = pair.indexOf('=');
        if (idx != -1) {
          cookieMap[pair.substring(0, idx).trim()] = pair
              .substring(idx + 1)
              .trim();
        }
      }
    }
    for (final c in cookies) {
      cookieMap[c.name] = c.value;
    }
    if (setCookies != null) {
      for (final sc in setCookies) {
        final part = sc.split(';').first.trim();
        final idx = part.indexOf('=');
        if (idx != -1) {
          cookieMap[part.substring(0, idx).trim()] = part
              .substring(idx + 1)
              .trim();
        }
      }
    }
    if (cookieMap.isNotEmpty &&
        (cookies.isNotEmpty || setCookies != null) &&
        cookieRevision == _cookieRevision) {
      final updatedCookie = cookieMap.entries
          .map((e) => '${e.key}=${e.value}')
          .join('; ');
      if (updatedCookie != _sessionCookie || _cookiePersistenceFailed) {
        _sessionCookie = updatedCookie;
        await _persistCookie(_sessionCookie, cookieRevision);
      }
    }

    final headers = <String, String>{};
    response.headers.forEach(
      (name, values) => headers[name] = values.join(', '),
    );
    final body = await utf8.decoder.bind(response).join().timeout(timeout);
    return ApiResponse(
      statusCode: response.statusCode,
      headers: headers,
      body: body,
    );
  }

  void close() {
    _closed = true;
    _closeCommunitySockets();
    _client.close(force: true);
  }
}
