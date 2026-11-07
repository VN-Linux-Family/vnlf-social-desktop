import '../../polls/data/poll_dto.dart';
import '../../../data/field_reader.dart';
import '../../../data/profile_dto.dart';
import '../../../domain/models.dart';
import '../domain/channel_models.dart';

final class ChatChannelDto {
  const ChatChannelDto(this.json);
  final Map<String, dynamic> json;
  ChatChannel toDomain() => ChatChannel(
    id: _identity(json['id']),
    slug: stringValue(json['slug'], 'slug'),
    name: stringValue(json['name'], 'name'),
    description: stringValue(json['description'], 'description'),
    type: stringValue(json['type'], 'type'),
    position: intValue(json['position'], 'position'),
    isArchived: boolValue(json['isArchived'], 'isArchived'),
    minRoleToPost: stringValue(json['minRoleToPost'], 'minRoleToPost'),
    slowModeSeconds: intValue(json['slowModeSeconds'], 'slowModeSeconds'),
    unreadCount: intValue(json['unreadCount'], 'unreadCount'),
    unreadAttentionCount: intValue(
      json['unreadAttentionCount'],
      'unreadAttentionCount',
    ),
  );
}

final class ChannelMessageDto {
  const ChannelMessageDto(this.json);
  final Map<String, dynamic> json;
  ChannelMessage toDomain() {
    final reply = objectValue(json['replyTo'], 'replyTo');
    return ChannelMessage(
      channelId: nullableString(json['channelId'], 'channelId'),
      id: _identity(json['id']),
      author: ProfileDto.fromJson(objectValue(json['author'], 'author') ?? {})
          .toDomain(),
      content: stringValue(json['content'], 'content'),
      clientMessageId: stringValue(json['clientMessageId'], 'clientMessageId'),
      createdAt: dateValue(json['createdAt'], 'createdAt'),
      editedAt: dateValue(json['editedAt'], 'editedAt'),
      deletedAt: dateValue(json['deletedAt'], 'deletedAt'),
      replyTo: reply == null
          ? null
          : ChannelReply(
              id: _identity(reply['id']),
              name: stringValue(reply['name'], 'replyTo.name'),
              content: stringValue(reply['content'], 'replyTo.content'),
              deleted: boolValue(reply['deleted'], 'replyTo.deleted'),
            ),
      reactions: objectList(json['reactions'], 'reactions')
          .map(
            (r) => ChannelReaction(
              emoji: stringValue(r['emoji'], 'emoji'),
              count: intValue(r['count'], 'count'),
              viewerReacted: boolValue(r['viewerReacted'], 'viewerReacted'),
            ),
          )
          .toList(),
      attachments: objectList(json['attachments'], 'attachments')
          .map(
            (a) => ChannelAttachment(
              id: _identity(a['id']),
              url: stringValue(a['url'], 'url'),
              downloadPath: stringValue(a['downloadPath'], 'downloadPath'),
              mime: stringValue(a['mime'], 'mime'),
              state: stringValue(a['state'], 'state'),
              width: nullableInt(a['width'], 'width'),
              height: nullableInt(a['height'], 'height'),
              posterUrl: nullableString(a['posterUrl'], 'posterUrl'),
            ),
          )
          .toList(),
      hasGif: objectValue(json['gif'], 'gif') != null,
      poll: PollDto.optional(json['poll']),
    );
  }
}

String _identity(Object? value) {
  final id = stringValue(value, 'id');
  if (id.isEmpty) throw const ParseFailure('id');
  return id;
}
