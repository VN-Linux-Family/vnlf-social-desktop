import 'channel_models.dart';

abstract interface class ChannelRepository {
  Future<List<ChatChannel>> getChannels();
  Future<ChannelMessagePage> getMessages(String channelId, {String? cursor});
  Future<void> send(
    String channelId, {
    required String clientMessageId,
    required String content,
    String? replyToId,
  });
  Future<void> edit(String messageId, String content);
  Future<void> delete(String messageId);
  Future<void> react(String messageId, String emoji, {bool remove = false});
  Future<void> markRead(String channelId, {String? lastReadMessageId});
}
