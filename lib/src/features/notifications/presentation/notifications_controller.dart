import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../domain/models.dart';
import '../data/live_notifications_repository.dart';
import '../domain/notifications_repository.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>(
  (ref) => LiveNotificationsRepository(ref.watch(apiClientProvider)),
);

final unreadNotificationsCountProvider = FutureProvider<int>((ref) async {
  final session = ref.watch(sessionStateProvider);
  if (session == null || session.userId.isEmpty) return 0;
  final repo = ref.watch(notificationsRepositoryProvider);
  try {
    final page = await repo.load(unreadOnly: true);
    return page.unreadCount;
  } catch (_) {
    return 0;
  }
});

final notificationsControllerProvider =
    StateNotifierProvider.autoDispose<
      NotificationsController,
      NotificationsState
    >((ref) {
      final account = ref.watch(sessionStateProvider);
      final controller = NotificationsController(
        ref.watch(notificationsRepositoryProvider),
      );
      if (account != null) controller.refresh();
      return controller;
    });

final class NotificationsState {
  NotificationsState({
    List<CommunityNotice> items = const [],
    this.loading = false,
    this.busy = false,
    this.unreadOnly = false,
    this.kind = NotificationKind.all,
    this.nextCursor,
    this.unreadCount = 0,
    this.failure,
  }) : items = List.unmodifiable(items);
  final List<CommunityNotice> items;
  final bool loading, busy, unreadOnly;
  final NotificationKind kind;
  final String? nextCursor;
  final int unreadCount;
  final AppFailure? failure;
  NotificationsState copy({
    List<CommunityNotice>? items,
    bool? loading,
    bool? busy,
    int? unreadCount,
    AppFailure? failure,
    bool clearFailure = false,
  }) => NotificationsState(
    items: items ?? this.items,
    loading: loading ?? this.loading,
    busy: busy ?? this.busy,
    unreadOnly: unreadOnly,
    kind: kind,
    nextCursor: nextCursor,
    unreadCount: unreadCount ?? this.unreadCount,
    failure: clearFailure ? null : failure ?? this.failure,
  );
}

class NotificationsController extends StateNotifier<NotificationsState> {
  NotificationsController(this._repository) : super(NotificationsState());
  final NotificationsRepository _repository;
  bool _seen = false;
  Future<void> refresh({bool? unreadOnly, NotificationKind? kind}) =>
      _load(reset: true, unreadOnly: unreadOnly, kind: kind);
  Future<void> loadMore() =>
      state.nextCursor == null ? Future.value() : _load(reset: false);
  Future<void> _load({
    required bool reset,
    bool? unreadOnly,
    NotificationKind? kind,
  }) async {
    if (state.loading || state.busy) return;
    final filter = unreadOnly ?? state.unreadOnly;
    final selectedKind = kind ?? state.kind;
    state = state.copy(loading: true, clearFailure: true);
    try {
      final page = await _repository.load(
        cursor: reset ? null : state.nextCursor,
        unreadOnly: filter,
        kind: selectedKind,
      );
      if (!mounted) return;
      state = NotificationsState(
        items: {
          for (final item in [
            ...(reset ? <CommunityNotice>[] : state.items),
            ...page.items,
          ])
            item.id: item,
        }.values.toList(),
        nextCursor: page.nextCursor == state.nextCursor && !reset
            ? null
            : page.nextCursor,
        unreadCount: page.unreadCount,
        unreadOnly: filter,
        kind: selectedKind,
      );
      if (!_seen) {
        await _repository.seen();
        _seen = true;
      }
    } catch (error) {
      if (mounted) state = state.copy(loading: false, failure: _failure(error));
    }
  }

  Future<void> markRead(String id) => _read([id]);
  Future<void> markAllRead() => _read(null);
  Future<void> _read(List<String>? ids) async {
    if (state.busy || state.loading) return;
    state = state.copy(busy: true, clearFailure: true);
    try {
      await _repository.read(ids: ids);
      if (!mounted) return;
      final changed = state.items
          .where(
            (item) => item.unread && (ids == null || ids.contains(item.id)),
          )
          .length;
      final items = state.items
          .map(
            (item) => ids == null || ids.contains(item.id) ? item.read() : item,
          )
          .where((item) => !state.unreadOnly || item.unread)
          .toList();
      state = state.copy(
        items: items,
        busy: false,
        unreadCount: ids == null
            ? 0
            : (state.unreadCount - changed).clamp(0, state.unreadCount),
      );
    } catch (error) {
      if (mounted) state = state.copy(busy: false, failure: _failure(error));
    }
  }
}

AppFailure _failure(Object error) =>
    error is AppFailure ? error : const TransportFailure();
