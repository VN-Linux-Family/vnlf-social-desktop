import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/providers.dart';
import '../data/live_blocked_people_repository.dart';
import '../domain/blocked_people.dart';

final class BlockedPeopleState {
  const BlockedPeopleState({this.items, this.loading = false, this.failed = false, this.uncertain = false, this.confirmedName});
  final List<BlockedPerson>? items;
  final bool loading;
  final bool failed;
  final bool uncertain;
  final String? confirmedName;
}

final class BlockedPeopleController extends StateNotifier<BlockedPeopleState> {
  BlockedPeopleController(this.repository) : super(const BlockedPeopleState()) { unawaited(refresh()); }
  final BlockedPeopleRepository repository;

  Future<void> refresh() async {
    if (!mounted || state.loading) return;
    final previous = state;
    state = BlockedPeopleState(items: previous.items, loading: true, uncertain: previous.uncertain, confirmedName: previous.confirmedName);
    try {
      final items = await repository.load();
      if (mounted) state = BlockedPeopleState(items: items, confirmedName: previous.confirmedName);
    } on Object {
      if (mounted) state = BlockedPeopleState(items: previous.items, failed: true, uncertain: previous.uncertain, confirmedName: previous.confirmedName);
    }
  }

  Future<void> unblock(BlockedPerson person) async {
    if (!mounted || state.loading || state.uncertain || !(state.items?.any((item) => item.id == person.id) ?? false)) return;
    final items = state.items;
    state = BlockedPeopleState(items: items, loading: true);
    String? confirmed;
    try {
      await repository.unblock(person.id);
      confirmed = person.displayName.isEmpty ? person.username : person.displayName;
    } on Object {
      // The server may have applied the write even when its reply was lost.
    }
    if (!mounted) return;
    state = BlockedPeopleState(items: items, uncertain: true, confirmedName: confirmed);
    await refresh();
  }
}

final blockedPeopleControllerProvider = StateNotifierProvider.autoDispose<BlockedPeopleController, BlockedPeopleState>((ref) {
  final owner = ref.watch(sessionStateProvider)?.userId;
  if (owner == null || owner.isEmpty) throw StateError('Session required');
  final client = ref.watch(apiClientProvider);
  final unsubscribe = client.observeSessionInvalidation(ref.invalidateSelf);
  ref.onDispose(unsubscribe);
  return BlockedPeopleController(LiveBlockedPeopleRepository(client, owner, () => ref.read(sessionStateProvider)?.userId));
});
