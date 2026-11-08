import '../../realtime/domain/latest_history_window.dart';

import 'dart:async';

import '../../realtime/domain/message_read_reconciler.dart';
import '../../polls/domain/poll_models.dart';
import '../../polls/presentation/poll_state.dart';
import '../../../core/request_identity.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../domain/models.dart';
import '../data/live_channel_repository.dart';
import '../domain/channel_models.dart';
import '../domain/channel_repository.dart';

final liveChannelRepositoryProvider = Provider<ChannelRepository>(
  (ref) => LiveChannelRepository(ref.watch(apiClientProvider)),
);
final liveChannelsProvider = FutureProvider<List<ChatChannel>>((ref) {
  final user = ref.watch(sessionStateProvider);
  if (user == null) return [];
  return ref.watch(liveChannelRepositoryProvider).getChannels();
});
final channelTimelineProvider =
    StateNotifierProvider.family<
      ChannelTimelineController,
      ChannelTimelineState,
      String
    >((ref, id) {
      ref.watch(sessionStateProvider);
      final controller = ChannelTimelineController(
        ref.watch(liveChannelRepositoryProvider),
        id,
        onRead: () => ref.invalidate(liveChannelsProvider),
        onPollRealtime: (poll) => ref
            .read(pollStoreProvider.notifier)
            .ingestRealtime(poll, preserveViewerSelection: true),
        capturePollRead: () => ref.read(pollStoreProvider.notifier).beginRead(),
      );
      controller.load();
      return controller;
    });

final class ChannelTimelineState {
  ChannelTimelineState({
    List<ChannelMessage> messages = const [],
    this.nextCursor,
    this.loading = false,
    this.loaded = false,
    this.loadingOlder = false,
    this.sending = false,
    this.busyMessageId,
    this.failure,
    this.operationFailure,
    this.draft = '',
    this.reply,
    this.confirmedRefreshFailed = false,
  }) : messages = List.unmodifiable(messages);
  final List<ChannelMessage> messages;
  final String? nextCursor;
  final bool loading;
  final bool loaded;
  final bool loadingOlder;
  final bool sending;
  final String? busyMessageId;
  final AppFailure? failure;
  final AppFailure? operationFailure;
  final String draft;
  final ChannelMessage? reply;
  final bool confirmedRefreshFailed;

  ChannelTimelineState copy({
    List<ChannelMessage>? messages,
    String? nextCursor,
    bool replaceCursor = false,
    bool? loading,
    bool? loaded,
    bool? loadingOlder,
    bool? sending,
    String? busyMessageId,
    bool clearBusy = false,
    AppFailure? failure,
    bool clearFailure = false,
    AppFailure? operationFailure,
    bool clearOperationFailure = false,
    String? draft,
    ChannelMessage? reply,
    bool clearReply = false,
    bool? confirmedRefreshFailed,
  }) => ChannelTimelineState(
    messages: messages ?? this.messages,
    nextCursor: replaceCursor ? nextCursor : this.nextCursor,
    loading: loading ?? this.loading,
    loaded: loaded ?? this.loaded,
    loadingOlder: loadingOlder ?? this.loadingOlder,
    sending: sending ?? this.sending,
    busyMessageId: clearBusy ? null : busyMessageId ?? this.busyMessageId,
    failure: clearFailure ? null : failure ?? this.failure,
    operationFailure: clearOperationFailure
        ? null
        : operationFailure ?? this.operationFailure,
    draft: draft ?? this.draft,
    reply: clearReply ? null : reply ?? this.reply,
    confirmedRefreshFailed:
        confirmedRefreshFailed ?? this.confirmedRefreshFailed,
  );
}

class ChannelTimelineController extends StateNotifier<ChannelTimelineState> {
  ChannelTimelineController(
    this._repository,
    this._channelId, {
    this._capturePollRead,
    this.onPollRealtime,
    this.onRead,
  }) : super(ChannelTimelineState());
  final PollReadTicket Function()? _capturePollRead;
  final void Function(Poll)? onPollRealtime;
  final void Function()? onRead;
  final _messageReads = MessageReadReconciler<ChannelMessage>(
    idOf: (m) => m.id,
  );
  bool _catchUpPending = false, _accessRevoked = false;
  final ChannelRepository _repository;
  final String _channelId;
  int _revision = 0;
  String? _draftId;

