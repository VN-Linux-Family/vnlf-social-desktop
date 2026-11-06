import '../../../domain/models.dart';

/// Quick reaction emoji palette from `packages/contracts/src/reactions.ts`.
const List<String> defaultDmQuickReactions = <String>[
  '❤️',
  '😂',
  '😮',
  '😢',
  '😡',
  '👍',
];

/// Normalizes chat message text matching `tidyMessageText` in
/// `packages/contracts/src/message-text.ts`.
String tidyDmMessageText(String value) {
  final invisible = RegExp(
    r'[\s\u2800\u3164\u115F\u1160\uFFA0\u200B-\u200D\u2060\uFEFF]',
    unicode: true,
  );
  return value
      .split('\n')
      .map((line) => line.replaceAll(invisible, '').isNotEmpty ? line : '')
      .join('\n')
      .replaceAll(RegExp(r'\n{4,}'), '\n\n\n')
      .trim();
}

enum DmConversationStatus {
  requested('REQUESTED'),
  active('ACTIVE'),
  declined('DECLINED'),
  closed('CLOSED'),
  unknown('UNKNOWN');

  const DmConversationStatus(this.wireValue);
  final String wireValue;

  static DmConversationStatus fromWire(String value) =>
      switch (value.toUpperCase()) {
        'REQUESTED' => DmConversationStatus.requested,
        'ACTIVE' => DmConversationStatus.active,
        'DECLINED' => DmConversationStatus.declined,
        'CLOSED' => DmConversationStatus.closed,
        _ => DmConversationStatus.unknown,
      };
}

enum DmViewerState {
  active('ACTIVE'),
  blockedByMe('BLOCKED_BY_ME'),
  requestRequired('REQUEST_REQUIRED'),
  awaitingAcceptance('AWAITING_ACCEPTANCE'),
  unknown('UNKNOWN');

  const DmViewerState(this.wireValue);
  final String wireValue;

  static DmViewerState fromWire(String value) => switch (value.toUpperCase()) {
    'ACTIVE' => DmViewerState.active,
    'BLOCKED_BY_ME' => DmViewerState.blockedByMe,
    'REQUEST_REQUIRED' => DmViewerState.requestRequired,
    'AWAITING_ACCEPTANCE' => DmViewerState.awaitingAcceptance,
    _ => DmViewerState.unknown,
  };
}

enum DmPeerPresence {
  online('ONLINE'),
  offline('OFFLINE');

  const DmPeerPresence(this.wireValue);
  final String wireValue;

  static DmPeerPresence fromWire(String value) =>
      value.toUpperCase() == 'ONLINE'
      ? DmPeerPresence.online
      : DmPeerPresence.offline;
}

enum DmReportReason {
  spam('SPAM'),
  harassment('HARASSMENT'),
  scam('SCAM'),
  other('OTHER');

  const DmReportReason(this.wireValue);
  final String wireValue;
}

final class DmPeer {
  const DmPeer({
    required this.id,
    required this.username,
    required this.displayName,
    this.avatarUrl = '',
    this.style,
    this.presence = DmPeerPresence.offline,
  });

  final String id;
  final String username;
  final String displayName;
  final String avatarUrl;
  final AuthorStyle? style;
  final DmPeerPresence presence;

  bool get isOnline => presence == DmPeerPresence.online;

  Author toAuthor() => Author(
    id: id,
    username: username,
    displayName: displayName.isEmpty ? username : displayName,
    avatarUrl: avatarUrl,
    style: style,
  );
}

final class DmConversation {
  const DmConversation({
    required this.id,
    required this.peer,
    this.status = DmConversationStatus.active,
    this.viewerState = DmViewerState.active,
    this.canSend = false,
    this.unreadCount = 0,
    this.firstUnreadMessageId,
    this.lastReadMessageId,
    this.peerLastReadMessageId,
    this.lastMessageId,
    this.lastMessage,
    this.updatedAt,
  });

  final String id;
  final DmConversationStatus status;
  final DmViewerState viewerState;
  final bool canSend;
  final int unreadCount;
  final String? firstUnreadMessageId;
  final String? lastReadMessageId;
  final String? peerLastReadMessageId;
  final String? lastMessageId;
  final String? lastMessage;
  final DateTime? updatedAt;
  final DmPeer peer;

  bool get isBlockedByMe => viewerState == DmViewerState.blockedByMe;

  bool get isAwaitingAcceptance =>
      viewerState == DmViewerState.awaitingAcceptance;

  /// Recipient has a pending incoming request they can accept or decline.
  bool get isIncomingRequest =>
      viewerState == DmViewerState.requestRequired &&
      status == DmConversationStatus.requested;

