// ignore_for_file: prefer_initializing_formals

import 'dart:math';

import '../domain/models.dart';
export '../domain/models.dart'
    show AppFailure, HttpFailure, ParseFailure, TransportFailure;

/// A request addressed to a fixture transport; no network transport is supplied.
final class ApiRequest {
  ApiRequest(
    this.path, {
    Map<String, String> headers = const {},
    Map<String, String> query = const {},
  }) : headers = Map.unmodifiable(headers),
       query = Map.unmodifiable(query);
  final String path;
  final Map<String, String> headers;
  final Map<String, String> query;

  ApiRequest withHeaders(Map<String, String> values) =>
      ApiRequest(path, headers: {...headers, ...values}, query: query);
}

typedef ApiTransport = Future<Map<String, dynamic>> Function(
  ApiRequest request,
);
typedef ApiInterceptor = Future<ApiRequest> Function(ApiRequest request);
typedef RetryDelay = Future<void> Function(Duration delay);

/// The transport must be supplied explicitly; the application uses local fixtures.
final class ApiClient {
  ApiClient({
    required ApiTransport transport,
    List<ApiInterceptor> interceptors = const [],
    RetryDelay? retryDelay,
    Random? random,
  }) : _transport = transport,
       _interceptors = List.unmodifiable(interceptors),
       _retryDelay = retryDelay ?? Future<void>.delayed,
       _random = random ?? Random();
  final ApiTransport _transport;
  final List<ApiInterceptor> _interceptors;
  final RetryDelay _retryDelay;
  final Random _random;

  Future<T> get<T>(
    String path, {
    Map<String, String> query = const {},
    T Function(Map<String, dynamic>)? decode,
  }) async {
    var request = ApiRequest(path, query: query);
    try {
      for (final interceptor in _interceptors) {
        request = await interceptor(request);
      }
      for (var attempt = 0; ; attempt++) {
        try {
          final response = await _transport(request);
          if (decode != null) return decode(response);
          return response as T;
        } on HttpFailure catch (error) {
          if (attempt >= 2 ||
              (error.statusCode != 429 && error.statusCode != 503)) {
            rethrow;
          }
          await _retryDelay(
            Duration(
              milliseconds: (200 * (1 << attempt)) + _random.nextInt(101),
            ),
          );
        }
      }
    } on AppFailure {
      rethrow;
    } catch (_) {
      throw const TransportFailure();
    }
  }
}
