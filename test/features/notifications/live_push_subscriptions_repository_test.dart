import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/core/api_client.dart';
import 'package:vnlfsocialapp/src/features/notifications/data/live_push_subscriptions_repository.dart';
import 'package:vnlfsocialapp/src/features/notifications/domain/push_subscriptions_repository.dart';

const _endpoint = 'https://fcm.googleapis.com/fcm/send/synthetic-token';

void main() {
  group('LivePushSubscriptionsRepository.removeSubscription', () {
    late List<ApiRequest> requests;

    LivePushSubscriptionsRepository repository(ApiResponse response) {
      requests = [];
      return LivePushSubscriptionsRepository(
        ApiClient(
          hostKey: Object(),
          throttleInterval: Duration.zero,
          transport: (request) async {
            requests.add(request);
            return response;
          },
        ),
      );
    }

    test('sends the endpoint as a JSON DELETE body', () async {
      await repository(
        ApiResponse(statusCode: 200, body: jsonEncode({'ok': true})),
      ).removeSubscription(_endpoint);

      expect(requests, hasLength(1));
      expect(requests.single.method, 'DELETE');
      expect(requests.single.path, '/api/v1/push/subscriptions');
      expect(jsonDecode(requests.single.body!), {'endpoint': _endpoint});
    });

    test('requires the server acknowledgement', () async {
      final repo = repository(
        ApiResponse(statusCode: 200, body: jsonEncode({'ok': false})),
      );

      await expectLater(
        repo.removeSubscription(_endpoint),
        throwsA(isA<ParseFailure>()),
      );
    });

    test('does not retry a failed delete', () async {
      final repo = repository(
        ApiResponse(
          statusCode: 503,
          body: jsonEncode({
            'error': {'code': 'UNAVAILABLE', 'retryable': true},
          }),
        ),
      );

      await expectLater(
        repo.removeSubscription(_endpoint),
        throwsA(isA<HttpFailure>()),
      );
      expect(requests, hasLength(1));
    });
  });

  group('LivePushSubscriptionsRepository reads and registers', () {
    late List<ApiRequest> requests;

    LivePushSubscriptionsRepository repository(List<ApiResponse> responses) {
      requests = [];
      return LivePushSubscriptionsRepository(
        ApiClient(
          hostKey: Object(),
          throttleInterval: Duration.zero,
          retryDelay: (_) async {},
          transport: (request) async {
            requests.add(request);
            return responses[requests.length - 1];
          },
        ),
      );
    }

    test('reads the server config and the session endpoints', () async {
      final repo = repository([
        ApiResponse(
          statusCode: 200,
          body: jsonEncode({'enabled': true, 'publicKey': 'BAbc-_'}),
        ),
        ApiResponse(
          statusCode: 200,
          body: jsonEncode({
            'endpoints': [_endpoint, 7],
          }),
        ),
        ApiResponse(statusCode: 200, body: jsonEncode({'enabled': false})),
      ]);
      final config = await repo.config();
      expect(requests.single.path, '/api/v1/push/config');
      expect((config.enabled, config.publicKey), (true, 'BAbc-_'));
      expect(await repo.endpoints(), [_endpoint]);
      expect(requests.last.path, '/api/v1/push/subscriptions');
      final off = await repo.config();
      expect((off.enabled, off.publicKey), (false, ''));
    });

    test('registers a subscription with its keys, once', () async {
      const subscription = WebPushSubscription(
        endpoint: _endpoint,
        p256dh: 'BPublicKey',
        auth: 'secret',
      );
      await repository([
        ApiResponse(statusCode: 201, body: jsonEncode({'ok': true})),
      ]).addSubscription(subscription);
      expect(requests.single.method, 'POST');
      expect(jsonDecode(requests.single.body!), {
        'endpoint': _endpoint,
        'keys': {'p256dh': 'BPublicKey', 'auth': 'secret'},
      });

      final limited = repository([
        ApiResponse(
          statusCode: 429,
          body: jsonEncode({
            'code': 'PUSH_DEVICE_LIMIT',
            'message': 'Đã đạt giới hạn 10 thiết bị.',
          }),
        ),
      ]);
      await expectLater(
        limited.addSubscription(subscription),
        throwsA(
          isA<HttpFailure>().having(
            (failure) => failure.code,
            'code',
            'PUSH_DEVICE_LIMIT',
          ),
        ),
      );
      expect(requests, hasLength(1));
    });
  });
}
