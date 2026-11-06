import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/request_identity.dart';
import '../../../domain/models.dart';
import '../data/live_direct_message_repository.dart';
import '../domain/direct_message_models.dart';
import '../domain/direct_message_repository.dart';

final directMessageRepositoryProvider = Provider<DirectMessageRepository>(
  (ref) => LiveDirectMessageRepository(ref.watch(apiClientProvider)),
);

/// Resets automatically whenever the authenticated user changes.
final selectedDmConversationIdProvider = StateProvider<String?>((ref) {
  ref.watch(sessionStateProvider.select((session) => session?.userId));
  return null;
});

enum DmInboxTab {
  all,
  requests,
}

final dmInboxTabProvider = StateProvider<DmInboxTab>((ref) {
  ref.watch(sessionStateProvider.select((session) => session?.userId));
  return DmInboxTab.all;
});

final dmInboxProvider =
    StateNotifierProvider<DmInboxController, DmInboxState>((ref) {
      final session = ref.watch(sessionStateProvider);
      final controller = DmInboxController(
        ref.watch(directMessageRepositoryProvider),
        userId: session?.userId,
        readActiveUserId: () => ref.read(sessionStateProvider)?.userId,
        readSelectedConversationId: () =>
            ref.read(selectedDmConversationIdProvider),
        onSelectConversation: (conversationId) {
          ref.read(selectedDmConversationIdProvider.notifier).state =
              conversationId;
        },
      );
      if (session != null && session.userId.isNotEmpty) {
        unawaited(controller.load());
      }
      return controller;
    });

final dmTimelineProvider = StateNotifierProvider.autoDispose
    .family<DmTimelineController, DmTimelineState, String>((
      ref,
      conversationId,
    ) {
      final session = ref.watch(sessionStateProvider);
      final controller = DmTimelineController(
        ref.watch(directMessageRepositoryProvider),
        conversationId: conversationId,
        userId: session?.userId,
        readActiveUserId: () => ref.read(sessionStateProvider)?.userId,
        onConversationSynced: (conversation) {
          ref.read(dmInboxProvider.notifier).upsertConversation(conversation);
        },
        onConversationRemoved: (removedId) {
          ref.read(dmInboxProvider.notifier).removeConversation(removedId);
        },
      );
      if (session != null && session.userId.isNotEmpty) {
        unawaited(controller.load());
      }
      return controller;
    });

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
    actionFailure: clearActionFailure ? null : actionFailure ?? this.actionFailure,
  );
}

class DmInboxController extends StateNotifier<DmInboxState> {
  DmInboxController(
    this._repository, {
    String? userId = 'test-user',
    String? Function()? readActiveUserId,
    String? Function()? readSelectedConversationId,
    void Function(String?)? onSelectConversation,
  }) : _userId = userId,
       _readActiveUserId = readActiveUserId,
       _readSelectedConversationId = readSelectedConversationId,
       _onSelectConversation = onSelectConversation,
       super(DmInboxState());

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
    state = state.copyWith(
      openingConversation: true,
      clearActionFailure: true,
    );
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

  void removeConversation(String conversationId) {
    if (!_isSessionValid()) return;
    final next = state.conversations
        .where((item) => item.id != conversationId)
        .toList(growable: false);
    state = state.copyWith(conversations: next);
    final selected = _readSelectedConversationId?.call();
    if (selected == conversationId) {
      _onSelectConversation?.call(next.firstOrNull?.id);
    }
  }

  void _ensureSelectedConversation(List<DmConversation> items) {
    final selected = _readSelectedConversationId?.call();
    if (selected != null && items.any((item) => item.id == selected)) {
      return;
    }
    _onSelectConversation?.call(items.firstOrNull?.id);
  }
}

