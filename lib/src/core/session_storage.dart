import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../domain/models.dart';
import 'api_client.dart';
import 'session_storage_contract.dart';
export 'session_storage_contract.dart';

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
