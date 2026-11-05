import 'dart:convert';
import 'dart:io';

import 'api_client.dart';
import 'session_storage.dart';

/// Opt-in native transport. The application defaults to local fixtures.
final class IoApiTransport {
  IoApiTransport(
    this.baseUri, {
    this.timeout = const Duration(seconds: 10),
    this.storage,
  }) : _client = HttpClient();

  final Uri baseUri;
  final Duration timeout;
  final HttpClient _client;
  final SessionStorage? storage;
  String? _sessionCookie;
  bool _initialized = false;

  Future<void> _initCookie() async {
    if (_initialized) return;
    _initialized = true;
    if (storage != null) {
      try {
        _sessionCookie = await storage!.read('vnlf_session_cookie');
      } catch (_) {}
    }
  }

  void clearCookies() {
    _sessionCookie = null;
    try {
      storage?.delete('vnlf_session_cookie');
    } catch (_) {}
  }

  Future<ApiResponse> call(ApiRequest request) async {
    await _initCookie();
    final path = Uri.parse(request.path);
    if (path.hasScheme || path.hasAuthority || !path.path.startsWith('/')) {
      throw const TransportFailure();
    }
    final uri = baseUri
        .resolveUri(path)
        .replace(queryParameters: request.query.isEmpty ? null : request.query);
    final outgoing = await _client
        .openUrl(request.method, uri)
        .timeout(timeout);
    outgoing.followRedirects = false;
    request.headers.forEach(outgoing.headers.set);

    if (_sessionCookie != null &&
        _sessionCookie!.isNotEmpty &&
        !request.headers.containsKey('Cookie')) {
      outgoing.headers.set('Cookie', _sessionCookie!);
    }

    if (request.body != null) {
      if (!request.headers.containsKey('Content-Type')) {
        outgoing.headers.set('Content-Type', 'application/json');
      }
      outgoing.write(request.body);
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
    if (cookieMap.isNotEmpty) {
      _sessionCookie = cookieMap.entries
          .map((e) => '${e.key}=${e.value}')
          .join('; ');
      try {
        storage?.write('vnlf_session_cookie', _sessionCookie!);
      } catch (_) {}
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

  void close() => _client.close(force: true);
}
