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
  ChannelTimelineController(this._repository, this._channelId)
    : super(ChannelTimelineState());
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
    try {
      final page = await _repository.getMessages(_channelId);
      if (!mounted || revision != _revision) return;
      state = state.copy(
        messages: _merge(page.items),
        nextCursor: page.nextCursor,
        replaceCursor: true,
        loading: false,
        loaded: true,
      );
    } catch (error) {
      if (mounted && revision == _revision) {
        state = state.copy(loading: false, failure: _failure(error));
      }
    }
  }

  Future<void> loadOlder() async {
    final cursor = state.nextCursor;
    if (cursor == null || state.loading || state.loadingOlder) return;
    final revision = _revision;
    state = state.copy(loadingOlder: true, clearFailure: true);
    try {
      final page = await _repository.getMessages(_channelId, cursor: cursor);
      if (!mounted || revision != _revision) return;
      state = state.copy(
        messages: _merge([...page.items, ...state.messages]),
        nextCursor: page.nextCursor == cursor ? null : page.nextCursor,
        replaceCursor: true,
        loadingOlder: false,
      );
    } catch (error) {
      if (mounted && revision == _revision) {
        state = state.copy(loadingOlder: false, failure: _failure(error));
      }
    }
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
    if (mounted) {
      state = state.copy(
        messages: state.messages.where((message) => message.id != id).toList(),
      );
    }
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

  Future<void> _reloadAfterConfirmation() async {
    // A confirmed write is never repeated if the follow-up read fails.
    final revision = ++_revision;
    try {
      final page = await _repository.getMessages(_channelId);
      if (!mounted || revision != _revision) return;
      state = state.copy(
        messages: _merge([...state.messages, ...page.items]),
        nextCursor: state.loaded ? state.nextCursor : page.nextCursor,
        replaceCursor: true,
        loaded: true,
        loading: false,
        loadingOlder: false,
        clearFailure: true,
      );
    } catch (error) {
      if (mounted && revision == _revision) {
        state = state.copy(
          loading: false,
          loadingOlder: false,
          confirmedRefreshFailed: true,
          failure: _failure(error),
        );
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