final class DmTimelineState {
  DmTimelineState({
    required this.conversationId,
    this.conversation,
    List<DmMessage> messages = const <DmMessage>[],
    this.nextCursor,
    this.viewerState = DmViewerState.active,
    this.loading = false,
    this.loaded = false,
    this.loadingOlder = false,
    this.sending = false,
    this.uploadingAttachment = false,
    this.busyMessageId,
    this.mutatingConversation = false,
    this.draft = '',
    this.replyTarget,
    this.editingMessage,
    this.editDraft = '',
    List<DmUploadedAsset> pendingAttachments = const <DmUploadedAsset>[],
    this.highlightedMessageId,
    this.showingContextWindow = false,
    this.searchQuery = '',
    this.searching = false,
    List<DmSearchResult> searchResults = const <DmSearchResult>[],
    this.searchFailure,
    List<DmMediaItem> mediaItems = const <DmMediaItem>[],
    this.mediaNextCursor,
    this.loadingMedia = false,
    this.mediaLoaded = false,
    this.mediaFailure,
    this.failure,
    this.operationFailure,
    this.confirmedRefreshFailed = false,
    this.statusNotice,
  }) : messages = List.unmodifiable(messages),
       pendingAttachments = List.unmodifiable(pendingAttachments),
       searchResults = List.unmodifiable(searchResults),
       mediaItems = List.unmodifiable(mediaItems);

  final String conversationId;
  final DmConversation? conversation;
  final List<DmMessage> messages;
  final String? nextCursor;
  final DmViewerState viewerState;
  final bool loading;
  final bool loaded;
  final bool loadingOlder;
  final bool sending;
  final bool uploadingAttachment;
  final String? busyMessageId;
  final bool mutatingConversation;
  final String draft;
  final DmMessage? replyTarget;
  final DmMessage? editingMessage;
  final String editDraft;
  final List<DmUploadedAsset> pendingAttachments;
  final String? highlightedMessageId;
  final bool showingContextWindow;
  final String searchQuery;
  final bool searching;
  final List<DmSearchResult> searchResults;
  final AppFailure? searchFailure;
  final List<DmMediaItem> mediaItems;
  final String? mediaNextCursor;
  final bool loadingMedia;
  final bool mediaLoaded;
  final AppFailure? mediaFailure;
  final AppFailure? failure;
  final AppFailure? operationFailure;
  final bool confirmedRefreshFailed;
  final String? statusNotice;

  bool get canSend =>
      (conversation?.canSendMessage ?? (viewerState == DmViewerState.active)) &&
      viewerState != DmViewerState.blockedByMe;

  bool get canMutateMessages =>
      conversation?.canMutateMessages ??
      (viewerState == DmViewerState.active);

  DmTimelineState copyWith({
    DmConversation? conversation,
    List<DmMessage>? messages,
    String? nextCursor,
    bool replaceCursor = false,
    DmViewerState? viewerState,
    bool? loading,
    bool? loaded,
    bool? loadingOlder,
    bool? sending,
    bool? uploadingAttachment,
    String? busyMessageId,
    bool clearBusyMessage = false,
    bool? mutatingConversation,
    String? draft,
    DmMessage? replyTarget,
    bool clearReplyTarget = false,
    DmMessage? editingMessage,
    bool clearEditingMessage = false,
    String? editDraft,
    List<DmUploadedAsset>? pendingAttachments,
    String? highlightedMessageId,
    bool clearHighlightedMessage = false,
    bool? showingContextWindow,
    String? searchQuery,
    bool? searching,
    List<DmSearchResult>? searchResults,
    AppFailure? searchFailure,
    bool clearSearchFailure = false,
    List<DmMediaItem>? mediaItems,
    String? mediaNextCursor,
    bool replaceMediaCursor = false,
    bool? loadingMedia,
    bool? mediaLoaded,
    AppFailure? mediaFailure,
    bool clearMediaFailure = false,
    AppFailure? failure,
    bool clearFailure = false,
    AppFailure? operationFailure,
    bool clearOperationFailure = false,
    bool? confirmedRefreshFailed,
    String? statusNotice,
    bool clearStatusNotice = false,
  }) => DmTimelineState(
    conversationId: conversationId,
    conversation: conversation ?? this.conversation,
    messages: messages ?? this.messages,
    nextCursor: replaceCursor ? nextCursor : this.nextCursor,
    viewerState: viewerState ?? this.viewerState,
    loading: loading ?? this.loading,
    loaded: loaded ?? this.loaded,
    loadingOlder: loadingOlder ?? this.loadingOlder,
    sending: sending ?? this.sending,
    uploadingAttachment: uploadingAttachment ?? this.uploadingAttachment,
    busyMessageId: clearBusyMessage
        ? null
        : busyMessageId ?? this.busyMessageId,
    mutatingConversation: mutatingConversation ?? this.mutatingConversation,
    draft: draft ?? this.draft,
    replyTarget: clearReplyTarget ? null : replyTarget ?? this.replyTarget,
    editingMessage: clearEditingMessage
        ? null
        : editingMessage ?? this.editingMessage,
    editDraft: editDraft ?? this.editDraft,
    pendingAttachments: pendingAttachments ?? this.pendingAttachments,
    highlightedMessageId: clearHighlightedMessage
        ? null
        : highlightedMessageId ?? this.highlightedMessageId,
    showingContextWindow: showingContextWindow ?? this.showingContextWindow,
    searchQuery: searchQuery ?? this.searchQuery,
    searching: searching ?? this.searching,
    searchResults: searchResults ?? this.searchResults,
    searchFailure: clearSearchFailure
        ? null
        : searchFailure ?? this.searchFailure,
    mediaItems: mediaItems ?? this.mediaItems,
    mediaNextCursor: replaceMediaCursor
        ? mediaNextCursor
        : this.mediaNextCursor,
    loadingMedia: loadingMedia ?? this.loadingMedia,
    mediaLoaded: mediaLoaded ?? this.mediaLoaded,
    mediaFailure: clearMediaFailure ? null : mediaFailure ?? this.mediaFailure,
    failure: clearFailure ? null : failure ?? this.failure,
    operationFailure: clearOperationFailure
        ? null
        : operationFailure ?? this.operationFailure,
    confirmedRefreshFailed:
        confirmedRefreshFailed ?? this.confirmedRefreshFailed,
    statusNotice: clearStatusNotice ? null : statusNotice ?? this.statusNotice,
  );
}

