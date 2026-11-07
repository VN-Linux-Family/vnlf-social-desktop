import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../data/live_security_sessions_repository.dart';
import '../domain/security_sessions.dart';

final class SecuritySessionsState {
  const SecuritySessionsState({
    this.items,
    this.loading = false,
    this.failed = false,
    this.uncertain = false,
    this.confirmed = false,
  });
  final List<SecuritySession>? items;
  final bool loading;
  final bool failed;
  final bool uncertain;
  final bool confirmed;
}

final class SecuritySessionsController
    extends StateNotifier<SecuritySessionsState> {
  SecuritySessionsController(this.repository)
    : super(const SecuritySessionsState()) {
    unawaited(refresh());
  }
  final SecuritySessionsRepository repository;

  Future<void> refresh() async {
    if (!mounted || state.loading) return;
    final prior = state;
    state = SecuritySessionsState(
      items: prior.items,
      loading: true,
      uncertain: prior.uncertain,
      confirmed: prior.confirmed,
    );
    try {
      final items = await repository.load();
      if (mounted) state = SecuritySessionsState(items: items);
    } on Object {
      if (mounted) {
        state = SecuritySessionsState(
          items: prior.items,
          failed: true,
          uncertain: prior.uncertain,
          confirmed: prior.confirmed,
        );
      }
    }
  }

  Future<void> revoke(SecuritySession? target) async {
    if (!mounted) return;
    final prior = state;
    if (prior.loading || prior.uncertain || prior.items == null) return;
    if (target != null &&
        (target.current ||
            !prior.items!.any((s) => s.id == target.id && !s.current))) {
      return;
    }
    state = SecuritySessionsState(items: prior.items, loading: true);
    try {
      if (target == null) {
        await repository.revokeOthers();
      } else {
        await repository.revoke(target);
      }
    } on Object {
      if (mounted) {
        state = SecuritySessionsState(
          items: prior.items,
          failed: true,
          uncertain: true,
        );
      }
      return;
    }
    if (!mounted) return;
    state = SecuritySessionsState(
      items: prior.items,
      uncertain: true,
      confirmed: true,
    );
    await refresh();
  }
}

final securitySessionsRepositoryProvider = Provider<SecuritySessionsRepository>(
  (ref) {
    ref.watch(sessionStateProvider.select((session) => session?.userId));
    return LiveSecuritySessionsRepository(ref.watch(apiClientProvider));
  },
);

final securitySessionsControllerProvider =
    StateNotifierProvider.autoDispose<
      SecuritySessionsController,
      SecuritySessionsState
    >((ref) {
      final session = ref.watch(sessionStateProvider);
      if (session == null) throw StateError('Session required');
      return SecuritySessionsController(
        ref.watch(securitySessionsRepositoryProvider),
      );
    });
