import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models.dart';

/// Local, non-secret application preferences, separate from session storage.
abstract interface class PreferencesStorage {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

final class SharedPreferencesStorage implements PreferencesStorage {
  SharedPreferencesStorage([SharedPreferencesAsync? preferences])
    : _preferences = preferences;

  SharedPreferencesAsync? _preferences;
  SharedPreferencesAsync get _storage =>
      _preferences ??= SharedPreferencesAsync();

  @override
  Future<String?> read(String key) async {
    try {
      return await _storage.getString(key);
    } catch (_) {
      throw const StorageFailure();
    }
  }

  @override
  Future<void> write(String key, String value) async {
    try {
      await _storage.setString(key, value);
    } catch (_) {
      throw const StorageFailure();
    }
  }
}
