import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../design_system/design_system.dart';
import '../../shared/presentation/author_mapper.dart';
import '../domain/direct_message_models.dart';
import 'direct_message_feedback.dart';

class DmConversationHeader extends StatelessWidget {
  const DmConversationHeader({
    super.key,
    required this.conversation,
    required this.wide,
    required this.loading,
    required this.busy,
    required this.onBack,
    required this.onSearch,
    required this.onMedia,
    required this.onRefresh,
    required this.onAction,
  });
  final DmConversation conversation;
  final bool wide, loading, busy;
  final VoidCallback onBack, onSearch, onMedia, onRefresh;
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final peer = conversation.peer;
    final scale = MediaQuery.textScalerOf(context);
    final height = math.max(
      54.0,
      scale.scale(13) * 1.15 + scale.scale(11) * 1.2 + 6,
    );
    return SizedBox(
      key: const Key('dm-conversation-header'),
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 500;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              children: [
                if (!wide)
                  IconButton(
                    key: const Key('dm-open-inbox-sheet-button'),
                    tooltip: dmText(
                      context,
                      'Danh sách cuộc trò chuyện',
                      'Conversation list',
                    ),
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back, size: 20),
                  ),
                VnlfAvatar(
                  author: presentAuthor(peer.toAuthor()),
                  size: 32,
                  semanticLabel: peer.displayName,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        peer.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.15,
                          fontWeight: FontWeight.w700,
                          color: colors.ink,
                        ),
                      ),
                      Text(
                        '${peer.username.isEmpty ? '' : '@${peer.username} · '}${peer.isOnline ? dmText(context, 'Trực tuyến', 'Online') : dmText(context, 'Ngoại tuyến', 'Offline')}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.2,
                          color: colors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  key: const Key('dm-search-button'),
                  tooltip: dmText(
                    context,
                    'Tìm trong cuộc trò chuyện',
                    'Search in conversation',
                  ),
                  onPressed: onSearch,
                  icon: const Icon(Icons.search, size: 20),
                ),
                if (!compact) ...[
                  IconButton(
                    key: const Key('dm-media-button'),
                    tooltip: dmText(context, 'Ảnh đã chia sẻ', 'Shared media'),
                    onPressed: onMedia,
                    icon: const Icon(Icons.photo_library_outlined, size: 20),
                  ),
                  IconButton(
                    key: const Key('dm-refresh-timeline-button'),
                    tooltip: dmText(
                      context,
                      'Làm mới tin nhắn',
                      'Refresh messages',
                    ),
                    onPressed: loading ? null : onRefresh,
                    icon: const Icon(Icons.refresh, size: 20),
                  ),
                ],
                PopupMenuButton<String>(
                  key: const Key('dm-conversation-menu'),
                  tooltip: dmText(
                    context,
                    'Tùy chọn cuộc trò chuyện',
                    'Conversation options',
                  ),
                  enabled: !busy,
                  onSelected: (action) {
                    if (action == 'media') {
                      onMedia();
                    } else if (action == 'refresh') {
                      onRefresh();
                    } else {
                      onAction(action);
                    }
                  },
                  itemBuilder: (context) => [
                    if (compact) ...[
                      PopupMenuItem(
                        value: 'media',
                        child: Text(
                          dmText(context, 'Ảnh đã chia sẻ', 'Shared media'),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'refresh',
                        enabled: !loading,
                        child: Text(
                          dmText(
                            context,
                            'Làm mới tin nhắn',
                            'Refresh messages',
                          ),
                        ),
                      ),
                    ],
                    PopupMenuItem(
                      value: 'mark_read',
                      child: Text(
                        dmText(context, 'Đánh dấu đã đọc', 'Mark as read'),
                      ),
                    ),
                    PopupMenuItem(
                      value: conversation.isBlockedByMe ? 'unblock' : 'block',
                      child: Text(
                        conversation.isBlockedByMe
                            ? dmText(
                                context,
                                'Bỏ chặn người dùng',
                                'Unblock user',
                              )
                            : dmText(context, 'Chặn người dùng', 'Block user'),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'report',
                      child: Text(
                        dmText(
                          context,
                          'Báo cáo cuộc trò chuyện',
                          'Report conversation',
                        ),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete_conversation',
                      child: Text(
                        dmText(
                          context,
                          'Xóa cuộc trò chuyện',
                          'Delete conversation',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
