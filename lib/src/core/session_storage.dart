import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../domain/models.dart';
import 'api_client.dart';

/// Opaque session data only; the server's cookie and CSRF contracts are unknown.
abstract interface class SessionStorage {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

final class SecureSessionStorage implements SessionStorage {
  const SecureSessionStorage([this._storage = const FlutterSecureStorage()]);
  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (_) {
      throw const StorageFailure();
    }
  }

  @override
  Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (_) {
      throw const StorageFailure();
    }
  }

  @override
  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (_) {
      throw const StorageFailure();
    }
  }
}

/// Adds only header names and values explicitly supplied by the caller.
Future<Map<String, String>> readSessionHeaders(
  SessionStorage storage,
  Map<String, String> headerKeys,
) async {
  final headers = <String, String>{};
  for (final entry in headerKeys.entries) {
    final value = await storage.read(entry.value);
    if (value != null) headers[entry.key] = value;
  }
  return headers;
}

/// Creates an interceptor for explicitly configured session and CSRF headers.
ApiInterceptor sessionHeadersInterceptor(
  SessionStorage storage,
  Map<String, String> headerKeys,
) =>
    (request) async =>
        request.withHeaders(await readSessionHeaders(storage, headerKeys));
