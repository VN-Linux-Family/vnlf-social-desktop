import '../../../domain/models.dart';

// Channel authors share the site's identity and decoration contract.
typedef ChannelAuthor = Author;

final class ChatChannel {
  const ChatChannel({
    required this.id,
    required this.slug,
    required this.name,
    this.description = '',
    this.type = '',
    this.position = 0,
    this.isArchived = false,
    this.minRoleToPost = '',
    this.slowModeSeconds = 0,
    this.unreadCount = 0,
    this.unreadAttentionCount = 0,
  });
  final String id;
  final String slug;
  final String name;
  final String description;
  final String type;
  final int position;
  final bool isArchived;
  final String minRoleToPost;
  final int slowModeSeconds;
  final int unreadCount;
  final int unreadAttentionCount;

  bool canPost(String role) {
    const ranks = ['MEMBER', 'MODERATOR', 'ADMIN', 'OWNER'];
    final required = ranks.indexOf(minRoleToPost.toUpperCase());
    final actual = ranks.indexOf(role.toUpperCase());
    return !isArchived && required >= 0 && actual >= required;
  }
}

final class ChannelMessagePage {
  ChannelMessagePage({required List<ChannelMessage> items, this.nextCursor})
    : items = List.unmodifiable(items);
  final List<ChannelMessage> items;
  final String? nextCursor;
}

final class ChannelMessage {
  ChannelMessage({
    required this.id,
    required this.author,
    required this.content,
    this.createdAt,
    this.editedAt,
    this.deletedAt,
    this.replyTo,
    this.clientMessageId = '',
    List<ChannelReaction> reactions = const [],
    List<ChannelAttachment> attachments = const [],
    this.hasGif = false,
    this.hasPoll = false,
  }) : reactions = List.unmodifiable(reactions),
       attachments = List.unmodifiable(attachments);
  final String id;
  final ChannelAuthor author;
  final String content;
  final String clientMessageId;
  final DateTime? createdAt;
  final DateTime? editedAt;
  final DateTime? deletedAt;
  final ChannelReply? replyTo;
  final List<ChannelReaction> reactions;
  final List<ChannelAttachment> attachments;
  final bool hasGif;
  final bool hasPoll;
}

final class ChannelReply {
  const ChannelReply({
    required this.id,
    required this.name,
    required this.content,
    this.deleted = false,
  });
  final String id;
  final String name;
  final String content;
  final bool deleted;
}

final class ChannelReaction {
  const ChannelReaction({
    required this.emoji,
    required this.count,
    this.viewerReacted = false,
  });
  final String emoji;
  final int count;
  final bool viewerReacted;
}

final class ChannelAttachment {
  const ChannelAttachment({
    required this.id,
    this.url = '',
    this.downloadPath = '',
    this.mime = '',
    this.state = '',
    this.width,
    this.height,
    this.posterUrl,
  });
  final String id;
  final String url;
  final String downloadPath;
  final String mime;
  final String state;
  final int? width;
  final int? height;
  final String? posterUrl;
}
