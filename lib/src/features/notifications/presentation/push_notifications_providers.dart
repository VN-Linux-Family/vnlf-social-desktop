import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../data/live_push_subscriptions_repository.dart';
import '../data/push_key_generator.dart';
import '../domain/push_subscription_models.dart';
import '../domain/push_subscriptions_repository.dart';

final pushSubscriptionsRepositoryProvider =
    Provider<PushSubscriptionsRepository>((ref) {
      final client = ref.watch(apiClientProvider);
      return LivePushSubscriptionsRepository(client);
    });

final pushConfigProvider = FutureProvider<PushConfig>((ref) async {
  final repo = ref.watch(pushSubscriptionsRepositoryProvider);
  return repo.fetchConfig();
});

final pushRegistrationControllerProvider =
    StateNotifierProvider<PushRegistrationController, PushRegistrationState>((
      ref,
    ) {
      final repo = ref.watch(pushSubscriptionsRepositoryProvider);
      final session = ref.watch(sessionStateProvider);
      return PushRegistrationController(
        repo: repo,
        isAuthenticated: session != null,
      );
    });

class PushRegistrationController extends StateNotifier<PushRegistrationState> {
  PushRegistrationController({
    required this.repo,
    required this.isAuthenticated,
  }) : super(const PushRegistrationState()) {
    if (isAuthenticated) {
      registerDevice();
    }
  }

  final PushSubscriptionsRepository repo;
  final bool isAuthenticated;

  Future<void> registerDevice({bool force = false}) async {
    if (!isAuthenticated) {
      state = state.copyWith(phase: PushRegistrationPhase.idle);
      return;
    }

    state = state.copyWith(phase: PushRegistrationPhase.checking);
    try {
      final config = await repo.fetchConfig();
      if (!config.enabled) {
        state = state.copyWith(phase: PushRegistrationPhase.disabled);
        return;
      }

      final payload = await PushKeyGenerator.getOrCreateSubscription();
      final currentList = await repo.listSubscriptions();

      if (force || !currentList.contains(payload.endpoint)) {
        await repo.registerSubscription(payload);
      }

      state = state.copyWith(
        phase: PushRegistrationPhase.registered,
        endpoint: payload.endpoint,
      );
    } catch (e) {
      state = state.copyWith(
        phase: PushRegistrationPhase.failed,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> unregisterDevice() async {
    if (state.endpoint == null) return;
    try {
      await repo.removeSubscription(state.endpoint!);
      state = const PushRegistrationState(phase: PushRegistrationPhase.idle);
    } catch (e) {
      state = state.copyWith(
        phase: PushRegistrationPhase.failed,
        errorMessage: e.toString(),
      );
    }
  }
}
