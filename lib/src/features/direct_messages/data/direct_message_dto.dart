import '../../polls/data/poll_dto.dart';
import '../../../data/field_reader.dart';
import '../../../domain/models.dart';
import '../domain/direct_message_models.dart';

final class DmConversationDto {
  const DmConversationDto(this.json);

  final Map<String, dynamic> json;

  DmConversation toDomain() {
    final id = _requiredId(json['id'], 'conversation.id');
    final peerMap = objectValue(json['peer'], 'conversation.peer');
    if (peerMap == null) {
      throw const ParseFailure('conversation.peer');
    }
    final statusRaw = stringValue(json['status'], 'conversation.status');
    final viewerStateRaw = stringValue(
      json['viewerState'],
      'conversation.viewerState',
    );
    return DmConversation(
      id: id,
      status: DmConversationStatus.fromWire(
        statusRaw.isEmpty ? 'ACTIVE' : statusRaw,
      ),
      viewerState: DmViewerState.fromWire(
        viewerStateRaw.isEmpty ? 'ACTIVE' : viewerStateRaw,
      ),
      canSend: boolValue(json['canSend'], 'conversation.canSend'),
      unreadCount: intValue(json['unreadCount'], 'conversation.unreadCount'),
      firstUnreadMessageId: nullableString(
        json['firstUnreadMessageId'],
        'conversation.firstUnreadMessageId',
      ),
      lastReadMessageId: nullableString(
        json['lastReadMessageId'],
        'conversation.lastReadMessageId',
      ),
      peerLastReadMessageId: nullableString(
        json['peerLastReadMessageId'],
        'conversation.peerLastReadMessageId',
      ),
      lastMessageId: nullableString(
        json['lastMessageId'],
        'conversation.lastMessageId',
      ),
      lastMessage: nullableString(
        json['lastMessage'],
        'conversation.lastMessage',
      ),
      updatedAt: dateValue(json['updatedAt'], 'conversation.updatedAt'),
      peer: _parsePeer(peerMap),
    );
  }

  static List<DmConversation> parseList(Map<String, dynamic> json) =>
      List.unmodifiable(
        objectList(
          json['items'],
          'conversations.items',
        ).map((item) => DmConversationDto(item).toDomain()),
      );
}

final class DmConversationOpenResultDto {
  const DmConversationOpenResultDto(this.json);

  final Map<String, dynamic> json;

  DmConversationOpenResult toDomain() {
    final id = _requiredId(
      json['conversationId'] ?? json['id'],
      'openConversation.conversationId',
    );
    final statusRaw = stringValue(json['status'], 'openConversation.status');
    return DmConversationOpenResult(
      conversationId: id,
      status: DmConversationStatus.fromWire(
        statusRaw.isEmpty ? 'ACTIVE' : statusRaw,
      ),
    );
  }
}

final class DmMessagePageDto {
  const DmMessagePageDto(this.json);

  final Map<String, dynamic> json;

  DmMessagePage toDomain() {
    final viewerStateRaw = stringValue(
      json['viewerState'],
      'messages.viewerState',
    );
    return DmMessagePage(
      items: objectList(
        json['items'],
        'messages.items',
      ).map((item) => DmMessageDto(item).toDomain()).toList(growable: false),
      nextCursor: nullableString(json['nextCursor'], 'messages.nextCursor'),
      viewerState: DmViewerState.fromWire(
        viewerStateRaw.isEmpty ? 'ACTIVE' : viewerStateRaw,
      ),
    );
  }
}

final class DmContextWindowDto {
  const DmContextWindowDto(this.json);

  final Map<String, dynamic> json;

  DmContextWindow toDomain() => DmContextWindow(
    items: objectList(
      json['items'],
      'context.items',
    ).map((item) => DmMessageDto(item).toDomain()).toList(growable: false),
    targetMessageId: nullableString(
      json['targetMessageId'],
      'context.targetMessageId',
    ),
  );
}

final class DmMessageDto {
  const DmMessageDto(this.json);

  final Map<String, dynamic> json;

