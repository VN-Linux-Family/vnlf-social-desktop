import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/domain/models.dart';
import 'package:vnlfsocialapp/src/features/realtime/data/community_chat_update.dart';
import 'package:vnlfsocialapp/src/features/realtime/domain/community_event.dart';
import 'package:vnlfsocialapp/src/features/realtime/domain/community_topic.dart';

const channel = '11111111-1111-4111-8111-111111111111';
const conversation = '22222222-2222-4222-8222-222222222222';
CommunityEvent event(String type, Map<String, Object?> data) => CommunityEvent(
  type: type,
  eventId: 'e',
  occurredAt: DateTime.utc(2026),
  data: data,
);
Map<String, Object?> message({String? channelId, String? conversationId}) => {
  'id': 'm',
  'channelId': channelId,
  'conversationId': conversationId,
  'authorId': 'peer',
  'author': {'id': 'peer', 'username': 'peer', 'displayName': 'Peer'},
  'content': 'Tiếng Việt: ặ ữ ờ ẫ ệ',
};
void main() {
  test('maps shared message DTOs with an unambiguous topic', () {
    final dm = CommunityChatUpdate.decode(
      event('dm:message-created', message(conversationId: conversation)),
    ) as CommunityDmMessage;
    expect(dm.topic, CommunityTopic.conversation(conversation));
    expect(dm.message.content, 'Tiếng Việt: ặ ữ ờ ẫ ệ');
    final ch = CommunityChatUpdate.decode(
      event('message:updated', message(channelId: channel)),
    ) as CommunityChannelMessage;
    expect(ch.topic, CommunityTopic.channel(channel));
  });
  test('rejects ambiguous and event-kind mismatched routing', () {
    for (final payload in [
      message(),
      message(channelId: channel, conversationId: conversation),
      message(channelId: channel),
    ]) {
      expect(
        () => CommunityChatUpdate.decode(event('dm:message-created', payload)),
        throwsA(isA<ParseFailure>()),
      );
    }
  });
  test('routes deletion and immutable reaction results', () {
    final deleted = CommunityChatUpdate.decode(
      event('dm:message-deleted', {
        'messageId': 'm',
        'conversationId': conversation,
        'channelId': null,
      }),
    ) as CommunityMessageDeleted;
    expect(deleted.messageId, 'm');
    final changed = CommunityChatUpdate.decode(
      event('reaction:changed', {
        'messageId': 'm',
        'channelId': channel,
        'conversationId': null,
        'reactions': [
          {'emoji': '👍', 'count': 2, 'viewerReacted': true},
        ],
      }),
    ) as CommunityReactionsChanged;
    expect(changed.reactions.single.count, 2);
    expect(() => changed.reactions.clear(), throwsUnsupportedError);
  });
  test('topicless indicators and unknown events are not guessed', () {
    expect(
      CommunityChatUpdate.decode(
        event('dm:typing-changed', {'userId': 'peer', 'isTyping': true}),
      ),
      isNull,
    );
    expect(CommunityChatUpdate.decode(event('future:type', {})), isNull);
  });
}
