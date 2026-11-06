import '../../../data/field_reader.dart';
import '../../../domain/models.dart';
import '../../channels/data/channel_dto.dart';
import '../../channels/domain/channel_models.dart';
import '../../direct_messages/data/direct_message_dto.dart';
import '../../direct_messages/domain/direct_message_models.dart';
import '../domain/community_event.dart';
import '../domain/community_topic.dart';

/// Decodes only source-confirmed, explicitly routed chat events.
sealed class CommunityChatUpdate {
  const CommunityChatUpdate(this.topic);
  final CommunityTopic topic;
  static CommunityChatUpdate? decode(CommunityEvent event) {
    if (!_types.contains(event.type)) return null;
    try {
      final data = objectValue(event.data, 'realtime.chat');
      if (data == null) throw const ParseFailure('realtime.chat');
      final topic = _topic(data);
      if ((event.type.startsWith('dm:') &&
              topic.kind != CommunityTopicKind.conversation) ||
          (event.type.startsWith('message:') &&
              topic.kind != CommunityTopicKind.channel)) {
        throw const ParseFailure('realtime.chatTopic');
      }
      switch (event.type) {
        case 'dm:message-created':
        case 'dm:message-updated':
          return CommunityDmMessage(topic, DmMessageDto(data).toDomain());
        case 'message:created':
        case 'message:updated':
          return CommunityChannelMessage(
            topic,
            ChannelMessageDto(data).toDomain(),
          );
        case 'dm:message-deleted':
        case 'message:deleted':
          return CommunityMessageDeleted(topic, _id(data['messageId']));
        case 'reaction:changed':
          final reactions = objectList(data['reactions'], 'realtime.reactions')
              .map(
                (r) => DmReaction(
                  emoji: _id(r['emoji']),
                  count: intValue(r['count'], 'realtime.count'),
                  viewerReacted: boolValue(
                    r['viewerReacted'],
                    'realtime.viewerReacted',
                  ),
                ),
              )
              .toList();
          if (reactions.any((r) => r.count < 0)) {
            throw const ParseFailure('realtime.reactions');
          }
          return CommunityReactionsChanged(
            topic,
            _id(data['messageId']),
            reactions,
          );
        default:
          return null;
      }
    } catch (_) {
      throw const ParseFailure('realtime.chat');
    }
  }
}

final class CommunityDmMessage extends CommunityChatUpdate {
  const CommunityDmMessage(super.topic, this.message);
  final DmMessage message;
}

final class CommunityChannelMessage extends CommunityChatUpdate {
  const CommunityChannelMessage(super.topic, this.message);
  final ChannelMessage message;
}

final class CommunityMessageDeleted extends CommunityChatUpdate {
  const CommunityMessageDeleted(super.topic, this.messageId);
  final String messageId;
}

final class CommunityReactionsChanged extends CommunityChatUpdate {
  CommunityReactionsChanged(
    super.topic,
    this.messageId,
    List<DmReaction> reactions,
  ) : reactions = List.unmodifiable(reactions);
  final String messageId;
  final List<DmReaction> reactions;
}

CommunityTopic _topic(Map<String, dynamic> data) {
  final channel = data['channelId'], conversation = data['conversationId'];
  if ((channel == null) == (conversation == null)) {
    throw const ParseFailure('realtime.chatTopic');
  }
  return channel != null
      ? CommunityTopic.channel(_id(channel))
      : CommunityTopic.conversation(_id(conversation));
}

String _id(Object? value) {
  if (value is! String || value.isEmpty) {
    throw const ParseFailure('realtime.chatIdentity');
  }
  return value;
}

const _types = {
  'dm:message-created',
  'dm:message-updated',
  'message:created',
  'message:updated',
  'dm:message-deleted',
  'message:deleted',
  'reaction:changed',
};