  DmMessage toDomain() {
    final id = _requiredId(json['id'], 'message.id');
    final authorMap = objectValue(json['author'], 'message.author');
    if (authorMap == null) {
      throw const ParseFailure('message.author');
    }
    final topAuthorId = stringValue(json['authorId'], 'message.authorId');
    final nestedAuthorId = stringValue(authorMap['id'], 'message.author.id');
    final authorId = topAuthorId.isNotEmpty ? topAuthorId : nestedAuthorId;
    if (authorId.isEmpty) {
      throw const ParseFailure('message.authorId');
    }
    final author = _parseAuthor(
      authorMap,
      fallbackId: authorId,
      field: 'message.author',
    );
    final replyMap = objectValue(json['replyTo'], 'message.replyTo');
    final gifMap = objectValue(json['gif'], 'message.gif');

    return DmMessage(
      id: id,
      conversationId: nullableString(
        json['conversationId'],
        'message.conversationId',
      ),
      authorId: authorId,
      author: author,
      content: stringValue(json['content'], 'message.content'),
      clientMessageId: stringValue(
        json['clientMessageId'],
        'message.clientMessageId',
      ),
      replyToMessageId: nullableString(
        json['replyToMessageId'],
        'message.replyToMessageId',
      ),
      replyTo: replyMap == null ? null : _parseReplyPreview(replyMap),
      mentions: objectList(
        json['mentions'],
        'message.mentions',
      ).map(_parseMention).toList(growable: false),
      attentionUserIds: stringList(
        json['attentionUserIds'],
        'message.attentionUserIds',
      ),
      reactions: objectList(
        json['reactions'],
        'message.reactions',
      ).map(_parseReaction).toList(growable: false),
      attachments: objectList(
        json['attachments'],
        'message.attachments',
      ).map(_parseAttachment).toList(growable: false),
      gif: gifMap == null ? null : _parseGif(gifMap),
      poll: PollDto.optional(json['poll']),
      createdAt: dateValue(json['createdAt'], 'message.createdAt'),
      editedAt: dateValue(json['editedAt'], 'message.editedAt'),
      deletedAt: dateValue(json['deletedAt'], 'message.deletedAt'),
    );
  }

  static DmMessage parseMutationResponse(Map<String, dynamic> json) =>
      DmMessageDto(json).toDomain();
}

final class DmSearchPageDto {
  const DmSearchPageDto(this.json);

  final Map<String, dynamic> json;

  DmSearchPage toDomain() => DmSearchPage(
    items: objectList(
      json['items'],
      'search.items',
    ).map(_parseSearchResult).toList(growable: false),
    nextCursor: nullableString(json['nextCursor'], 'search.nextCursor'),
  );
}

final class DmMediaPageDto {
  const DmMediaPageDto(this.json);

  final Map<String, dynamic> json;

  DmMediaPage toDomain() => DmMediaPage(
    items: objectList(
      json['items'],
      'media.items',
    ).map(_parseMediaItem).toList(growable: false),
    nextCursor: nullableString(json['nextCursor'], 'media.nextCursor'),
  );
}

final class DmReadReceiptDto {
  const DmReadReceiptDto(this.json);

  final Map<String, dynamic> json;

  DmReadReceipt toDomain() {
    if (json['ok'] != true ||
        json['changed'] is! bool ||
        !json.containsKey('lastReadMessageId')) {
      throw const ParseFailure('read.ack');
    }
    return DmReadReceipt(
      changed: json['changed'] as bool,
      lastReadMessageId: nullableString(
        json['lastReadMessageId'],
        'read.lastReadMessageId',
      ),
    );
  }
}

DmPeer _parsePeer(Map<String, dynamic> json) {
  final id = _requiredId(json['id'], 'peer.id');
  final username = stringValue(json['username'], 'peer.username');
  final displayName = stringValue(json['displayName'], 'peer.displayName');
  final presenceRaw = stringValue(json['presence'], 'peer.presence');
  return DmPeer(
    id: id,
    username: username,
    displayName: displayName.isEmpty
        ? (username.isNotEmpty ? username : id)
        : displayName,
    avatarUrl: stringValue(json['avatarUrl'], 'peer.avatarUrl'),
    style: styleValue(json['style'], 'peer.style'),
    presence: DmPeerPresence.fromWire(
      presenceRaw.isEmpty ? 'OFFLINE' : presenceRaw,
    ),
  );
}

Author _parseAuthor(
  Map<String, dynamic> json, {
  required String fallbackId,
  required String field,
}) {
  final rawId = stringValue(json['id'], '$field.id');
  final id = rawId.isNotEmpty ? rawId : fallbackId;
  if (id.isEmpty) {
    throw ParseFailure('$field.id');
  }
  final username = stringValue(json['username'], '$field.username');
  final displayName = stringValue(json['displayName'], '$field.displayName');
  final role = stringValue(json['role'], '$field.role');
  return Author(
    id: id,
    username: username,
    displayName: displayName.isEmpty
        ? (username.isNotEmpty ? username : id)
        : displayName,
    avatarUrl: stringValue(json['avatarUrl'], '$field.avatarUrl'),
    role: role.isEmpty ? 'USER' : role,
    style: styleValue(json['style'], '$field.style'),
  );
}

DmReplyPreview _parseReplyPreview(Map<String, dynamic> json) {
  final id = _requiredId(json['id'], 'replyTo.id');
  final username = stringValue(json['username'], 'replyTo.username');
  final rawName = stringValue(json['name'], 'replyTo.name');
  final displayName = stringValue(json['displayName'], 'replyTo.displayName');
  final name = rawName.isNotEmpty
      ? rawName
      : (displayName.isNotEmpty ? displayName : username);
  final previewMap = objectValue(
    json['previewAttachment'],
    'replyTo.previewAttachment',
  );
  return DmReplyPreview(
    id: id,
    authorId: stringValue(json['authorId'], 'replyTo.authorId'),
    name: name,
    username: username,
    content: stringValue(json['content'], 'replyTo.content'),
    deleted: boolValue(json['deleted'], 'replyTo.deleted'),
    hasGif: boolValue(json['hasGif'], 'replyTo.hasGif'),
    previewAttachment: previewMap == null ? null : _parseAttachment(previewMap),
  );
}

