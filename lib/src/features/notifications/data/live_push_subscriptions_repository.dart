import 'dart:convert';

import '../../../core/api_client.dart';
import '../../../data/field_reader.dart';
import '../domain/push_subscription_models.dart';
import '../domain/push_subscriptions_repository.dart';

final class LivePushSubscriptionsRepository
    implements PushSubscriptionsRepository {
  const LivePushSubscriptionsRepository(this._client);

  final ApiClient _client;

  @override
  Future<PushConfig> fetchConfig() => _client.get(
    '/api/v1/push/config',
    refresh: true,
    decode: (json) => PushConfig(
      enabled: json['enabled'] == true,
      publicKey: nullableString(json['publicKey'], 'push.publicKey'),
    ),
  );

  @override
  Future<List<String>> listSubscriptions() => _client.get(
    '/api/v1/push/subscriptions',
    refresh: true,
    decode: (json) {
      final endpoints = json['endpoints'];
      if (endpoints is List) {
        return endpoints
            .whereType<String>()
            .where((e) => e.isNotEmpty)
            .toList();
      }
      return const <String>[];
    },
  );

  @override
  Future<void> registerSubscription(PushSubscriptionPayload subscription) =>
      _client.request<void>(
        'POST',
        '/api/v1/push/subscriptions',
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(subscription.toJson()),
        decode: (json) {
          if (json['ok'] != true) {
            throw const ParseFailure('push.registerSubscription');
          }
        },
      );

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