class DmTimelineController extends StateNotifier<DmTimelineState> {
  DmTimelineController(
    this._repository, {
    required String conversationId,
    String? userId = 'test-user',
    String? Function()? readActiveUserId,
    void Function(DmConversation)? onConversationSynced,
    void Function(String)? onConversationRemoved,
  }) : _userId = userId,
       _readActiveUserId = readActiveUserId,
       _onConversationSynced = onConversationSynced,
       _onConversationRemoved = onConversationRemoved,
       super(DmTimelineState(conversationId: conversationId));

  final DirectMessageRepository _repository;
  final String? _userId;
  final String? Function()? _readActiveUserId;
  final void Function(DmConversation)? _onConversationSynced;
  final void Function(String)? _onConversationRemoved;
  int _revision = 0;
  String? _draftClientId;

  bool _isSessionValid([int? revision]) {
    final expected = _userId;
    if (!mounted || expected == null || expected.isEmpty) return false;
    final activeReader = _readActiveUserId;
    if (activeReader != null && activeReader() != expected) return false;
    return revision == null || _revision == revision;
  }

  Future<void> load({bool refresh = false}) async {
    if (!_isSessionValid() || state.loading || state.loadingOlder) return;
    final revision = ++_revision;
    state = state.copyWith(
      loading: true,
      clearFailure: true,
      confirmedRefreshFailed: false,
    );
    try {
      final conversationFuture = _repository.getConversation(
        state.conversationId,
        refresh: refresh,
      );
      final pageFuture = _repository.getMessages(state.conversationId);
      final conversation = await conversationFuture;
      final page = await pageFuture;
      if (!_isSessionValid(revision)) return;

      final mergedMessages = _mergeMessages(page.items);
      final resolvedViewerState = page.viewerState == DmViewerState.blockedByMe
          ? DmViewerState.blockedByMe
          : conversation.viewerState;
      final syncedConversation = conversation.copyWith(
        viewerState: resolvedViewerState,
      );

      state = state.copyWith(
        conversation: syncedConversation,
        messages: mergedMessages,
        nextCursor: page.nextCursor,
        replaceCursor: true,
        viewerState: resolvedViewerState,
        loading: false,
        loaded: true,
        showingContextWindow: false,
        clearHighlightedMessage: true,
        clearFailure: true,
      );
      _onConversationSynced?.call(syncedConversation);

      if (syncedConversation.unreadCount > 0 && mergedMessages.isNotEmpty) {
        unawaited(markRead(lastReadMessageId: mergedMessages.last.id));
      }
    } catch (error) {
      if (_isSessionValid(revision)) {
        state = state.copyWith(loading: false, failure: _asFailure(error));
      }
    }
  }

