import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../data/legacy_push_subscription_cleanup.dart';
import '../data/live_push_subscriptions_repository.dart';

final legacyPushCleanupProvider = Provider<LegacyPushSubscriptionCleanup>(
  (ref) => LegacyPushSubscriptionCleanup(
    LivePushSubscriptionsRepository(ref.watch(apiClientProvider)),
  ),
);
