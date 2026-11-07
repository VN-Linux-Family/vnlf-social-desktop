import 'dart:convert';

import '../../../core/api_client.dart';
import 'preferences.dart';

final class PreferencesRepository {
  PreferencesRepository(this._client, this.ownerId, this._currentOwner)
    : _scope = _client.captureSession();

  final ApiClient _client;
  final String ownerId;
  final String? Function() _currentOwner;
  final ApiSessionScope _scope;
  static const _path = '/api/v1/me/preferences';

  void _guard() {
    _scope.ensureCurrent();
    if (ownerId.isEmpty || _currentOwner() != ownerId) {
      throw const HttpFailure(401);
    }
  }

  Future<WebsitePreferences> load() async {
    _guard();
    final json = await _client.getNullableObject(_path, refresh: true);
    _guard();
    return WebsitePreferences.fromJson(json);
  }

  Future<void> save(
    WebsitePreferences saved,
    WebsitePreferences preferences,
  ) async {
    _guard();
    final oldValues = saved.toJson();
    final changes = Map.of(preferences.toJson())
      ..removeWhere((key, value) => oldValues[key] == value);
    if (changes.isEmpty) return;
    await _client.request<void>(
      'PATCH',
      _path,
      body: jsonEncode(changes),
      decode: (json) {
        if (json['ok'] != true) throw const ParseFailure('preferences.ack');
      },
    );
    _guard();
  }
}