  Future<void> refresh() => load(refresh: true);

  Future<void> loadOlder() async {
    final cursor = state.nextCursor;
    if (!_isSessionValid() ||
        cursor == null ||
        cursor.isEmpty ||
        state.loading ||
        state.loadingOlder) {
      return;
    }
    final revision = _revision;
    state = state.copyWith(loadingOlder: true, clearFailure: true);
    try {
      final page = await _repository.getMessages(
        state.conversationId,
        cursor: cursor,
      );
      if (!_isSessionValid(revision)) return;
      state = state.copyWith(
        messages: _mergeMessages(<DmMessage>[
          ...page.items,
          ...state.messages,
        ]),
        nextCursor: page.nextCursor == cursor ? null : page.nextCursor,
        replaceCursor: true,
        loadingOlder: false,
      );
    } catch (error) {
      if (_isSessionValid(revision)) {
        state = state.copyWith(loadingOlder: false, failure: _asFailure(error));
      }
    }
  }

  Future<void> jumpToMessageContext(String messageId) async {
    final target = messageId.trim();
    if (!_isSessionValid() || target.isEmpty || state.loading) return;
    final revision = ++_revision;
    state = state.copyWith(loading: true, clearFailure: true);
    try {
      final window = await _repository.getMessageContext(
        state.conversationId,
        aroundMessageId: target,
      );
      if (!_isSessionValid(revision)) return;
      state = state.copyWith(
        messages: _mergeMessages(window.items),
        nextCursor: null,
        replaceCursor: true,
        loading: false,
        loaded: true,
        showingContextWindow: true,
        highlightedMessageId: window.targetMessageId ?? target,
      );
    } catch (error) {
      if (_isSessionValid(revision)) {
        state = state.copyWith(loading: false, failure: _asFailure(error));
      }
    }
  }

  Future<void> returnToLatestMessages() => load(refresh: true);

  Future<void> markRead({String? lastReadMessageId}) async {
    if (!_isSessionValid()) return;
    final revision = _revision;
    final targetId = lastReadMessageId ?? state.messages.lastOrNull?.id;
    try {
      final receipt = await _repository.markRead(
        state.conversationId,
        lastReadMessageId: targetId,
      );
      if (!_isSessionValid(revision)) return;
      final current = state.conversation;
      if (current != null) {
        final updated = current.copyWith(
          unreadCount: 0,
          clearFirstUnread: true,
          lastReadMessageId: receipt.lastReadMessageId ?? targetId,
          replaceLastRead: true,
        );
        state = state.copyWith(conversation: updated);
        _onConversationSynced?.call(updated);
      }
    } catch (_) {
      // Read-sync is non-blocking; timeline stays usable if it fails.
    }
  }

  void updateDraft(String value) {
    if (!_isSessionValid() || state.sending) return;
    if (value != state.draft) {
      _draftClientId = null;
    }
    state = state.copyWith(
      draft: value,
      clearOperationFailure: true,
      clearStatusNotice: true,
    );
  }

  void setReplyTarget(DmMessage? message) {
    if (!_isSessionValid() || state.sending) return;
    _draftClientId = null;
    state = state.copyWith(
      replyTarget: message,
      clearReplyTarget: message == null,
      clearOperationFailure: true,
    );
  }

  Future<void> uploadAndAttach(DmUploadFile file) async {
    if (!_isSessionValid() ||
        state.uploadingAttachment ||
        state.sending ||
        state.pendingAttachments.length >= 4) {
      return;
    }
    final revision = _revision;
    state = state.copyWith(
      uploadingAttachment: true,
      clearOperationFailure: true,
    );
    try {
      final uploaded = await _repository.uploadAttachment(file);
      if (!_isSessionValid(revision)) return;
      _draftClientId = null;
      state = state.copyWith(
        uploadingAttachment: false,
        pendingAttachments: <DmUploadedAsset>[
          ...state.pendingAttachments,
          uploaded,
        ],
      );
    } catch (error) {
      if (_isSessionValid(revision)) {
        state = state.copyWith(
          uploadingAttachment: false,
          operationFailure: _asFailure(error),
        );
      }
    }
  }

  void removePendingAttachment(String assetId) {
    if (!_isSessionValid() || state.sending) return;
    _draftClientId = null;
    state = state.copyWith(
      pendingAttachments: state.pendingAttachments
          .where((item) => item.assetId != assetId)
          .toList(growable: false),
    );
  }

