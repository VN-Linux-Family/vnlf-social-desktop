import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../../direct_messages/presentation/direct_message_state.dart';
import '../../../feed/presentation/feed_notifier.dart';
import '../../../profile/presentation/profile_data.dart';
import '../data/live_blocked_people_repository.dart';
import '../domain/blocked_people.dart';

final class BlockedPeopleState {
  const BlockedPeopleState({
    this.items,
    this.loading = false,
    this.failed = false,
    this.uncertain = false,
    this.confirmedName,
  });
  final List<BlockedPerson>? items;
  final bool loading;
  final bool failed;
  final bool uncertain;
  final String? confirmedName;
}

final class BlockedPeopleController extends StateNotifier<BlockedPeopleState> {
  BlockedPeopleController(this.repository, {this.onPossibleChange})
    : super(const BlockedPeopleState()) {
    unawaited(refresh());
  }
  final BlockedPeopleRepository repository;
  final void Function(BlockedPerson)? onPossibleChange;

  Future<void> refresh() async {
    if (!mounted || state.loading) return;
    final previous = state;
    state = BlockedPeopleState(
      items: previous.items,
      loading: true,
      uncertain: previous.uncertain,
      confirmedName: previous.confirmedName,
    );
    try {
      final items = await repository.load();
      if (mounted) {
        state = BlockedPeopleState(
          items: items,
          confirmedName: previous.confirmedName,
        );
      }
    } on Object {
      if (mounted) {
        state = BlockedPeopleState(
          items: previous.items,
          failed: true,
          uncertain: previous.uncertain,
          confirmedName: previous.confirmedName,
        );
      }
    }
  }

  Future<void> unblock(BlockedPerson person) async {
    if (!mounted ||
        state.loading ||
        state.uncertain ||
        !(state.items?.any((item) => item.id == person.id) ?? false)) {
      return;
    }
    final items = state.items;
    state = BlockedPeopleState(items: items, loading: true);
    String? confirmed;
    try {
      await repository.unblock(person.id);
      confirmed = person.displayName.isEmpty
          ? person.username
          : person.displayName;
    } on Object {
      // The server may have applied the write even when its reply was lost.
    }
    if (!mounted) return;
    onPossibleChange?.call(person);
    state = BlockedPeopleState(
      items: items,
      uncertain: true,
      confirmedName: confirmed,
    );
    await refresh();
  }
}

final blockedPeopleControllerProvider =
    StateNotifierProvider.autoDispose<
      BlockedPeopleController,
      BlockedPeopleState
    >((ref) {
      final owner = ref.watch(sessionStateProvider)?.userId;
      if (owner == null || owner.isEmpty) throw StateError('Session required');
      final client = ref.watch(apiClientProvider);
      final unsubscribe = client.observeSessionInvalidation(ref.invalidateSelf);
      ref.onDispose(unsubscribe);
      return BlockedPeopleController(
        LiveBlockedPeopleRepository(
          client,
          owner,
          () => ref.read(sessionStateProvider)?.userId,
        ),
        onPossibleChange: (person) {
          client.clearCache();
          ref.invalidate(profileProvider(person.username));
          ref.invalidate(feedProvider);
          ref.invalidate(feedNotifierProvider);
          if (ref.exists(dmInboxProvider)) {
            unawaited(ref.read(dmInboxProvider.notifier).load(refresh: true));
          }
        },
      );
    });
