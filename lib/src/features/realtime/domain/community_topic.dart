import '../../../domain/models.dart';

enum CommunityTopicKind { channel, conversation }

final class CommunityTopic {
  CommunityTopic._(this.kind, String value) : id = value.toLowerCase() {
    if (!_uuid.hasMatch(value)) throw const ParseFailure('realtime.topic');
  }
  factory CommunityTopic.channel(String id) =>
      CommunityTopic._(CommunityTopicKind.channel, id);
  factory CommunityTopic.conversation(String id) =>
      CommunityTopic._(CommunityTopicKind.conversation, id);
  final CommunityTopicKind kind;
  final String id;
  String get joinType =>
      kind == CommunityTopicKind.channel ? 'channel:join' : 'conversation:join';
  String get leaveType => kind == CommunityTopicKind.channel
      ? 'channel:leave'
      : 'conversation:leave';
  Map<String, Object?> get data => Map.unmodifiable({
    kind == CommunityTopicKind.channel ? 'channelId' : 'conversationId': id,
  });
  @override
  bool operator ==(Object other) =>
      other is CommunityTopic && kind == other.kind && id == other.id;
  @override
  int get hashCode => Object.hash(kind, id);
}

final _uuid = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);
