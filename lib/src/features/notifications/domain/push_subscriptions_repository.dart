/// The server's Web Push settings (`GET /api/v1/push/config`).
final class PushServerConfig {
  const PushServerConfig({required this.enabled, required this.publicKey});

  /// False when the server has no VAPID key configured.
  final bool enabled;

  /// The VAPID public key, base64url encoded; empty when push is off.
  final String publicKey;
}

/// Where the server sends a device's notifications, and the keys it encrypts
/// them for (RFC 8291), like a browser's `PushSubscription.toJSON()`.
final class WebPushSubscription {
  const WebPushSubscription({
    required this.endpoint,
    required this.p256dh,
    required this.auth,
  });

  final String endpoint;

  /// The device's P-256 public key, base64url encoded.
  final String p256dh;

  /// The 16-byte authentication secret, base64url encoded.
  final String auth;

  Map<String, Object?> toJson() => {
    'endpoint': endpoint,
    'keys': {'p256dh': p256dh, 'auth': auth},
  };
}

/// The push subscription calls the website's `push-settings.tsx` makes.
abstract interface class PushSubscriptionsRepository {
  Future<PushServerConfig> config();

  /// The endpoints registered for the current login session.
  Future<List<String>> endpoints();

  /// Registers [subscription] for the current login session.
  Future<void> addSubscription(WebPushSubscription subscription);

  /// Deletes the signed-in account's Web Push subscription for [endpoint].
  Future<void> removeSubscription(String endpoint);
}
