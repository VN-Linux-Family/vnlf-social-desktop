import 'dart:convert';

import '../../../core/api_client.dart';
import '../domain/push_subscriptions_repository.dart';

final class LivePushSubscriptionsRepository
    implements PushSubscriptionsRepository {
  const LivePushSubscriptionsRepository(this._client);

  final ApiClient _client;

  static const _path = '/api/v1/push/subscriptions';

  @override
  Future<PushServerConfig> config() => _client.request<PushServerConfig>(
    'GET',
    '/api/v1/push/config',
    refresh: true,
    decode: (json) {
      final enabled = json['enabled'];
      final key = json['publicKey'];
      if (enabled is! bool) throw const ParseFailure('push.config');
      final publicKey = key is String ? key : '';
      return PushServerConfig(
        enabled: enabled && publicKey.isNotEmpty,
        publicKey: publicKey,
      );
    },
  );

  @override
  Future<List<String>> endpoints() => _client.request<List<String>>(
    'GET',
    _path,
    refresh: true,
    decode: (json) {
      final endpoints = json['endpoints'];
      if (endpoints is! List) throw const ParseFailure('push.endpoints');
      return endpoints.whereType<String>().toList(growable: false);
    },
  );

  @override
  Future<void> addSubscription(WebPushSubscription subscription) =>
      _client.request<void>(
        'POST',
        _path,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(subscription.toJson()),
        decode: (json) {
          if (json['ok'] != true) {
            throw const ParseFailure('push.addSubscription');
          }
        },
      );

  @override
  Future<void> removeSubscription(String endpoint) => _client.request<void>(
    'DELETE',
    _path,
    headers: const {'Content-Type': 'application/json'},
    body: jsonEncode({'endpoint': endpoint}),
    decode: (json) {
      if (json['ok'] != true) {
        throw const ParseFailure('push.removeSubscription');
      }
    },
  );
}
