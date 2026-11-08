import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models.dart';
import '../domain/direct_message_models.dart';
import '../domain/direct_message_repository.dart';

final class DmInboxState {
  DmInboxState({
    List<DmConversation> conversations = const <DmConversation>[],
    this.loading = false,
    this.loaded = false,
    this.openingConversation = false,
    this.failure,
    this.actionFailure,
  }) : conversations = List.unmodifiable(conversations);

  final List<DmConversation> conversations;
  final bool loading;
  final bool loaded;
  final bool openingConversation;
  final AppFailure? failure;
  final AppFailure? actionFailure;

  List<DmConversation> get incomingRequests => conversations
      .where((item) => item.isIncomingRequest)
      .toList(growable: false);

  int get totalUnreadCount =>
      conversations.fold<int>(0, (sum, item) => sum + item.unreadCount);

  DmInboxState copyWith({
    List<DmConversation>? conversations,
    bool? loading,
    bool? loaded,
    bool? openingConversation,
    AppFailure? failure,
    bool clearFailure = false,
    AppFailure? actionFailure,
    bool clearActionFailure = false,
  }) => DmInboxState(
    conversations: conversations ?? this.conversations,
    loading: loading ?? this.loading,
    loaded: loaded ?? this.loaded,
    openingConversation: openingConversation ?? this.openingConversation,
    failure: clearFailure ? null : failure ?? this.failure,
    actionFailure: clearActionFailure
        ? null
        : actionFailure ?? this.actionFailure,
  );
}

class DmInboxController extends StateNotifier<DmInboxState> {
  DmInboxController(
    this._repository, {
    required this._userId,
    this._readActiveUserId,
    this._readSelectedConversationId,
    this._onSelectConversation,
  }) : super(DmInboxState());

  final DirectMessageRepository _repository;
  final String? _userId;
  final String? Function()? _readActiveUserId;
  final String? Function()? _readSelectedConversationId;
  final void Function(String?)? _onSelectConversation;
  int _revision = 0;

  bool _isSessionValid([int? revision]) {
    final expected = _userId;
    if (!mounted || expected == null || expected.isEmpty) return false;
    final activeReader = _readActiveUserId;
    if (activeReader != null && activeReader() != expected) return false;
    return revision == null || _revision == revision;
  }

  Future<void> load({bool refresh = false}) async {
    if (!_isSessionValid() || state.loading) return;
    final revision = ++_revision;
    state = state.copyWith(loading: true, clearFailure: true);
    try {
      final items = await _repository.getConversations(refresh: refresh);
      if (!_isSessionValid(revision)) return;
      final sorted = _sortConversations(items);
      state = state.copyWith(
        conversations: sorted,
        loading: false,
        loaded: true,
        clearFailure: true,
      );
      _ensureSelectedConversation(sorted);
    } catch (error) {
      if (_isSessionValid(revision)) {
        state = state.copyWith(loading: false, failure: _asFailure(error));
      }
    }
  }

  Future<String?> openOrRequestConversation(String recipientUserId) async {
    final trimmed = recipientUserId.trim();
    if (!_isSessionValid() || state.openingConversation || trimmed.isEmpty) {
      return null;
    }
    state = state.copyWith(openingConversation: true, clearActionFailure: true);
    try {
      final result = await _repository.openOrRequestConversation(trimmed);
      if (!_isSessionValid()) return null;
      _onSelectConversation?.call(result.conversationId);
      final items = await _repository.getConversations(refresh: true);
      if (!_isSessionValid()) return null;
      final sorted = _sortConversations(items);
      state = state.copyWith(
        conversations: sorted,
        loaded: true,
        openingConversation: false,
        clearFailure: true,
      );
      return result.conversationId;
    } catch (error) {
      if (_isSessionValid()) {
        state = state.copyWith(
          openingConversation: false,
          actionFailure: _asFailure(error),
        );
      }
      return null;
    }
  }

  void upsertConversation(DmConversation updated) {
    if (!_isSessionValid()) return;
    final existing = state.conversations;
    final next = <DmConversation>[
      updated,
      for (final item in existing)
        if (item.id != updated.id) item,
    ];
    state = state.copyWith(conversations: _sortConversations(next));
  }

  void markConversationRead(
    String conversationId, {
    String? lastReadMessageId,
  }) {
    if (!_isSessionValid()) return;
    final existing = state.conversations;
    final next = <DmConversation>[
      for (final item in existing)
        if (item.id == conversationId)
          item.copyWith(
            unreadCount: 0,
            clearFirstUnread: true,
            lastReadMessageId: lastReadMessageId ?? item.lastReadMessageId,
            replaceLastRead: lastReadMessageId != null,
          )
        else
          item,
    ];
    state = state.copyWith(conversations: _sortConversations(next));
  }

  void removeConversation(String conversationId) {
    if (!_isSessionValid()) return;
    final next = state.conversations
        .where((item) => item.id != conversationId)
        .toList(growable: false);
    state = state.copyWith(conversations: next);
    final selected = _readSelectedConversationId?.call();
    if (selected == conversationId) {
      _onSelectConversation?.call(null);
    }
  }

  void _ensureSelectedConversation(List<DmConversation> items) {
    final selected = _readSelectedConversationId?.call();
    if (selected != null && items.any((item) => item.id == selected)) {
      return;
    }
    if (selected != null) _onSelectConversation?.call(null);
  }
}

List<DmConversation> _sortConversations(List<DmConversation> items) {
  final unique = <String, DmConversation>{
    for (final item in items) item.id: item,
  }.values.toList();
  unique.sort((a, b) {
    final aTime = a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bTime = b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return bTime.compareTo(aTime);
  });
  return unique;
}

AppFailure _asFailure(Object error) =>
    error is AppFailure ? error : const TransportFailure();
