import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../design_system/design_system.dart';
import 'dm_conversation_header.dart';
import '../domain/direct_message_models.dart';
import 'direct_message_composer.dart';
import 'direct_message_feedback.dart';
import '../../communication/presentation/communication_directory.dart';
import 'direct_message_panels.dart';
import 'direct_message_state.dart';
import 'direct_message_tile.dart';

class DirectMessagesScreen extends ConsumerWidget {
  const DirectMessagesScreen({
    super.key,
    this.pollBuilder,
    this.conversationId,
  });

  final DmPollWidgetBuilder? pollBuilder;
  final String? conversationId;

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
    final id = conversationId;
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewport = MediaQuery.sizeOf(context).width;
        final wide = viewport > 840 && constraints.maxWidth >= 650;
        final directory = CommunicationDirectory(activeConversationId: id);
        if (!wide && id == null) return directory;
        return Row(
          children: [
            if (wide) ...[
              SizedBox(width: viewport >= 1181 ? 240 : 205, child: directory),
              const VerticalDivider(width: 1),
            ],
            Expanded(
              child: id == null
                  ? Center(
                      child: Text(
                        dmText(
                          context,
                          'Chọn một cuộc trò chuyện',
                          'Choose a conversation',
                        ),
                      ),
                    )
                  : _DmConversationPane(
                      key: ValueKey('${session.userId}-$id'),
                      conversationId: id,
                      conversation: inbox.conversations
                          .where((item) => item.id == id)
                          .firstOrNull,
                      viewerUserId: session.userId,
                      wide: wide,
                      onOpenInboxSheet: () => context.go('/messages'),
                      pollBuilder: pollBuilder,
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _DmConversationPane extends ConsumerWidget {
  const _DmConversationPane({
    super.key,
    required this.conversationId,
    this.conversation,
    required this.viewerUserId,
    required this.wide,
    required this.onOpenInboxSheet,
    this.pollBuilder,
  });

  final String conversationId;
  final DmConversation? conversation;
  final String viewerUserId;
  final bool wide;
  final VoidCallback onOpenInboxSheet;
  final DmPollWidgetBuilder? pollBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dmTimelineProvider(conversationId));
    final controller = ref.read(dmTimelineProvider(conversationId).notifier);
    final colors = VnlfColors.of(context);
    final activeConversation = state.conversation ?? conversation;
    if (activeConversation == null) {
      return Column(
        children: [
          if (!wide)
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                tooltip: dmText(
                  context,
                  'Danh sách cuộc trò chuyện',
                  'Conversation list',
                ),
                onPressed: onOpenInboxSheet,
                icon: const Icon(Icons.arrow_back),
              ),
            ),
          Expanded(
            child: Center(
              child: state.loading
                  ? const CircularProgressIndicator()
                  : VnlfStateCard(
                      icon: Icons.chat_bubble_outline,
                      title: dmText(
                        context,
                        'Không mở được cuộc trò chuyện',
                        'Could not open conversation',
                      ),
                      message: dmFailureMessage(context, state.failure),
                      isError: true,
                      actionLabel: dmText(context, 'Thử lại', 'Try again'),
                      onAction: controller.refresh,
                    ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: <Widget>[
        DmConversationHeader(
          conversation: activeConversation,
          wide: wide,
          loading: state.loading,
          busy: state.mutatingConversation,
          onBack: onOpenInboxSheet,
          onSearch: () =>
              showDmSearchSheet(context, conversationId: conversationId),
          onMedia: () =>
              showDmMediaSheet(context, conversationId: conversationId),
          onRefresh: () {
            ref.read(apiClientProvider).clearCache();
            controller.refresh();
          },
          onAction: (action) => _handleConversationMenu(
            context,
            ref,
            action: action,
            conversation: activeConversation,
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
            key: ValueKey('dm-composer-$conversationId'),
            conversationId: conversationId,
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
