import 'dart:convert';

import '../../../core/api_client.dart';
import '../domain/push_subscriptions_repository.dart';

final class LivePushSubscriptionsRepository
    implements PushSubscriptionsRepository {
  const LivePushSubscriptionsRepository(this._client);

  final ApiClient _client;

  @override
  Future<void> removeSubscription(String endpoint) => _client.request<void>(
    'DELETE',
    '/api/v1/push/subscriptions',
    headers: const {'Content-Type': 'application/json'},
    body: jsonEncode({'endpoint': endpoint}),
    decode: (json) {
      if (json['ok'] != true) {
        throw const ParseFailure('push.removeSubscription');
      }
    },
  );
}
