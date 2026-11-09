import 'package:shared_preferences/shared_preferences.dart';

import '../domain/push_subscriptions_repository.dart';

enum LegacyPushCleanupOutcome { nothingStored, removed }

/// Removes the Web Push subscription that v0.1.0 registered from Settings.
///
/// That build sent random bytes as the subscription keys and an invented
/// `fcm.googleapis.com` endpoint. The server cannot encrypt for those keys, so
/// every delivery to the row fails and is retried, and the row counts toward
/// the account's ten-device limit. The endpoint stayed in shared preferences;
/// it is forgotten once the server confirms the delete.
final class LegacyPushSubscriptionCleanup {
  LegacyPushSubscriptionCleanup(
    this._repository, {
    Future<SharedPreferences> Function()? preferences,
  }) : _preferences = preferences ?? SharedPreferences.getInstance;

  static const endpointKey = 'vnlf_push_endpoint';
  static const storedKeys = [endpointKey, 'vnlf_push_p256dh', 'vnlf_push_auth'];

  final PushSubscriptionsRepository _repository;
  final Future<SharedPreferences> Function() _preferences;

  /// Sends at most one delete. A failure propagates and keeps the stored
  /// endpoint, so the next sign-in or launch can try once more.
  Future<LegacyPushCleanupOutcome> run() async {
    final prefs = await _preferences();
    final endpoint = prefs.getString(endpointKey);
    if (endpoint == null || endpoint.isEmpty) {
      await _forget(prefs);
      return LegacyPushCleanupOutcome.nothingStored;
    }
    await _repository.removeSubscription(endpoint);
    await _forget(prefs);
    return LegacyPushCleanupOutcome.removed;
  }

  Future<void> _forget(SharedPreferences prefs) async {
    for (final key in storedKeys) {
      if (prefs.containsKey(key)) await prefs.remove(key);
    }
  }
}
