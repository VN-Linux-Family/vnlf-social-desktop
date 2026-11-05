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

    if (request.body != null) outgoing.write(request.body);
    final response = await outgoing.close().timeout(timeout);

    final setCookies = response.headers['set-cookie'];
    if (setCookies != null && setCookies.isNotEmpty) {
      final cookieParts = <String>[];
      for (final sc in setCookies) {
        final idx = sc.indexOf(';');
        final pair = idx != -1 ? sc.substring(0, idx).trim() : sc.trim();
        if (pair.isNotEmpty) cookieParts.add(pair);
      }
      if (cookieParts.isNotEmpty) {
        _sessionCookie = cookieParts.join('; ');
        try {
          storage?.write('vnlf_session_cookie', _sessionCookie!);
        } catch (_) {}
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

  void close() => _client.close(force: true);
}
