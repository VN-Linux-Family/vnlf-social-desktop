import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/features/notifications/domain/push_subscription_models.dart';

void main() {
  group('PushSubscriptionModels', () {
    test('PushConfig serializes and deserializes properly', () {
      final config = PushConfig.fromJson({
        'enabled': true,
        'publicKey': 'BCOsNumxX30zmEd721HqJNBAvbmVV94c1qBTHMmPxi8vnwcwhMsICOAMQ3lVHd2ocA86hqzuXKCKn8ylPiniJNc',
      });

      expect(config.enabled, isTrue);
      expect(config.publicKey, startsWith('BCOsNumx'));

      final json = config.toJson();
      expect(json['enabled'], isTrue);
      expect(json['publicKey'], startsWith('BCOsNumx'));
    });

    test('PushSubscriptionPayload serializes matching backend schema', () {
      const payload = PushSubscriptionPayload(
        endpoint: 'https://fcm.googleapis.com/fcm/send/token123',
        p256dh: 'BG3c7bE',
        auth: 'k9Xz_w',
      );

      final json = payload.toJson();
      expect(json['endpoint'], 'https://fcm.googleapis.com/fcm/send/token123');
      expect(json['keys'], isA<Map<String, dynamic>>());
      final keys = json['keys'] as Map<String, dynamic>;
      expect(keys['p256dh'], 'BG3c7bE');
      expect(keys['auth'], 'k9Xz_w');
    });

    test(
      'PushRegistrationState copyWith preserves or overrides properties',
      () {
        const initial = PushRegistrationState();
        expect(initial.phase, PushRegistrationPhase.idle);
        expect(initial.isRegistered, isFalse);

        final registered = initial.copyWith(
          phase: PushRegistrationPhase.registered,
          endpoint: 'https://fcm.googleapis.com/fcm/send/test',
        );
        expect(registered.phase, PushRegistrationPhase.registered);
        expect(registered.isRegistered, isTrue);
        expect(registered.endpoint, 'https://fcm.googleapis.com/fcm/send/test');
      },
    );
  });
}
