import 'push_subscription_models.dart';

abstract interface class PushSubscriptionsRepository {
  Future<PushConfig> fetchConfig();
  Future<List<String>> listSubscriptions();
  Future<void> registerSubscription(PushSubscriptionPayload subscription);
  Future<void> removeSubscription(String endpoint);
}
