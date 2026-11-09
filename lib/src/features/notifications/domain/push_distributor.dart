import 'push_subscriptions_repository.dart';

/// A subscription a [PushDistributor] holds, with the server key it was made
/// for.
typedef HeldPushSubscription = ({
  WebPushSubscription subscription,
  String serverKey,
});

/// A push service on this device that receives the server's Web Push
/// messages, such as a UnifiedPush distributor on Android. It plays the part
/// of a browser's `PushManager`: it makes an endpoint with keys for the
/// server's VAPID key, and decrypts what arrives there.
///
/// No build ships one yet; `docs/contracts/native-push.md` describes what
/// the server and the app each need.
abstract interface class PushDistributor {
  /// The subscription this device holds, or null.
  Future<HeldPushSubscription?> current();

  /// Makes a subscription for the server's VAPID [serverKey].
  Future<WebPushSubscription> subscribe(String serverKey);

  /// Drops the subscription this device holds.
  Future<void> unsubscribe();
}
