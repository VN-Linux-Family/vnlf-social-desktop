import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vnlfsocialapp/src/features/notifications/data/push_key_generator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PushKeyGenerator RFC 8291 compliance', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test(
      'generates valid P-256 public key and auth secret matching backend rules',
      () async {
        final payload = await PushKeyGenerator.getOrCreateSubscription();

        expect(
          payload.endpoint,
          startsWith('https://fcm.googleapis.com/fcm/send/'),
        );

        // 1. Verify p256dh is base64url characters only
        expect(RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(payload.p256dh), isTrue);

        // 2. Decode p256dh and check byte length == 65 and first byte == 0x04
        var normalizedP256 = payload.p256dh;
        while (normalizedP256.length % 4 != 0) {
          normalizedP256 += '=';
        }
        final p256Bytes = base64Url.decode(normalizedP256);
        expect(p256Bytes.length, 65);
        expect(p256Bytes[0], 0x04);

        // 3. Verify auth is base64url characters only
        expect(RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(payload.auth), isTrue);

        // 4. Decode auth and check byte length == 16
        var normalizedAuth = payload.auth;
        while (normalizedAuth.length % 4 != 0) {
          normalizedAuth += '=';
        }
        final authBytes = base64Url.decode(normalizedAuth);
        expect(authBytes.length, 16);
      },
    );

    test('returns cached subscription if already generated', () async {
      final first = await PushKeyGenerator.getOrCreateSubscription();
      final second = await PushKeyGenerator.getOrCreateSubscription();

      expect(second.endpoint, first.endpoint);
      expect(second.p256dh, first.p256dh);
      expect(second.auth, first.auth);
    });
  });
}
