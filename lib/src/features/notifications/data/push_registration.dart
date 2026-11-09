import '../../../domain/models.dart';
import '../domain/push_distributor.dart';
import '../domain/push_subscriptions_repository.dart';

/// Whether this device gets the server's push notifications.
typedef PushDeviceState = ({PushServerConfig config, bool enabled});

/// Turns this device's push notifications on and off, following the
/// website's `push-settings.tsx` step by step with a [PushDistributor] in
/// place of the browser's `PushManager`.
///
/// Writes are never retried: a failure reaches the caller, which shows it
/// and lets the member press again.
final class PushRegistration {
  const PushRegistration(this._repository, this._distributor);

  final PushSubscriptionsRepository _repository;
  final PushDistributor _distributor;

  /// Like `loadPushState`: on only when the device's subscription was made
  /// for the server's current key and is registered for this session.
  Future<PushDeviceState> load() async {
    final (config, saved, held) = await (
      _repository.config(),
      _repository.endpoints(),
      _distributor.current(),
    ).wait;
    return (
      config: config,
      enabled:
          held != null &&
          held.serverKey == config.publicKey &&
          saved.contains(held.subscription.endpoint),
    );
  }

  /// Like `enablePushNotifications`.
  Future<void> enable(PushServerConfig config) async {
    if (!config.enabled) {
      throw ArgumentError.value(config, 'config', 'push is off on the server');
    }
    final held = await _distributor.current();
    final reusable = held != null && held.serverKey == config.publicKey
        ? held.subscription
        : null;
    if (held != null && reusable == null) {
      await _distributor.unsubscribe();
      try {
        await _repository.removeSubscription(held.subscription.endpoint);
      } on AppFailure {
        // The website goes on too: the dropped endpoint now answers 404 or
        // 410, and the server's push worker deletes the row on that answer.
      }
    }
    final subscription =
        reusable ?? await _distributor.subscribe(config.publicKey);
    try {
      await _repository.addSubscription(subscription);
    } on Object {
      if (reusable == null) await _distributor.unsubscribe();
      rethrow;
    }
  }

  /// Like the settings page's `disable`.
  Future<void> disable() async {
    final held = await _distributor.current();
    if (held == null) return;
    await _repository.removeSubscription(held.subscription.endpoint);
    await _distributor.unsubscribe();
  }
}