  /// Conversation requires sending or re-sending a message request.
  bool get requiresNewRequest =>
      viewerState == DmViewerState.requestRequired &&
      status != DmConversationStatus.requested;

  /// Matches `dm-send.ts`: active or requester's initial request message.
  bool get canSendMessage =>
      canSend &&
      !isBlockedByMe &&
      (status == DmConversationStatus.active ||
          status == DmConversationStatus.requested);

  /// Matches `requireMessageAccess` (`message-access.ts:250`): message edit,
  /// delete, and reaction mutations require an active, unblocked conversation.
  bool get canMutateMessages =>
      !isBlockedByMe &&
      viewerState == DmViewerState.active &&
      status == DmConversationStatus.active;

  DmConversation copyWith({
    DmConversationStatus? status,
    DmViewerState? viewerState,
    bool? canSend,
    int? unreadCount,
    String? firstUnreadMessageId,
    bool clearFirstUnread = false,
    String? lastReadMessageId,
    bool replaceLastRead = false,
    String? peerLastReadMessageId,
    bool replacePeerLastRead = false,
    String? lastMessageId,
    String? lastMessage,
    DateTime? updatedAt,
    DmPeer? peer,
  }) => DmConversation(
    id: id,
    status: status ?? this.status,
    viewerState: viewerState ?? this.viewerState,
    canSend: canSend ?? this.canSend,
    unreadCount: unreadCount ?? this.unreadCount,
    firstUnreadMessageId: clearFirstUnread
        ? null
        : firstUnreadMessageId ?? this.firstUnreadMessageId,
    lastReadMessageId: replaceLastRead
        ? lastReadMessageId
        : lastReadMessageId ?? this.lastReadMessageId,
    peerLastReadMessageId: replacePeerLastRead
        ? peerLastReadMessageId
        : peerLastReadMessageId ?? this.peerLastReadMessageId,
    lastMessageId: lastMessageId ?? this.lastMessageId,
    lastMessage: lastMessage ?? this.lastMessage,
    updatedAt: updatedAt ?? this.updatedAt,
    peer: peer ?? this.peer,
  );
}

final class DmMessagePage {
  DmMessagePage({
    required List<DmMessage> items,
    this.nextCursor,
    this.viewerState = DmViewerState.active,
  }) : items = List.unmodifiable(items);

  final List<DmMessage> items;
  final String? nextCursor;
  final DmViewerState viewerState;
}

final class DmContextWindow {
  DmContextWindow({
    required List<DmMessage> items,
    required this.targetMessageId,
  }) : items = List.unmodifiable(items);

  final List<DmMessage> items;
  final String? targetMessageId;
}

final class DmMessage {
  DmMessage({
    required this.id,
    required this.authorId,
    required this.author,
    required this.content,
    this.conversationId,
    this.clientMessageId = '',
    this.replyToMessageId,
    this.replyTo,
    List<DmMention> mentions = const <DmMention>[],
    List<String> attentionUserIds = const <String>[],
    List<DmReaction> reactions = const <DmReaction>[],
    List<DmAttachment> attachments = const <DmAttachment>[],
    this.gif,
    Map<String, dynamic>? poll,
    this.createdAt,
    this.editedAt,
    this.deletedAt,
  }) : mentions = List.unmodifiable(mentions),
       attentionUserIds = List.unmodifiable(attentionUserIds),
       reactions = List.unmodifiable(reactions),
       attachments = List.unmodifiable(attachments),
       poll = poll == null ? null : Map<String, dynamic>.unmodifiable(poll);

  final String id;
  final String? conversationId;
  final String authorId;
  final Author author;
  final String content;
  final String clientMessageId;
  final String? replyToMessageId;
  final DmReplyPreview? replyTo;
  final List<DmMention> mentions;
  final List<String> attentionUserIds;
  final List<DmReaction> reactions;
  final List<DmAttachment> attachments;
  final DmGifAttachment? gif;
  final Map<String, dynamic>? poll;
  final DateTime? createdAt;
  final DateTime? editedAt;
  final DateTime? deletedAt;

  bool get hasPoll => poll != null;

  bool get isDeleted => deletedAt != null;

  /// Preserves the recipient's `viewerOptionId` when merging a realtime
  /// message or poll update broadcast by another user (`chat-timeline.ts`).
  DmMessage withPreservedPollViewerChoice(DmMessage? previous) {
    final currentPoll = poll;
    final previousPoll = previous?.poll;
    if (currentPoll == null || previousPoll == null) return this;
    if (!previousPoll.containsKey('viewerOptionId')) return this;
    final prevChoice = previousPoll['viewerOptionId'];
    if (currentPoll['viewerOptionId'] == prevChoice) return this;
    return DmMessage(
      id: id,
      conversationId: conversationId,
      authorId: authorId,
      author: author,
      content: content,
      clientMessageId: clientMessageId,
      replyToMessageId: replyToMessageId,
      replyTo: replyTo,
      mentions: mentions,
      attentionUserIds: attentionUserIds,
      reactions: reactions,
      attachments: attachments,
      gif: gif,
      poll: <String, dynamic>{...currentPoll, 'viewerOptionId': prevChoice},
      createdAt: createdAt,
      editedAt: editedAt,
      deletedAt: deletedAt,
    );
  }

