import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../design_system/design_system.dart';
import '../../shared/presentation/author_mapper.dart';
import '../domain/direct_message_models.dart';
import 'direct_message_composer.dart';
import 'direct_message_feedback.dart';
import 'direct_message_inbox.dart';
import 'direct_message_panels.dart';
import 'direct_message_state.dart';
import 'direct_message_tile.dart';

class DirectMessagesScreen extends ConsumerWidget {
  const DirectMessagesScreen({super.key, this.pollBuilder});

  final DmPollWidgetBuilder? pollBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionStateProvider);
    if (session == null) {
      return Center(
        child: SingleChildScrollView(
          child: VnlfStateCard(
            icon: Icons.mail_outline_rounded,
            title: dmText(
              context,
              'Đăng nhập để xem tin nhắn trực tiếp',
              'Sign in to view direct messages',
            ),
            message: dmText(
              context,
              'Tin nhắn riêng tư và yêu cầu kết nối chỉ dành cho thành viên đã đăng nhập.',
              'Private conversations and message requests are available to signed-in members.',
            ),
            actionLabel: dmText(context, 'Đăng nhập', 'Sign in'),
            onAction: () => context.push('/login'),
          ),
        ),
      );
    }

    final inbox = ref.watch(dmInboxProvider);
    final selectedId = ref.watch(selectedDmConversationIdProvider);

    return Column(
      children: <Widget>[
        VnlfCenterPageHeader(
          title: dmText(context, 'Tin nhắn trực tiếp', 'Direct messages'),
        ),
        Expanded(
          child: inbox.loading && !inbox.loaded
              ? const Center(child: CircularProgressIndicator())
              : inbox.failure != null && inbox.conversations.isEmpty
              ? Center(
                  child: SingleChildScrollView(
                    child: VnlfStateCard(
                      icon: Icons.cloud_off_outlined,
                      title: dmText(
                        context,
                        'Không tải được hộp thư',
                        'Could not load inbox',
                      ),
                      message: dmFailureMessage(context, inbox.failure),
                      isError: true,
                      actionLabel: dmText(context, 'Thử lại', 'Try again'),
                      onAction: () {
                        ref.read(apiClientProvider).clearCache();
                        ref.read(dmInboxProvider.notifier).load(refresh: true);
                      },
                    ),
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 720;
                    final activeConversation =
                        inbox.conversations
                            .where((item) => item.id == selectedId)
                            .firstOrNull ??
                        inbox.conversations.firstOrNull;

                    return Row(
                      children: <Widget>[
                        if (wide) ...<Widget>[
                          const SizedBox(
                            width: 280,
                            child: DirectMessageInbox(),
                          ),
                          const VerticalDivider(width: 1),
                        ],
                        Expanded(
                          child: activeConversation == null
                              ? _EmptyConversationPlaceholder(
                                  wide: wide,
                                  onOpenInboxSheet: () =>
                                      _openInboxBottomSheet(context),
                                  onNewConversation: () =>
                                      showNewDmDialog(context, ref),
                                )
                              : _DmConversationPane(
                                  key: ValueKey(
                                    '${session.userId}-${activeConversation.id}',
                                  ),
                                  conversation: activeConversation,
                                  viewerUserId: session.userId,
                                  wide: wide,
                                  onOpenInboxSheet: () =>
                                      _openInboxBottomSheet(context),
                                  pollBuilder: pollBuilder,
                                ),
                        ),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _openInboxBottomSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: DirectMessageInbox(
          onSelected: () => Navigator.pop(sheetContext),
        ),
      ),
    );
  }
}

class _EmptyConversationPlaceholder extends StatelessWidget {
  const _EmptyConversationPlaceholder({
    required this.wide,
    required this.onOpenInboxSheet,
    required this.onNewConversation,
  });

  final bool wide;
  final VoidCallback onOpenInboxSheet;
  final VoidCallback onNewConversation;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            VnlfStateCard(
              icon: Icons.chat_bubble_outline_rounded,
              title: dmText(
                context,
                'Chưa có cuộc trò chuyện nào được chọn',
                'No conversation selected',
              ),
              message: dmText(
                context,
                'Chọn một cuộc trò chuyện từ hộp thư đến hoặc bắt đầu cuộc trò chuyện mới.',
                'Choose a conversation from your inbox or start a new one.',
              ),
              actionLabel: dmText(
                context,
                'Trò chuyện mới',
                'New conversation',
              ),
              onAction: onNewConversation,
            ),
            if (!wide) ...<Widget>[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onOpenInboxSheet,
                icon: const Icon(Icons.inbox_outlined),
                label: Text(dmText(context, 'Mở hộp thư đến', 'Open inbox')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DmConversationPane extends ConsumerWidget {
  const _DmConversationPane({
    super.key,
    required this.conversation,
    required this.viewerUserId,
    required this.wide,
    required this.onOpenInboxSheet,
    this.pollBuilder,
  });

  final DmConversation conversation;
  final String viewerUserId;
  final bool wide;
  final VoidCallback onOpenInboxSheet;
  final DmPollWidgetBuilder? pollBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dmTimelineProvider(conversation.id));
    final controller = ref.read(dmTimelineProvider(conversation.id).notifier);
    final colors = VnlfColors.of(context);
    final activeConversation = state.conversation ?? conversation;
    final peer = activeConversation.peer;
    final peerAuthor = presentAuthor(peer.toAuthor());

    return Column(
      children: <Widget>[
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (!wide)
                IconButton(
                  key: const Key('dm-open-inbox-sheet-button'),
                  tooltip: dmText(
                    context,
                    'Danh sách cuộc trò chuyện',
                    'Conversation list',
                  ),
                  onPressed: onOpenInboxSheet,
                  icon: const Icon(Icons.menu_open_rounded),
                ),
              VnlfAvatar(
                author: peerAuthor,
                size: 36,
                semanticLabel: peer.displayName,
              ),
            ],
          ),
          title: Row(
            children: <Widget>[
              Flexible(
                child: Text(
                  peer.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: peer.isOnline ? const Color(0xFF22C55E) : colors.muted,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          subtitle: Text(
            peer.username.isNotEmpty
                ? '@${peer.username} · ${peer.isOnline ? dmText(context, 'Trực tuyến', 'Online') : dmText(context, 'Ngoại tuyến', 'Offline')}'
                : (peer.isOnline
                      ? dmText(context, 'Trực tuyến', 'Online')
                      : dmText(context, 'Ngoại tuyến', 'Offline')),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              IconButton(
                key: const Key('dm-search-button'),
                tooltip: dmText(
                  context,
                  'Tìm trong cuộc trò chuyện',
                  'Search in conversation',
                ),
                onPressed: () =>
                    showDmSearchSheet(context, conversationId: conversation.id),
                icon: const Icon(Icons.search, size: 20),
              ),
              IconButton(
                key: const Key('dm-media-button'),
                tooltip: dmText(context, 'Ảnh đã chia sẻ', 'Shared media'),
                onPressed: () =>
                    showDmMediaSheet(context, conversationId: conversation.id),
                icon: const Icon(Icons.photo_library_outlined, size: 20),
              ),
              IconButton(
                key: const Key('dm-refresh-timeline-button'),
                tooltip: dmText(
                  context,
                  'Làm mới tin nhắn',
                  'Refresh messages',
                ),
                onPressed: state.loading
                    ? null
                    : () {
                        ref.read(apiClientProvider).clearCache();
                        controller.refresh();
                      },
                icon: const Icon(Icons.refresh, size: 20),
              ),
              PopupMenuButton<String>(
                key: const Key('dm-conversation-menu'),
                tooltip: dmText(
                  context,
                  'Tùy chọn cuộc trò chuyện',
                  'Conversation options',
                ),
                enabled: !state.mutatingConversation,
                onSelected: (action) => _handleConversationMenu(
                  context,
                  ref,
                  action: action,
                  conversation: activeConversation,
                ),
                itemBuilder: (menuContext) => <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'mark_read',
                    child: Text(
                      dmText(menuContext, 'Đánh dấu đã đọc', 'Mark as read'),
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: activeConversation.isBlockedByMe
                        ? 'unblock'
                        : 'block',
                    child: Text(
                      activeConversation.isBlockedByMe
                          ? dmText(
                              menuContext,
                              'Bỏ chặn người dùng',
                              'Unblock user',
                            )
                          : dmText(
                              menuContext,
                              'Chặn người dùng',
                              'Block user',
                            ),
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'report',
                    child: Text(
                      dmText(
                        menuContext,
                        'Báo cáo cuộc trò chuyện',
                        'Report conversation',
                      ),
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'delete_conversation',
                    child: Text(
                      dmText(
                        menuContext,
                        'Xóa cuộc trò chuyện',
                        'Delete conversation',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        if (state.loading && state.loaded) const LinearProgressIndicator(),
        if (state.showingContextWindow)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: colors.brandSoft,
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    dmText(
                      context,
                      'Đang xem ngữ cảnh quanh tin nhắn đã chọn.',
                      'Viewing context around selected message.',
                    ),
                    style: VnlfTypography.caption(colors.ink),
                  ),
                ),
                TextButton(
                  onPressed: controller.returnToLatestMessages,
                  child: Text(
                    dmText(context, 'Về tin nhắn mới nhất', 'Return to latest'),
                  ),
                ),
              ],
            ),
          ),
        if (state.failure != null)
          Padding(
            key: const Key('dm-timeline-error'),
            padding: const EdgeInsets.all(8),
            child: Text(
              state.confirmedRefreshFailed
                  ? dmText(
                      context,
                      'Máy chủ đã xác nhận thao tác, nhưng chưa tải lại được lịch sử. Hãy làm mới; không cần gửi lại.',
                      'The server confirmed the action, but history could not be reloaded. Refresh; do not send again.',
                    )
                  : dmFailureMessage(context, state.failure),
              style: TextStyle(color: colors.red),
            ),
          ),
        if (state.operationFailure != null)
          Padding(
            key: const Key('dm-operation-error'),
            padding: const EdgeInsets.all(8),
            child: Text(
              dmFailureMessage(context, state.operationFailure, mutation: true),
              style: TextStyle(color: colors.red),
            ),
          ),
        if (state.statusNotice != null)
          Padding(
            key: const Key('dm-status-notice'),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(
              dmText(
                context,
                'Đã gửi báo cáo cuộc trò chuyện (#${state.statusNotice}).',
                'Conversation report submitted (#${state.statusNotice}).',
              ),
              style: VnlfTypography.caption(colors.brand),
            ),
          ),
        Expanded(
          child: state.loading && !state.loaded
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () {
                    ref.read(apiClientProvider).clearCache();
                    return controller.refresh();
                  },
                  child: ListView.separated(
                    reverse: true,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(8),
                    itemCount: state.messages.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      if (index == state.messages.length) {
                        if (state.loadingOlder) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (state.nextCursor != null) {
                          return Center(
                            child: TextButton(
                              key: const Key('dm-load-older-button'),
                              onPressed: controller.loadOlder,
                              child: Text(
                                dmText(
                                  context,
                                  'Tải tin nhắn cũ hơn',
                                  'Load older messages',
                                ),
                              ),
                            ),
                          );
                        }
                        if (state.loaded && state.messages.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                dmText(
                                  context,
                                  'Chưa có tin nhắn trong cuộc trò chuyện này.',
                                  'No messages in this conversation yet.',
                                ),
                                style: VnlfTypography.body(colors.muted),
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      }
                      final message =
                          state.messages[state.messages.length - index - 1];
                      final own = message.authorId == viewerUserId;
                      final canAct =
                          state.canMutateMessages &&
                          !state.sending &&
                          state.busyMessageId == null &&
                          !state.mutatingConversation;
                      return DirectMessageTile(
                        key: ValueKey('dm-message-${message.id}'),
                        message: message,
                        own: own,
                        canAct: canAct,
                        busy: state.busyMessageId == message.id,
                        isFirstUnread:
                            activeConversation.firstUnreadMessageId ==
                            message.id,
                        isHighlighted: state.highlightedMessageId == message.id,
                        isPeerReadBarrier:
                            own &&
                            activeConversation.peerLastReadMessageId ==
                                message.id,
                        onReply: () => controller.setReplyTarget(message),
                        onReact: (emoji) =>
                            controller.toggleReaction(message.id, emoji),
                        onEdit: () =>
                            _promptEditMessage(context, controller, message),
                        onDelete: () =>
                            _confirmDeleteMessage(context, controller, message),
                        onTapReply: controller.jumpToMessageContext,
                        pollBuilder: pollBuilder,
                      );
                    },
                  ),
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: DirectMessageComposer(
            key: ValueKey('dm-composer-${conversation.id}'),
            conversationId: conversation.id,
          ),
        ),
      ],
    );
  }

  Future<void> _handleConversationMenu(
    BuildContext context,
    WidgetRef ref, {
    required String action,
    required DmConversation conversation,
  }) async {
    final controller = ref.read(dmTimelineProvider(conversation.id).notifier);
    switch (action) {
      case 'mark_read':
        await controller.markRead();
      case 'block':
        final confirmed = await _confirmAction(
          context,
          title: dmText(context, 'Chặn người dùng?', 'Block user?'),
          message: dmText(
            context,
            'Bạn và ${conversation.peer.displayName} sẽ không thể nhắn tin cho nhau cho tới khi bỏ chặn.',
            'You and ${conversation.peer.displayName} will not be able to message each other until unblocked.',
          ),
          confirmLabel: dmText(context, 'Chặn', 'Block'),
        );
        if (confirmed) {
          await controller.blockPeer();
        }
      case 'unblock':
        await controller.unblockPeer();
      case 'report':
        await showDmReportDialog(context, ref, conversationId: conversation.id);
      case 'delete_conversation':
        final confirmed = await _confirmAction(
          context,
          title: dmText(
            context,
            'Xóa cuộc trò chuyện?',
            'Delete conversation?',
          ),
          message: dmText(
            context,
            'Cuộc trò chuyện sẽ được ẩn khỏi hộp thư của bạn.',
            'This conversation will be removed from your inbox.',
          ),
          confirmLabel: dmText(context, 'Xóa', 'Delete'),
        );
        if (confirmed) {
          await controller.deleteConversation();
        }
    }
  }

  Future<void> _promptEditMessage(
    BuildContext context,
    DmTimelineController controller,
    DmMessage message,
  ) async {
    final textController = TextEditingController(text: message.content);
    final updated = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          dmText(dialogContext, 'Chỉnh sửa tin nhắn', 'Edit message'),
        ),
        content: TextField(
          key: const Key('dm-edit-message-input'),
          controller: textController,
          autofocus: true,
          minLines: 1,
          maxLines: 5,
          maxLength: 4000,
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(dmText(dialogContext, 'Hủy', 'Cancel')),
          ),
          FilledButton(
            key: const Key('dm-edit-message-save'),
            onPressed: () =>
                Navigator.pop(dialogContext, textController.text.trim()),
            child: Text(dmText(dialogContext, 'Lưu', 'Save')),
          ),
        ],
      ),
    );
    textController.dispose();
    if (updated == null || updated.isEmpty || updated == message.content) {
      return;
    }
    await controller.editMessage(message.id, updated);
  }

  Future<void> _confirmDeleteMessage(
    BuildContext context,
    DmTimelineController controller,
    DmMessage message,
  ) async {
    final confirmed = await _confirmAction(
      context,
      title: dmText(context, 'Xóa tin nhắn?', 'Delete message?'),
      message: dmText(
        context,
        'Tin nhắn này sẽ bị xóa khỏi cuộc trò chuyện.',
        'This message will be deleted from the conversation.',
      ),
      confirmLabel: dmText(context, 'Xóa', 'Delete'),
    );
    if (confirmed) {
      await controller.deleteMessage(message.id);
    }
  }

  Future<bool> _confirmAction(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(dmText(dialogContext, 'Hủy', 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
