import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vnlfsocialapp/src/domain/models.dart';
import 'package:vnlfsocialapp/src/features/notifications/data/legacy_push_subscription_cleanup.dart';
import 'package:vnlfsocialapp/src/features/notifications/domain/push_subscriptions_repository.dart';

const _legacyEndpoint = 'https://fcm.googleapis.com/fcm/send/synthetic-legacy';

void main() {
  late _Repository repository;
  late LegacyPushSubscriptionCleanup cleanup;

  setUp(() {
    repository = _Repository();
    cleanup = LegacyPushSubscriptionCleanup(repository);
  });

  test('does nothing when no legacy subscription was stored', () async {
    SharedPreferences.setMockInitialValues({});

    expect(await cleanup.run(), LegacyPushCleanupOutcome.nothingStored);
    expect(repository.removed, isEmpty);
  });

  test('deletes the stored subscription and forgets its keys', () async {
    SharedPreferences.setMockInitialValues({
      'vnlf_push_endpoint': _legacyEndpoint,
      'vnlf_push_p256dh': 'synthetic-key',
      'vnlf_push_auth': 'synthetic-auth',
      'android_background_sync': true,
    });

    expect(await cleanup.run(), LegacyPushCleanupOutcome.removed);

    expect(repository.removed, [_legacyEndpoint]);
    final prefs = await SharedPreferences.getInstance();
    for (final key in LegacyPushSubscriptionCleanup.storedKeys) {
      expect(prefs.containsKey(key), isFalse, reason: key);
    }
    expect(prefs.getBool('android_background_sync'), isTrue);
  });

  test('a failed delete keeps the endpoint for the next sign-in', () async {
    SharedPreferences.setMockInitialValues({
      'vnlf_push_endpoint': _legacyEndpoint,
      'vnlf_push_p256dh': 'synthetic-key',
      'vnlf_push_auth': 'synthetic-auth',
    });
    repository.failure = const TransportFailure();

    await expectLater(cleanup.run(), throwsA(isA<TransportFailure>()));

    expect(repository.removed, [_legacyEndpoint]);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('vnlf_push_endpoint'), _legacyEndpoint);

    repository.failure = null;
    expect(await cleanup.run(), LegacyPushCleanupOutcome.removed);
    expect(repository.removed, [_legacyEndpoint, _legacyEndpoint]);
    expect(prefs.containsKey('vnlf_push_endpoint'), isFalse);
  });

  test('forgets stray keys even without an endpoint', () async {
    SharedPreferences.setMockInitialValues({
      'vnlf_push_p256dh': 'synthetic-key',
      'vnlf_push_auth': 'synthetic-auth',
    });

    expect(await cleanup.run(), LegacyPushCleanupOutcome.nothingStored);

    expect(repository.removed, isEmpty);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getKeys(), isEmpty);
  });
}

final class _Repository implements PushSubscriptionsRepository {
  final removed = <String>[];
  AppFailure? failure;

  @override
  Future<void> removeSubscription(String endpoint) async {
    removed.add(endpoint);
    if (failure case final failure?) throw failure;
  }
}
