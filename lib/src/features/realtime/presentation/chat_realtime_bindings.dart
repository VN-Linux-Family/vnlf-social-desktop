import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../domain/models.dart' show ParseFailure;
import '../../channels/domain/channel_models.dart';
import '../../channels/presentation/live_channel_state.dart';
import '../../direct_messages/domain/direct_message_models.dart';
import '../../direct_messages/presentation/direct_message_state.dart';
import '../data/community_chat_update.dart';
import '../domain/community_topic.dart';
import 'community_realtime_binding.dart';
import 'community_realtime_providers.dart';

class DmRealtimeBinding extends ConsumerWidget {
  const DmRealtimeBinding({
    required this.conversationId,
    required this.child,
    super.key,
  });
  final String conversationId;
  final Widget child;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(communitySocketProvider) == null) return child;
    final CommunityTopic topic;
    try {
      topic = CommunityTopic.conversation(conversationId);
    } on ParseFailure {
      return child;
    }
    final controller = ref.watch(dmTimelineProvider(conversationId).notifier);
    final peerId = ref.watch(
      dmTimelineProvider(conversationId).select((s) => s.conversation?.peer.id),
    );
    return CommunityTimelineBinding(
      topic: topic,
      onCatchUp: controller.catchUp,
      onFailure: controller.reportRealtimeFailure,
      onUpdate: (update) {
        switch (update) {
          case CommunityDmMessage(:final message):
            controller.applyRealtimeMessage(message);
          case CommunityMessageDeleted(:final messageId):
            controller.removeRealtimeMessage(messageId);
          case CommunityReactionsChanged(:final messageId, :final reactions):
            controller.applyRealtimeReactions(messageId, reactions);
          default:
            break;
        }
      },
      onEvent: (event) {
        final data = event.data;
        if (event.type == 'session:revoked' ||
            event.type == 'moderation:session-revoked') {
          controller.revokeAccess();
        } else if (data is Map) {
          if (event.type == 'conversation:access-revoked' &&
              peerId != null &&
              (data['userId'] == peerId || data['peerId'] == peerId)) {
            controller.revokeAccess();
          } else if (event.type == 'dm:peer-read' &&
              data['conversationId'] == conversationId &&
              data['lastReadMessageId'] is String) {
            controller.applyPeerRead(data['lastReadMessageId'] as String);
          } else if (event.type == 'presence:changed' &&
              data['userId'] == peerId &&
              (data['status'] == 'ONLINE' || data['status'] == 'OFFLINE')) {
            controller.applyPeerPresence(
              DmPeerPresence.fromWire(data['status'] as String),
            );
          }
        }
      },
      child: child,
    );
  }
}

class ChannelRealtimeBinding extends ConsumerWidget {
  const ChannelRealtimeBinding({
    required this.channelId,
    required this.child,
    super.key,
  });
  final String channelId;
  final Widget child;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(communitySocketProvider) == null) return child;
    final CommunityTopic topic;
    try {
      topic = CommunityTopic.channel(channelId);
    } on ParseFailure {
      return child;
    }
    final controller = ref.watch(channelTimelineProvider(channelId).notifier);
    return CommunityTimelineBinding(
      topic: topic,
      onCatchUp: controller.catchUp,
      onFailure: controller.reportRealtimeFailure,
      onUpdate: (update) {
        switch (update) {
          case CommunityChannelMessage(:final message):
            controller.applyRealtimeMessage(message);
          case CommunityMessageDeleted(:final messageId):
            controller.removeRealtimeMessage(messageId);
          case CommunityReactionsChanged(:final messageId, :final reactions):
            controller.applyRealtimeReactions(
              messageId,
              reactions
                  .map(
                    (r) => ChannelReaction(
                      emoji: r.emoji,
                      count: r.count,
                      viewerReacted: r.viewerReacted,
                    ),
                  )
                  .toList(),
            );
          default:
            break;
        }
      },
      onEvent: (event) {
        if (event.type == 'channel:permission-changed') {
          controller.revokeAccess();
          ref.read(apiClientProvider).clearCache();
          ref.invalidate(liveChannelsProvider);
          ref.invalidate(channelTimelineProvider(channelId));
        } else if (event.type == 'session:revoked' ||
            event.type == 'moderation:session-revoked') {
          controller.revokeAccess();
        }
      },
      child: child,
    );
  }
}