  Future<void> load() => refresh();
  Future<void> refresh() async {
    if (state.loading || state.loadingOlder) return;
    final revision = ++_revision;
    state = state.copy(
      loading: true,
      clearFailure: true,
      confirmedRefreshFailed: false,
    );
    final read = _messageReads.beginRead();
    try {
      final pollRead = _capturePollRead?.call();
      final page = await _repository.getMessages(_channelId);
      if (!mounted || revision != _revision) return;
      pollRead?.acceptAll(page.items.map((message) => message.poll));
      final newMessages = _merge(_messageReads.complete(read, page.items));
      state = state.copy(
        messages: newMessages,
        nextCursor: page.nextCursor,
        replaceCursor: true,
        loading: false,
        loaded: true,
      );
      unawaited(markRead(lastReadMessageId: newMessages.lastOrNull?.id));
    } catch (error) {
      if (mounted && revision == _revision) {
        state = state.copy(loading: false, failure: _failure(error));
      }
    } finally {
      _messageReads.cancel(read);
      if (mounted && _catchUpPending && !state.loading && !state.loadingOlder) {
        _catchUpPending = false;
        unawaited(catchUp());
      }
    }
  }

  Future<void> loadOlder() async {
    final cursor = state.nextCursor;
    if (cursor == null || state.loading || state.loadingOlder) return;
    final revision = _revision;
    state = state.copy(loadingOlder: true, clearFailure: true);
    final read = _messageReads.beginRead();
    try {
      final pollRead = _capturePollRead?.call();
      final page = await _repository.getMessages(_channelId, cursor: cursor);
      if (!mounted || revision != _revision) return;
      pollRead?.acceptAll(page.items.map((message) => message.poll));
      state = state.copy(
        messages: _merge(
          _messageReads.complete(read, [...page.items, ...state.messages]),
        ),
        nextCursor: page.nextCursor == cursor ? null : page.nextCursor,
        replaceCursor: true,
        loadingOlder: false,
      );
    } catch (error) {
      if (mounted && revision == _revision) {
        state = state.copy(loadingOlder: false, failure: _failure(error));
      }
    } finally {
      _messageReads.cancel(read);
      if (mounted && _catchUpPending && !state.loading && !state.loadingOlder) {
        _catchUpPending = false;
        unawaited(catchUp());
      }
    }
  }

  void applyRealtimeMessage(ChannelMessage incoming) {
    if (!mounted || _accessRevoked || incoming.channelId != _channelId) return;
    final previous = state.messages
        .where((m) => m.id == incoming.id)
        .firstOrNull;
    final poll = incoming.poll;
    final resolved = incoming.withState(
      reactions: incoming.reactions
          .map(
            (r) => ChannelReaction(
              emoji: r.emoji,
              count: r.count,
              viewerReacted:
                  previous?.reactions.any(
                    (p) => p.emoji == r.emoji && p.viewerReacted,
                  ) ??
                  false,
            ),
          )
          .toList(),
      poll: poll?.withViewerSelection(
        previous?.poll?.id == poll.id ? previous?.poll?.viewerOptionId : null,
      ),
      replacePoll: true,
    );
    _messageReads.upsert(resolved);
    if (resolved.poll case final poll?) onPollRealtime?.call(poll);
    state = state.copy(messages: _merge([...state.messages, resolved]));
    unawaited(markRead(lastReadMessageId: incoming.id));
  }

  Future<void> markRead({String? lastReadMessageId}) async {
    if (!mounted) return;
    try {
      await _repository.markRead(
        _channelId,
        lastReadMessageId: lastReadMessageId ?? state.messages.lastOrNull?.id,
      );
      onRead?.call();
    } catch (_) {
      // Non-blocking
    }
  }

  void removeRealtimeMessage(String id) {
    if (!mounted) return;
    _messageReads.remove(id);
    state = state.copy(
      messages: state.messages.where((m) => m.id != id).toList(),
    );
  }

  void applyRealtimeReactions(String id, List<ChannelReaction> reactions) {
    final previous = state.messages.where((m) => m.id == id).firstOrNull;
    if (previous != null) {
      applyRealtimeMessage(previous.withState(reactions: reactions));
    }
  }

  void reportRealtimeFailure(AppFailure failure) {
    if (!mounted) return;
    if (failure is HttpFailure &&
        (failure.statusCode == 401 || failure.statusCode == 403)) {
      revokeAccess();
    } else {
      state = state.copy(operationFailure: failure);
    }
  }

  void revokeAccess() {
    if (!mounted) return;
    _accessRevoked = true;
    _revision++;
    _messageReads.reset();
    state = state.copy(
      messages: [],
      loading: false,
      loadingOlder: false,
      clearReply: true,
      failure: const HttpFailure(403),
    );
  }

