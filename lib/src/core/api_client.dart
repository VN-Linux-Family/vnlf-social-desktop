import 'dart:async';
import 'dart:convert';
import 'dart:math';

import '../domain/models.dart';
export '../domain/models.dart'
    show AppFailure, HttpFailure, ParseFailure, TransportFailure, RateLimited;

final class ApiRequest {
  ApiRequest(
    this.path, {
    this.method = 'GET',
    this.body,
    Map<String, String> headers = const {},
    Map<String, String> query = const {},
  }) : headers = Map.unmodifiable(headers),
       query = Map.unmodifiable(query);
  final String path;
  final String method;
  final String? body;
  final Map<String, String> headers;
  final Map<String, String> query;

  ApiRequest withHeaders(Map<String, String> values) => ApiRequest(
    path,
    method: method,
    body: body,
    headers: {...headers, ...values},
    query: query,
  );
}

final class ApiResponse {
  ApiResponse({
    required this.statusCode,
    required this.body,
    Map<String, String> headers = const {},
  }) : headers = Map.unmodifiable(
         headers.map((key, value) => MapEntry(key.toLowerCase(), value)),
       );
  final int statusCode;
  final Map<String, String> headers;
  final String body;
}

typedef ApiTransport = Future<ApiResponse> Function(ApiRequest request);
typedef ApiInterceptor = Future<ApiRequest> Function(ApiRequest request);
typedef RetryDelay = Future<void> Function(Duration delay);

/// Keeps all stages of an operation bound to the account that started it.
final class ApiSessionScope {
  ApiSessionScope._(this._client, this._generation);
  final ApiClient _client;
  final int _generation;

  void ensureCurrent() {
    if (_generation != _client._sessionRevision) throw const HttpFailure(401);
  }
}

final class ApiClient {
  static const userAgent = 'vlf-flutter-dev/0.1 (unofficial community client)';
  ApiClient({
    required ApiTransport transport,
    List<ApiInterceptor> interceptors = const [],
    RetryDelay? retryDelay,
    Random? random,
    this.throttleInterval = const Duration(milliseconds: 500),
    this.cacheDuration = const Duration(minutes: 1),
    Object? hostKey,
    // The public parameter name is intentionally different from the field.
    // ignore: prefer_initializing_formals
  }) : _transport = transport,
       _interceptors = List.unmodifiable(interceptors),
       _retryDelay = retryDelay ?? Future<void>.delayed,
       _random = random ?? Random(),
       _host = _hosts.putIfAbsent(hostKey ?? _defaultHostKey, _HostPolicy.new);
  static final _defaultHostKey = Object();
  static final _hosts = <Object, _HostPolicy>{};
  final ApiTransport _transport;
  final List<ApiInterceptor> _interceptors;
  final RetryDelay _retryDelay;
  final Random _random;
  final _HostPolicy _host;
  final Duration throttleInterval;
  final Duration cacheDuration;
  final _cache = <String, (DateTime, String)>{};
  int _cacheRevision = 0;
  int _sessionRevision = 0;
  final _sessionListeners = <void Function()>{};

  /// Returns an unsubscribe callback for owner-bound long-lived transports.
  void Function() observeSessionInvalidation(void Function() listener) {
    _sessionListeners.add(listener);
    return () => _sessionListeners.remove(listener);
  }

  ApiSessionScope captureSession() => ApiSessionScope._(this, _sessionRevision);

  /// Reject queued work from the previous account before it reaches transport.
  void invalidateSession() {
    _sessionRevision++;
    clearCache();
    for (final listener in _sessionListeners.toList()) {
      listener();
    }
  }

  void clearCache() {
    _cacheRevision++;
    _cache.clear();
  }

  Future<T> get<T>(
    String path, {
    Map<String, String> query = const {},
    bool refresh = false,
    T Function(Map<String, dynamic>)? decode,
  }) => request<T>('GET', path, query: query, refresh: refresh, decode: decode);

  /// Reads an endpoint whose successful response may be an object or JSON null.
  Future<Map<String, dynamic>?> getNullableObject(
    String path, {
    bool refresh = false,
  }) => _request<Map<String, dynamic>?>(
    'GET',
    path,
    refresh: refresh,
    allowNull: true,
    decode: (value) => value,
  );

  Future<T> request<T>(
    String method,
    String path, {
    Map<String, String> query = const {},
    String? body,
    Map<String, String> headers = const {},
    bool refresh = false,
    T Function(Map<String, dynamic>)? decode,
  }) => _request<T>(
    method,
    path,
    query: query,
    body: body,
    headers: headers,
    refresh: refresh,
    decode: (value) => decode != null ? decode(value!) : value as T,
  );

