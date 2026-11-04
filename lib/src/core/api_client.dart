// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import 'dart:convert';
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
    this.throttleInterval = const Duration(milliseconds: 200),
    this.cacheDuration = const Duration(minutes: 1),
  }) : _transport = transport,
       _interceptors = List.unmodifiable(interceptors),
       _retryDelay = retryDelay ?? Future<void>.delayed,
       _random = random ?? Random();
  final ApiTransport _transport;
  final List<ApiInterceptor> _interceptors;
  final RetryDelay _retryDelay;
  final Random _random;
  final Duration throttleInterval;
  final Duration cacheDuration;
  final _cache = <String, (DateTime, String)>{};
  Future<void> _throttleQueue = Future.value();
  DateTime? _lastRequest;

  void clearCache() => _cache.clear();

  Future<void> _throttle() {
    final previous = _throttleQueue;
    final done = Completer<void>();
    _throttleQueue = done.future;
    return () async {
      try {
        await previous;
        final last = _lastRequest;
        if (last != null) {
          final wait = throttleInterval - DateTime.now().difference(last);
          if (wait > Duration.zero) await Future<void>.delayed(wait);
        }
        _lastRequest = DateTime.now();
      } finally {
        done.complete();
      }
    }();
  }

  Future<T> get<T>(
    String path, {
    Map<String, String> query = const {},
    T Function(Map<String, dynamic>)? decode,
  }) async {
    var request = ApiRequest(
      path,
      query: query,
      headers: const {
        'User-Agent': 'VNLF-Mobile/0.1.0 (native client)',
        'Accept': 'application/json',
      },
    );
    try {
      for (final interceptor in _interceptors) {
        request = await interceptor(request);
      }
      final key = jsonEncode([
        request.path,
        Map.fromEntries(
          request.query.entries.toList()
            ..sort((a, b) => a.key.compareTo(b.key)),
        ),
        Map.fromEntries(
          request.headers.entries.toList()
            ..sort((a, b) => a.key.compareTo(b.key)),
        ),
      ]);
      final cached = _cache[key];
      if (cached != null &&
          DateTime.now().difference(cached.$1) < cacheDuration) {
        final response = jsonDecode(cached.$2) as Map<String, dynamic>;
        return decode != null ? decode(response) : response as T;
      }
      _cache.remove(key);
      for (var attempt = 0; ; attempt++) {
        try {
          await _throttle();
          final response = await _transport(request);
          final result = decode != null ? decode(response) : response as T;
          if (cacheDuration > Duration.zero) {
            if (_cache.length >= 100) _cache.remove(_cache.keys.first);
            _cache[key] = (DateTime.now(), jsonEncode(response));
          }
          return result;
        } on HttpFailure catch (error) {
          if (attempt >= 2 ||
              (error.statusCode != 429 &&
                  (error.statusCode < 500 || error.statusCode > 599))) {
            rethrow;
          }
          await _retryDelay(
            Duration(
              milliseconds: (200 * (1 << attempt)) + _random.nextInt(101),
            ),
          );
        } on TimeoutException {
          if (attempt >= 2) throw const TransportFailure();
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