  Future<void> catchUp() {
    if (!mounted) return Future.value();
    if (state.loading || state.loadingOlder) {
      _catchUpPending = true;
      return Future.value();
    }
    return _reloadAfterConfirmation(reconcileLatest: true);
  }

  @override
  void dispose() {
    _messageReads.reset();
    super.dispose();
  }

  void updateDraft(String value) {
    if (state.sending) return;
    if (value != state.draft) _draftId = null;
    state = state.copy(draft: value, clearOperationFailure: true);
  }

  void replyTo(ChannelMessage? message) {
    if (state.sending) return;
    _draftId = null;
    state = state.copy(reply: message, clearReply: message == null);
  }

  Future<void> send() async {
    final text = state.draft.trim();
    if (state.sending ||
        state.busyMessageId != null ||
        text.isEmpty ||
        text.length > 4000) {
      return;
    }
    _draftId ??= newRequestIdentity();
    state = state.copy(
      sending: true,
      clearOperationFailure: true,
      confirmedRefreshFailed: false,
    );
    try {
      await _repository.send(
        _channelId,
        clientMessageId: _draftId!,
        content: text,
        replyToId: state.reply?.id,
      );
      if (!mounted) return;
      _draftId = null;
      state = state.copy(draft: '', clearReply: true);
      await _reloadAfterConfirmation();
    } catch (error) {
      if (mounted) state = state.copy(operationFailure: _failure(error));
    } finally {
      if (mounted) state = state.copy(sending: false);
    }
  }

  Future<void> edit(String id, String content) =>
      _act(id, () => _repository.edit(id, content));
  Future<void> delete(String id) => _act(id, () async {
    await _repository.delete(id);
    if (mounted) removeRealtimeMessage(id);
  });
  Future<void> react(String id, String emoji) => _act(
    id,
    () => _repository.react(
      id,
      emoji,
      remove: state.messages
          .where((message) => message.id == id)
          .expand((message) => message.reactions)
          .any((reaction) => reaction.emoji == emoji && reaction.viewerReacted),
    ),
  );

  Future<void> _act(String id, Future<void> Function() request) async {
    if (state.busyMessageId != null || state.sending) return;
    state = state.copy(
      busyMessageId: id,
      clearOperationFailure: true,
      confirmedRefreshFailed: false,
    );
    try {
      await request();
      if (mounted) await _reloadAfterConfirmation();
    } catch (error) {
      if (mounted) state = state.copy(operationFailure: _failure(error));
    } finally {
      if (mounted) state = state.copy(clearBusy: true);
    }
  }

  Future<void> _reloadAfterConfirmation({bool reconcileLatest = false}) async {
    // A confirmed write is never repeated if the follow-up read fails.
    final revision = ++_revision;
    final read = _messageReads.beginRead();
    try {
      final page = await _repository.getMessages(_channelId);
      if (!mounted || revision != _revision) return;
      final newMessages = _merge(
        _messageReads.complete(
          read,
          reconcileLatest
              ? latestHistoryWindow(
                  current: state.messages,
                  incoming: page.items,
                  hasOlder: page.nextCursor != null,
                  idOf: (m) => m.id,
                  createdAt: (m) => m.createdAt,
                )
              : [...state.messages, ...page.items],
        ),
      );
      state = state.copy(
        messages: newMessages,
        nextCursor: state.loaded ? state.nextCursor : page.nextCursor,
        replaceCursor: true,
        loaded: true,
        loading: false,
        loadingOlder: false,
        clearFailure: true,
      );
      unawaited(markRead(lastReadMessageId: newMessages.lastOrNull?.id));
    } catch (error) {
      if (mounted && revision == _revision) {
        state = state.copy(
          loading: false,
          loadingOlder: false,
          confirmedRefreshFailed: true,
          failure: _failure(error),
        );
      }
    } finally {
      _messageReads.cancel(read);
      if (mounted && _catchUpPending && !state.loading && !state.loadingOlder) {
        _catchUpPending = false;
        unawaited(catchUp());
      }
    }
  }
}

List<ChannelMessage> _merge(List<ChannelMessage> messages) {
  final unique = {for (final message in messages) message.id: message}.values
      .toList();
  unique.sort(
    (a, b) => (a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)).compareTo(
      b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
    ),
  );
  return unique;
}

AppFailure _failure(Object error) =>
    error is AppFailure ? error : const TransportFailure();
