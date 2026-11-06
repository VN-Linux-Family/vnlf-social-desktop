import '../../../domain/models.dart';
import '../domain/direct_message_models.dart';

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
      conversation?.canMutateMessages ?? (viewerState == DmViewerState.active);

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
