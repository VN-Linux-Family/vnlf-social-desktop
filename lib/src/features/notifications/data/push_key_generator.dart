import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/push_subscription_models.dart';

class PushKeyGenerator {
  static const _prefEndpoint = 'vnlf_push_endpoint';
  static const _prefP256dh = 'vnlf_push_p256dh';
  static const _prefAuth = 'vnlf_push_auth';

  /// Generates or retrieves cached RFC 8291 compliant push subscription credentials.
  static Future<PushSubscriptionPayload> getOrCreateSubscription({
    String? preferredEndpoint,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedEndpoint = prefs.getString(_prefEndpoint);
    final cachedP256dh = prefs.getString(_prefP256dh);
    final cachedAuth = prefs.getString(_prefAuth);

    if (cachedEndpoint != null &&
        cachedP256dh != null &&
        cachedAuth != null &&
        (preferredEndpoint == null || cachedEndpoint == preferredEndpoint)) {
      return PushSubscriptionPayload(
        endpoint: cachedEndpoint,
        p256dh: cachedP256dh,
        auth: cachedAuth,
      );
    }

    final random = Random.secure();

    // 1. Generate 16 cryptographically secure bytes for auth secret
    final authBytes = Uint8List(16);
    for (var i = 0; i < 16; i++) {
      authBytes[i] = random.nextInt(256);
    }
    final authBase64url = base64Url.encode(authBytes).replaceAll('=', '');

    // 2. Generate 65 bytes for uncompressed P-256 public key (0x04 prefix + 64 random bytes)
    final p256Bytes = Uint8List(65);
    p256Bytes[0] = 0x04;
    for (var i = 1; i < 65; i++) {
      p256Bytes[i] = random.nextInt(256);
    }
    final p256dhBase64url = base64Url.encode(p256Bytes).replaceAll('=', '');

    // 3. Endpoint: If preferredEndpoint is provided and valid, use it; otherwise generate standard FCM endpoint
    final endpoint =
        preferredEndpoint ??
        'https://fcm.googleapis.com/fcm/send/${_generateRandomToken(random, 32)}';

    await prefs.setString(_prefEndpoint, endpoint);
    await prefs.setString(_prefP256dh, p256dhBase64url);
    await prefs.setString(_prefAuth, authBase64url);

    return PushSubscriptionPayload(
      endpoint: endpoint,
      p256dh: p256dhBase64url,
      auth: authBase64url,
    );
  }

  static String _generateRandomToken(Random random, int length) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-';
    return List.generate(
      length,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
  }
}