  /// Server enforces a 15-minute edit window (`channels.ts:146`).
  bool canEditAt(DateTime now) {
    if (isDeleted) return false;
    final created = createdAt;
    if (created == null) return true;
    return now.difference(created) <= const Duration(minutes: 15);
  }
}

final class DmReplyPreview {
  const DmReplyPreview({
    required this.id,
    required this.name,
    required this.content,
    this.authorId = '',
    this.username = '',
    this.deleted = false,
    this.hasGif = false,
    this.previewAttachment,
  });

  final String id;
  final String authorId;
  final String name;
  final String username;
  final String content;
  final bool deleted;
  final bool hasGif;
  final DmAttachment? previewAttachment;
}

final class DmMention {
  const DmMention({
    required this.id,
    required this.token,
    required this.username,
    required this.displayName,
  });

  final String id;
  final String token;
  final String username;
  final String displayName;
}

final class DmReaction {
  const DmReaction({
    required this.emoji,
    required this.count,
    this.viewerReacted = false,
  });

  final String emoji;
  final int count;
  final bool viewerReacted;
}

final class DmAttachment {
  const DmAttachment({
    required this.id,
    this.url = '',
    this.downloadPath = '',
    this.mime = '',
    this.size = 0,
    this.width,
    this.height,
    this.posterUrl,
    this.durationMs,
    this.state = '',
    this.error,
  });

  final String id;
  final String url;
  final String downloadPath;
  final String mime;
  final int size;
  final int? width;
  final int? height;
  final String? posterUrl;
  final int? durationMs;
  final String state;
  final String? error;
}

final class DmGifAttachment {
  const DmGifAttachment({
    required this.provider,
    required this.id,
    required this.url,
    this.title = '',
    this.width,
    this.height,
    this.kind,
    this.packId,
    this.packSlug,
    this.hidden = false,
  });

  final String provider;
  final String id;
  final String url;
  final String title;
  final int? width;
  final int? height;
  final String? kind;
  final String? packId;
  final String? packSlug;
  final bool hidden;

  bool get isSticker =>
      provider == 'VNLF' || (provider == 'KLIPY' && kind == 'sticker');
}

final class DmSearchResult {
  const DmSearchResult({
    required this.messageId,
    required this.conversationId,
    required this.sender,
    required this.excerpt,
    this.sentAt,
    this.contextCursor = '',
  });

  final String messageId;
  final String conversationId;
  final Author sender;
  final String excerpt;
  final DateTime? sentAt;
  final String contextCursor;
}

final class DmSearchPage {
  DmSearchPage({required List<DmSearchResult> items, this.nextCursor})
    : items = List.unmodifiable(items);

  final List<DmSearchResult> items;
  final String? nextCursor;
}

final class DmMediaItem {
  const DmMediaItem({
    required this.id,
    required this.messageId,
    required this.downloadPath,
    required this.author,
    this.width,
    this.height,
    this.createdAt,
  });

  final String id;
  final String messageId;
  final int? width;
  final int? height;
  final DateTime? createdAt;
  final String downloadPath;
  final Author author;
}

final class DmMediaPage {
  DmMediaPage({required List<DmMediaItem> items, this.nextCursor})
    : items = List.unmodifiable(items);

  final List<DmMediaItem> items;
  final String? nextCursor;
}

final class DmReadReceipt {
  const DmReadReceipt({required this.changed, this.lastReadMessageId});

  final bool changed;
  final String? lastReadMessageId;
}

final class DmConversationOpenResult {
  const DmConversationOpenResult({
    required this.conversationId,
    required this.status,
  });

  final String conversationId;
  final DmConversationStatus status;
}

final class DmUploadFile {
  const DmUploadFile({
    required this.name,
    required this.mime,
    required this.length,
    required this.openRead,
  });

  final String name;
  final String mime;
  final int length;
  final Stream<List<int>> Function() openRead;
}

final class DmUploadedAsset {
  const DmUploadedAsset({
    required this.assetId,
    this.fileName = '',
    required this.status,
    required this.mime,
    required this.size,
  });

  final String assetId;
  final String fileName;
  final String status;
  final String mime;
  final int size;
}