DmMention _parseMention(Map<String, dynamic> json) {
  final id = _requiredId(json['id'], 'mention.id');
  final token = _requiredId(json['token'], 'mention.token');
  final username = stringValue(json['username'], 'mention.username');
  final displayName = stringValue(json['displayName'], 'mention.displayName');
  return DmMention(
    id: id,
    token: token,
    username: username,
    displayName: displayName.isEmpty ? username : displayName,
  );
}

DmReaction _parseReaction(Map<String, dynamic> json) {
  final emoji = _requiredId(json['emoji'], 'reaction.emoji');
  final count = intValue(json['count'], 'reaction.count');
  return DmReaction(
    emoji: emoji,
    count: count,
    viewerReacted: boolValue(json['viewerReacted'], 'reaction.viewerReacted'),
  );
}

DmAttachment _parseAttachment(Map<String, dynamic> json) {
  final id = _requiredId(json['id'], 'attachment.id');
  return DmAttachment(
    id: id,
    url: stringValue(json['url'], 'attachment.url'),
    downloadPath: stringValue(json['downloadPath'], 'attachment.downloadPath'),
    mime: stringValue(json['mime'], 'attachment.mime'),
    size: intValue(json['size'], 'attachment.size'),
    width: nullableInt(json['width'], 'attachment.width'),
    height: nullableInt(json['height'], 'attachment.height'),
    posterUrl: nullableString(json['posterUrl'], 'attachment.posterUrl'),
    durationMs: nullableInt(json['durationMs'], 'attachment.durationMs'),
    state: stringValue(json['state'], 'attachment.state'),
    error: nullableString(json['error'], 'attachment.error'),
  );
}

DmGifAttachment _parseGif(Map<String, dynamic> json) {
  final provider = stringValue(json['provider'], 'gif.provider');
  return DmGifAttachment(
    provider: provider.isEmpty ? 'KLIPY' : provider,
    id: stringValue(json['id'], 'gif.id'),
    url: stringValue(json['url'], 'gif.url'),
    title: stringValue(json['title'], 'gif.title'),
    width: nullableInt(json['width'], 'gif.width'),
    height: nullableInt(json['height'], 'gif.height'),
    kind: nullableString(json['kind'], 'gif.kind'),
    packId: nullableString(json['packId'], 'gif.packId'),
    packSlug: nullableString(json['packSlug'], 'gif.packSlug'),
    hidden: boolValue(json['hidden'], 'gif.hidden'),
  );
}

DmSearchResult _parseSearchResult(Map<String, dynamic> json) {
  final messageId = _requiredId(
    json['messageId'] ?? json['id'],
    'search.messageId',
  );
  final conversationId = _requiredId(
    json['conversationId'],
    'search.conversationId',
  );
  final senderMap = objectValue(json['sender'], 'search.sender');
  if (senderMap == null) {
    throw const ParseFailure('search.sender');
  }
  final senderId = _requiredId(senderMap['id'], 'search.sender.id');
  return DmSearchResult(
    messageId: messageId,
    conversationId: conversationId,
    sender: _parseAuthor(
      senderMap,
      fallbackId: senderId,
      field: 'search.sender',
    ),
    excerpt: stringValue(json['excerpt'], 'search.excerpt'),
    sentAt: dateValue(json['sentAt'], 'search.sentAt'),
    contextCursor: stringValue(json['contextCursor'], 'search.contextCursor'),
  );
}

DmMediaItem _parseMediaItem(Map<String, dynamic> json) {
  final id = _requiredId(json['id'], 'media.id');
  final messageId = _requiredId(json['messageId'], 'media.messageId');
  final downloadPath = _requiredId(json['downloadPath'], 'media.downloadPath');
  final authorMap = objectValue(json['author'], 'media.author');
  if (authorMap == null) {
    throw const ParseFailure('media.author');
  }
  final authorId = _requiredId(authorMap['id'], 'media.author.id');
  return DmMediaItem(
    id: id,
    messageId: messageId,
    width: nullableInt(json['width'], 'media.width'),
    height: nullableInt(json['height'], 'media.height'),
    createdAt: dateValue(json['createdAt'], 'media.createdAt'),
    downloadPath: downloadPath,
    author: _parseAuthor(
      authorMap,
      fallbackId: authorId,
      field: 'media.author',
    ),
  );
}

String _requiredId(Object? value, String field) {
  final id = stringValue(value, field).trim();
  if (id.isEmpty) throw ParseFailure(field);
  return id;
}