  Future<void> send() async {
    if (!_isSessionValid()) return;
    final text = tidyDmMessageText(state.draft);
    final attachmentIds = state.pendingAttachments
        .map((item) => item.assetId)
        .toList(growable: false);
    if (state.sending ||
        state.uploadingAttachment ||
        state.busyMessageId != null ||
        state.mutatingConversation ||
        !state.canSend ||
        (text.isEmpty && attachmentIds.isEmpty) ||
        text.length > 4000) {
      return;
    }
    _draftClientId ??= newRequestIdentity();
    final clientId = _draftClientId!;
    state = state.copyWith(
      sending: true,
      clearOperationFailure: true,
      confirmedRefreshFailed: false,
    );
    try {
      final created = await _repository.sendMessage(
        state.conversationId,
        clientMessageId: clientId,
        content: text,
        replyToId: state.replyTarget?.id,
        attachmentIds: attachmentIds,
      );
      if (!_isSessionValid()) return;
      _draftClientId = null;
      state = state.copyWith(
        draft: '',
        clearReplyTarget: true,
        pendingAttachments: const <DmUploadedAsset>[],
        messages: created == null
            ? state.messages
            : _mergeMessages(<DmMessage>[...state.messages, created]),
      );
      await _reloadAfterConfirmation();
    } catch (error) {
      if (_isSessionValid()) {
        state = state.copyWith(operationFailure: _asFailure(error));
      }
    } finally {
      if (_isSessionValid()) {
        state = state.copyWith(sending: false);
      }
    }
  }

  void startEditing(DmMessage message) {
    if (!_isSessionValid() ||
        state.busyMessageId != null ||
        state.sending ||
        message.isDeleted) {
      return;
    }
    state = state.copyWith(
      editingMessage: message,
      editDraft: message.content,
      clearOperationFailure: true,
    );
  }

  void updateEditDraft(String value) {
    if (!_isSessionValid() || state.busyMessageId != null) return;
    state = state.copyWith(editDraft: value, clearOperationFailure: true);
  }

  void cancelEditing() {
    if (!_isSessionValid() || state.busyMessageId != null) return;
    state = state.copyWith(
      clearEditingMessage: true,
      editDraft: '',
      clearOperationFailure: true,
    );
  }

  Future<void> saveEdit() async {
    final target = state.editingMessage;
    if (target == null) return;
    await editMessage(target.id, state.editDraft);
  }

  Future<void> editMessage(String messageId, String content) async {
    final tidied = tidyDmMessageText(content);
    if (!_isSessionValid() ||
        !state.canMutateMessages ||
        tidied.isEmpty ||
        tidied.length > 4000) {
      return;
    }
    await _actOnMessage(messageId, () async {
      final updated = await _repository.editMessage(messageId, tidied);
      if (!_isSessionValid()) return;
      state = state.copyWith(
        clearEditingMessage: true,
        editDraft: '',
        messages: updated == null
            ? state.messages
            : _mergeMessages(<DmMessage>[...state.messages, updated]),
      );
    });
  }

  Future<void> deleteMessage(String messageId) async {
    if (!_isSessionValid() || !state.canMutateMessages) return;
    await _actOnMessage(messageId, () async {
      await _repository.deleteMessage(messageId);
      if (!_isSessionValid()) return;
      final now = DateTime.now().toUtc();
      state = state.copyWith(
        messages: state.messages
            .map(
              (item) => item.id == messageId
                  ? DmMessage(
                      id: item.id,
                      conversationId: item.conversationId,
                      authorId: item.authorId,
                      author: item.author,
                      content: '',
                      clientMessageId: item.clientMessageId,
                      createdAt: item.createdAt,
                      editedAt: item.editedAt,
                      deletedAt: now,
                    )
                  : item,
            )
            .toList(growable: false),
      );
    });
  }

  Future<void> toggleReaction(String messageId, String emoji) async {
    if (!_isSessionValid() || !state.canMutateMessages) return;
    final alreadyReacted = state.messages
        .where((item) => item.id == messageId)
        .expand((item) => item.reactions)
        .any((reaction) => reaction.emoji == emoji && reaction.viewerReacted);
    await _actOnMessage(messageId, () async {
      final updated = await _repository.reactToMessage(
        messageId,
        emoji,
        remove: alreadyReacted,
      );
      if (!_isSessionValid()) return;
      if (updated != null) {
        state = state.copyWith(
          messages: _mergeMessages(<DmMessage>[...state.messages, updated]),
        );
      }
    });
  }

