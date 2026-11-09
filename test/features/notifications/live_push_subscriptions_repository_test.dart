import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/core/api_client.dart';
import 'package:vnlfsocialapp/src/features/notifications/data/live_push_subscriptions_repository.dart';

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
}
