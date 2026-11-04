import 'dart:convert';
import 'dart:io';

import 'api_client.dart';

/// Opt-in native transport. The application defaults to local fixtures.
final class IoApiTransport {
  IoApiTransport(this.baseUri, {this.timeout = const Duration(seconds: 10)})
    : _client = HttpClient();

  final Uri baseUri;
  final Duration timeout;
  final HttpClient _client;

  Future<Map<String, dynamic>> call(ApiRequest request) async {
    final path = Uri.parse(request.path);
    if (path.hasScheme || path.hasAuthority || !path.path.startsWith('/')) {
      throw const TransportFailure();
    }
    final uri = baseUri
        .resolveUri(path)
        .replace(queryParameters: request.query.isEmpty ? null : request.query);
    final outgoing = await _client.getUrl(uri).timeout(timeout);
    outgoing.followRedirects = false;
    request.headers.forEach(outgoing.headers.set);
    final response = await outgoing.close().timeout(timeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      await response.drain<void>().timeout(timeout);
      throw HttpFailure(response.statusCode);
    }
    final body = await utf8.decoder.bind(response).join().timeout(timeout);
    try {
      final value = jsonDecode(body);
      if (value is! Map<String, dynamic>) throw const FormatException();
      return value;
    } on FormatException {
      throw const ParseFailure('response');
    }
  }

  void close() => _client.close(force: true);
}
