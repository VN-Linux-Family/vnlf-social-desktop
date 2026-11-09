abstract interface class PushSubscriptionsRepository {
  /// Deletes the signed-in account's Web Push subscription for [endpoint].
  Future<void> removeSubscription(String endpoint);
}
