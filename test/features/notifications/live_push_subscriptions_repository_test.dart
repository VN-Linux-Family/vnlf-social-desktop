import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/core/api_client.dart';
import 'package:vnlfsocialapp/src/features/notifications/data/live_push_subscriptions_repository.dart';
import 'package:vnlfsocialapp/src/features/notifications/domain/push_subscription_models.dart';

void main() {
  group('LivePushSubscriptionsRepository', () {
    test('fetchConfig returns server VAPID push configuration', () async {
      final requests = <ApiRequest>[];
      final repo = LivePushSubscriptionsRepository(
        ApiClient(
          hostKey: Object(),
          throttleInterval: Duration.zero,
          transport: (request) async {
            requests.add(request);
            return ApiResponse(
              statusCode: 200,
              body: jsonEncode({
                'enabled': true,
                'publicKey': 'BCOsNumxX30zmEd721HqJNBAvbmVV94c1qBTHMmPxi8vnwcwhMsICOAMQ3lVHd2ocA86hqzuXKCKn8ylPiniJNc',
              }),
            );
          },
        ),
      );

      final config = await repo.fetchConfig();
      expect(config.enabled, isTrue);
      expect(config.publicKey, startsWith('BCOsNumx'));
      expect(requests.first.path, '/api/v1/push/config');
      expect(requests.first.method, 'GET');
    });

    test('listSubscriptions returns active endpoint list', () async {
      final repo = LivePushSubscriptionsRepository(
        ApiClient(
          hostKey: Object(),
          throttleInterval: Duration.zero,
          transport: (request) async {
            return ApiResponse(
              statusCode: 200,
              body: jsonEncode({
                'endpoints': ['https://fcm.googleapis.com/fcm/send/token1'],
              }),
            );
          },
        ),
      );

      final list = await repo.listSubscriptions();
      expect(list, ['https://fcm.googleapis.com/fcm/send/token1']);
    });

    test('registerSubscription sends valid JSON payload', () async {
      ApiRequest? sent;
      final repo = LivePushSubscriptionsRepository(
        ApiClient(
          hostKey: Object(),
          throttleInterval: Duration.zero,
          transport: (request) async {
            sent = request;
            return ApiResponse(statusCode: 201, body: jsonEncode({'ok': true}));
          },
        ),
      );

      const payload = PushSubscriptionPayload(
        endpoint: 'https://fcm.googleapis.com/fcm/send/token123',
        p256dh: 'BN4d...',
        auth: '1234...',
      );

      await repo.registerSubscription(payload);
      expect(sent?.method, 'POST');
      expect(sent?.path, '/api/v1/push/subscriptions');
      final decoded = jsonDecode(sent!.body!) as Map<String, dynamic>;
      expect(
        decoded['endpoint'],
        'https://fcm.googleapis.com/fcm/send/token123',
      );
      expect(decoded['keys']['p256dh'], 'BN4d...');
      expect(decoded['keys']['auth'], '1234...');
    });

    test('removeSubscription sends DELETE request', () async {
      ApiRequest? sent;
      final repo = LivePushSubscriptionsRepository(
        ApiClient(
          hostKey: Object(),
          throttleInterval: Duration.zero,
          transport: (request) async {
            sent = request;
            return ApiResponse(statusCode: 200, body: jsonEncode({'ok': true}));
          },
        ),
      );

      await repo.removeSubscription(
        'https://fcm.googleapis.com/fcm/send/token123',
      );
      expect(sent?.method, 'DELETE');
      expect(sent?.path, '/api/v1/push/subscriptions');
      final decoded = jsonDecode(sent!.body!) as Map<String, dynamic>;
      expect(
        decoded['endpoint'],
        'https://fcm.googleapis.com/fcm/send/token123',
      );
    });
  });
}