  Future<void> acceptRequest() => _actOnConversation(() async {
    await _repository.acceptRequest(state.conversationId);
  });

  Future<void> declineRequest() => _actOnConversation(() async {
    await _repository.declineRequest(state.conversationId);
  });

  Future<void> sendNewRequest() => _actOnConversation(() async {
    final peerId = state.conversation?.peer.id;
    if (peerId == null || peerId.isEmpty) return;
    await _repository.openOrRequestConversation(peerId);
  });

  Future<bool> deleteConversation() async {
    if (!_isSessionValid() ||
        state.mutatingConversation ||
        state.sending ||
        state.busyMessageId != null) {
      return false;
    }
    state = state.copyWith(
      mutatingConversation: true,
      clearOperationFailure: true,
    );
    try {
      await _repository.deleteConversation(state.conversationId);
      if (!_isSessionValid()) return false;
      _onConversationRemoved?.call(state.conversationId);
      return true;
    } catch (error) {
      if (_isSessionValid()) {
        state = state.copyWith(operationFailure: _asFailure(error));
      }
      return false;
    } finally {
      if (_isSessionValid()) {
        state = state.copyWith(mutatingConversation: false);
      }
    }
  }

  Future<void> blockPeer() => _actOnConversation(() async {
    final peerId = state.conversation?.peer.id;
    if (peerId == null || peerId.isEmpty) return;
    await _repository.blockUser(peerId);
  });

  Future<void> unblockPeer() => _actOnConversation(() async {
    final peerId = state.conversation?.peer.id;
    if (peerId == null || peerId.isEmpty) return;
    await _repository.unblockUser(peerId);
  });

  Future<bool> reportConversation({
    required DmReportReason reason,
    String detail = '',
  }) async {
    if (!_isSessionValid() || state.mutatingConversation) return false;
    state = state.copyWith(
      mutatingConversation: true,
      clearOperationFailure: true,
      clearStatusNotice: true,
    );
    try {
      final reportId = await _repository.reportConversation(
        state.conversationId,
        reason: reason,
        detail: detail,
      );
      if (!_isSessionValid()) return false;
      state = state.copyWith(statusNotice: reportId);
      return true;
    } catch (error) {
      if (_isSessionValid()) {
        state = state.copyWith(operationFailure: _asFailure(error));
      }
      return false;
    } finally {
      if (_isSessionValid()) {
        state = state.copyWith(mutatingConversation: false);
      }
    }
  }

  Future<void> searchMessages(String query) async {
    final trimmed = query.trim();
    if (!_isSessionValid()) return;
    if (trimmed.isEmpty) {
      clearSearch();
      return;
    }
    final revision = _revision;
    state = state.copyWith(
      searchQuery: trimmed,
      searching: true,
      clearSearchFailure: true,
    );
    try {
      final page = await _repository.searchMessages(
        state.conversationId,
        query: trimmed,
      );
      if (!_isSessionValid(revision)) return;
      state = state.copyWith(
        searching: false,
        searchResults: page.items,
      );
    } catch (error) {
      if (_isSessionValid(revision)) {
        state = state.copyWith(
          searching: false,
          searchFailure: _asFailure(error),
        );
      }
    }
  }

  void clearSearch() {
    if (!_isSessionValid()) return;
    state = state.copyWith(
      searchQuery: '',
      searching: false,
      searchResults: const <DmSearchResult>[],
      clearSearchFailure: true,
    );
  }

  /// Applies an incoming realtime message or poll update while preserving
  /// the recipient's `viewerOptionId` when the event was triggered by a peer.
  void applyRealtimeMessage(
    DmMessage incoming, {
    bool preservePollViewerOptionId = true,
  }) {
    if (!_isSessionValid()) return;
    final existing = state.messages
        .where((item) => item.id == incoming.id)
        .firstOrNull;
    final resolved = preservePollViewerOptionId
        ? incoming.withPreservedPollViewerChoice(existing)
        : incoming;
    state = state.copyWith(
      messages: _mergeMessages(<DmMessage>[...state.messages, resolved]),
    );
  }

