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

  Future<ApiResponse> call(ApiRequest request) async {
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
    if (request.body != null) outgoing.write(request.body);
    final response = await outgoing.close().timeout(timeout);
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