  Future<T> _request<T>(
    String method,
    String path, {
    Map<String, String> query = const {},
    String? body,
    Map<String, String> headers = const {},
    bool refresh = false,
    bool allowNull = false,
    required T Function(Map<String, dynamic>?) decode,
  }) async {
    final cacheRevision = _cacheRevision;
    final sessionRevision = _sessionRevision;
    final normalizedMethod = method.toUpperCase();
    var request = ApiRequest(
      path,
      method: normalizedMethod,
      body: body,
      query: query,
      headers: {
        'User-Agent': userAgent,
        'Accept': 'application/json',
        if (body != null) 'Content-Type': 'application/json',
        ...headers,
      },
    );
    try {
      for (final interceptor in _interceptors) {
        request = await interceptor(request);
      }
      if (sessionRevision != _sessionRevision) throw const HttpFailure(401);
      final isGet = request.method == 'GET';
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
      final cached = isGet && !refresh ? _cache[key] : null;
      if (cached != null &&
          DateTime.now().difference(cached.$1) < cacheDuration) {
        final value = _decode(cached.$2, allowNull: allowNull);
        return decode(value);
      }
      if (isGet) _cache.remove(key);
      final canRetry =
          request.method == 'GET' ||
          request.method == 'HEAD' ||
          request.method == 'OPTIONS';
      for (var attempt = 0; ; attempt++) {
        ApiResponse response;
        try {
          await _host.acquire(throttleInterval);
          try {
            if (sessionRevision != _sessionRevision) {
              throw const HttpFailure(401);
            }
            response = await _transport(request);
            if (sessionRevision != _sessionRevision) {
              throw const HttpFailure(401);
            }
            _host.record(response.statusCode);
          } finally {
            _host.release();
          }
        } on TimeoutException {
          if (!canRetry || attempt >= 2) throw const TransportFailure();
          await _retryDelay(_backoff(attempt));
          continue;
        }
        if (response.statusCode < 200 || response.statusCode >= 300) {
          final transient =
              response.statusCode == 429 ||
              (response.statusCode >= 500 && response.statusCode <= 599);
          if (!canRetry || !transient || attempt >= 2) {
            String? code;
            try {
              final error = jsonDecode(response.body);
              final value = error is Map ? error['code'] : null;
              if (value is String &&
                  RegExp(r'^[A-Z][A-Z0-9_]{0,79}$').hasMatch(value)) {
                code = value;
              }
            } catch (_) {
              // Proxy errors may be HTML. Preserve the HTTP status either way.
            }
            throw HttpFailure(response.statusCode, code: code);
          }
          await _retryDelay(
            _retryAfter(response.headers['retry-after']) ?? _backoff(attempt),
          );
          continue;
        }
        if (!isGet) clearCache();
        final value = (response.statusCode == 204 || response.statusCode == 205)
            ? <String, dynamic>{}
            : _decode(response.body, allowNull: allowNull);
        final result = decode(value);
        if (isGet &&
            cacheDuration > Duration.zero &&
            cacheRevision == _cacheRevision) {
          if (_cache.length >= 100) _cache.remove(_cache.keys.first);
          _cache[key] = (DateTime.now(), response.body);
        }
        return result;
      }
    } on AppFailure {
      rethrow;
    } catch (_) {
      throw const TransportFailure();
    }
  }

  Map<String, dynamic>? _decode(String body, {bool allowNull = false}) {
    try {
      final decoded = jsonDecode(body);
      if (allowNull && decoded == null) return null;
      if (decoded is! Map<String, dynamic>) throw const FormatException();
      return decoded;
    } on FormatException {
      throw const ParseFailure('response');
    }
  }

  Duration _backoff(int attempt) =>
      Duration(milliseconds: 200 * (1 << attempt) + _random.nextInt(101));

  Duration? _retryAfter(String? value) {
    if (value == null) return null;
    final seconds = int.tryParse(value.trim());
    if (seconds != null) return Duration(seconds: seconds.clamp(0, 60));
    final match = RegExp(
      r'^(?:Mon|Tue|Wed|Thu|Fri|Sat|Sun), (\d{2}) (Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec) (\d{4}) (\d{2}):(\d{2}):(\d{2}) GMT$',
      caseSensitive: false,
    ).firstMatch(value.trim());
    if (match == null) return null;
    const months = [
      'jan',
      'feb',
      'mar',
      'apr',
      'may',
      'jun',
      'jul',
      'aug',
      'sep',
      'oct',
      'nov',
      'dec',
    ];
    final date = DateTime.utc(
      int.parse(match[3]!),
      months.indexOf(match[2]!.toLowerCase()) + 1,
      int.parse(match[1]!),
      int.parse(match[4]!),
      int.parse(match[5]!),
      int.parse(match[6]!),
    );
    final delay = date.difference(DateTime.now().toUtc());
    if (delay < Duration.zero) return Duration.zero;
    return delay > const Duration(seconds: 60)
        ? const Duration(seconds: 60)
        : delay;
  }
}

final class _HostPolicy {
  Future<void> _queue = Future.value();
  final _waiting = <Completer<void>>[];
  int _active = 0;
  int _consecutive429 = 0;
  DateTime? _lastRequest;
  DateTime? _pausedUntil;

  Future<void> acquire(Duration interval) async {
    final previous = _queue;
    final done = Completer<void>();
    _queue = done.future;
    try {
      await previous;
      _checkPause();
      while (_active >= 2) {
        final available = Completer<void>();
        _waiting.add(available);
        await available.future;
        _checkPause();
      }
      final last = _lastRequest;
      while (last != null && DateTime.now().difference(last) < interval) {
        final delay = interval - DateTime.now().difference(last);
        if (delay > Duration.zero) await Future<void>.delayed(delay);
      }
      _checkPause();
      _lastRequest = DateTime.now();
      _active++;
    } finally {
      done.complete();
    }
  }

  void _checkPause() {
    final until = _pausedUntil;
    if (until != null && DateTime.now().isBefore(until)) {
      throw RateLimited(until);
    }
    if (until != null) {
      _pausedUntil = null;
      _consecutive429 = 0;
    }
  }

  void record(int status) {
    if (status == 429) {
      _consecutive429++;
      if (_consecutive429 >= 2) {
        final until = DateTime.now().add(const Duration(minutes: 5));
        _pausedUntil = until;
        throw RateLimited(until);
      }
    } else {
      _consecutive429 = 0;
    }
  }

  void release() {
    _active--;
    if (_waiting.isNotEmpty) _waiting.removeAt(0).complete();
  }
}