  Future<void> loadMedia({bool loadMore = false}) async {
    if (!_isSessionValid() || state.loadingMedia) return;
    final cursor = loadMore ? state.mediaNextCursor : null;
    if (loadMore && (cursor == null || cursor.isEmpty)) return;
    final revision = _revision;
    state = state.copyWith(loadingMedia: true, clearMediaFailure: true);
    try {
      final page = await _repository.getConversationMedia(
        state.conversationId,
        cursor: cursor,
      );
      if (!_isSessionValid(revision)) return;
      final merged = loadMore
          ? <DmMediaItem>[...state.mediaItems, ...page.items]
          : page.items;
      state = state.copyWith(
        loadingMedia: false,
        mediaLoaded: true,
        mediaItems: merged,
        mediaNextCursor: page.nextCursor,
        replaceMediaCursor: true,
      );
    } catch (error) {
      if (_isSessionValid(revision)) {
        state = state.copyWith(
          loadingMedia: false,
          mediaFailure: _asFailure(error),
        );
      }
    }
  }

  Future<void> _actOnMessage(
    String messageId,
    Future<void> Function() request,
  ) async {
    if (!_isSessionValid() ||
        state.busyMessageId != null ||
        state.sending ||
        state.mutatingConversation) {
      return;
    }
    state = state.copyWith(
      busyMessageId: messageId,
      clearOperationFailure: true,
      confirmedRefreshFailed: false,
    );
    try {
      await request();
      if (_isSessionValid()) {
        await _reloadAfterConfirmation();
      }
    } catch (error) {
      if (_isSessionValid()) {
        state = state.copyWith(operationFailure: _asFailure(error));
      }
    } finally {
      if (_isSessionValid()) {
        state = state.copyWith(clearBusyMessage: true);
      }
    }
  }

  Future<void> _actOnConversation(Future<void> Function() request) async {
    if (!_isSessionValid() ||
        state.mutatingConversation ||
        state.sending ||
        state.busyMessageId != null) {
      return;
    }
    state = state.copyWith(
      mutatingConversation: true,
      clearOperationFailure: true,
      confirmedRefreshFailed: false,
    );
    try {
      await request();
      if (_isSessionValid()) {
        await _reloadAfterConfirmation();
      }
    } catch (error) {
      if (_isSessionValid()) {
        state = state.copyWith(operationFailure: _asFailure(error));
      }
    } finally {
      if (_isSessionValid()) {
        state = state.copyWith(mutatingConversation: false);
      }
    }
  }

  Future<void> _reloadAfterConfirmation() async {
    // A confirmed write is never repeated if the follow-up read fails.
    final revision = ++_revision;
    try {
      final conversationFuture = _repository.getConversation(
        state.conversationId,
        refresh: true,
      );
      final pageFuture = _repository.getMessages(state.conversationId);
      final conversation = await conversationFuture;
      final page = await pageFuture;
      if (!_isSessionValid(revision)) return;

      final resolvedViewerState = page.viewerState == DmViewerState.blockedByMe
          ? DmViewerState.blockedByMe
          : conversation.viewerState;
      final syncedConversation = conversation.copyWith(
        viewerState: resolvedViewerState,
      );
      state = state.copyWith(
        conversation: syncedConversation,
        messages: _mergeMessages(<DmMessage>[...state.messages, ...page.items]),
        nextCursor: state.loaded ? state.nextCursor : page.nextCursor,
        replaceCursor: true,
        viewerState: resolvedViewerState,
        loaded: true,
        loading: false,
        loadingOlder: false,
        clearFailure: true,
      );
      _onConversationSynced?.call(syncedConversation);
    } catch (error) {
      if (_isSessionValid(revision)) {
        state = state.copyWith(
          loading: false,
          loadingOlder: false,
          confirmedRefreshFailed: true,
          failure: _asFailure(error),
        );
      }
    }
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

List<DmMessage> _mergeMessages(List<DmMessage> messages) {
  final unique = <String, DmMessage>{
    for (final message in messages) message.id: message,
  }.values.toList();
  unique.sort(
    (a, b) => (a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)).compareTo(
      b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
    ),
  );
  return unique;
}

AppFailure _asFailure(Object error) =>
    error is AppFailure ? error : const TransportFailure();
