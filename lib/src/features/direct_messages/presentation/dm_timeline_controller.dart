import '../../polls/domain/poll_models.dart';
import '../../polls/presentation/poll_state.dart';

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models.dart';
import '../domain/direct_message_models.dart';
import '../domain/direct_message_repository.dart';
import '../../../core/request_identity.dart';
import 'dm_timeline_state.dart';

class DmTimelineController extends StateNotifier<DmTimelineState> {
  DmTimelineController(
    this._repository, {
    required String conversationId,
    required this._userId,
    this._readActiveUserId,
    this._onConversationSynced,
    this._onConversationRemoved,
    this._capturePollRead,
    this._onPollRealtime,
  }) : super(DmTimelineState(conversationId: conversationId));

  final DirectMessageRepository _repository;
  final String? _userId;
  final String? Function()? _readActiveUserId;
  final void Function(DmConversation)? _onConversationSynced;
  final void Function(String)? _onConversationRemoved;
  final PollReadTicket Function()? _capturePollRead;
  final void Function(Poll, bool)? _onPollRealtime;
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
      final pollRead = _capturePollRead?.call();
      final results = await Future.wait<Object>([
        _repository.getConversation(state.conversationId, refresh: refresh),
        _repository.getMessages(state.conversationId),
      ]);
      final conversation = results[0] as DmConversation;
      final page = results[1] as DmMessagePage;
      if (!_isSessionValid(revision)) return;

      pollRead?.acceptAll(page.items.map((message) => message.poll));
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
      final pollRead = _capturePollRead?.call();
      final page = await _repository.getMessages(
        state.conversationId,
        cursor: cursor,
      );
      if (!_isSessionValid(revision)) return;
      pollRead?.acceptAll(page.items.map((message) => message.poll));
      state = state.copyWith(
        messages: _mergeMessages(<DmMessage>[...page.items, ...state.messages]),
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
      final pollRead = _capturePollRead?.call();
      final window = await _repository.getMessageContext(
        state.conversationId,
        aroundMessageId: target,
      );
      if (!_isSessionValid(revision)) return;
      pollRead?.acceptAll(window.items.map((message) => message.poll));
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
          DmUploadedAsset(
            assetId: uploaded.assetId,
            fileName: file.name,
            status: uploaded.status,
            mime: uploaded.mime,
            size: uploaded.size,
          ),
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
        messages: _mergeMessages(<DmMessage>[...state.messages, created]),
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
        messages: _mergeMessages(<DmMessage>[...state.messages, updated]),
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
      state = state.copyWith(
        messages: _mergeMessages(<DmMessage>[...state.messages, updated]),
      );
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
      state = state.copyWith(searching: false, searchResults: page.items);
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
    if (resolved.poll case final poll?) {
      _onPollRealtime?.call(poll, preservePollViewerOptionId);
    }
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
      final results = await Future.wait<Object>([
        _repository.getConversation(state.conversationId, refresh: true),
        _repository.getMessages(state.conversationId),
      ]);
      final conversation = results[0] as DmConversation;
      final page = results[1] as DmMessagePage;
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
