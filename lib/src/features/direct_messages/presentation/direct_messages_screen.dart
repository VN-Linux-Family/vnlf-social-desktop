import '../../../i18n/vi.dart';
import '../../realtime/presentation/chat_realtime_bindings.dart';

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
  const DirectMessagesScreen({super.key, this.conversationId});

  final String? conversationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionStateProvider);
    if (session == null) {
      return Center(
        child: SingleChildScrollView(
          child: VnlfStateCard(
            icon: Icons.mail_outline_rounded,
            title: vi.app.directMessages.dangNhapDeXem,
            message: vi.app.directMessages.tinNhanRiengTu,
            actionLabel: vi.common.dangNhap,
            onAction: () => context.push('/login'),
          ),
        ),
      );
    }

    final inbox = ref.watch(dmInboxProvider);
    final id = conversationId;
    return PopScope(
      canPop: id == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          context.go('/messages');
        }
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final viewport = MediaQuery.sizeOf(context).width;
          final wide =
              VnlfViewportSize.fromWidth(viewport) != VnlfViewportSize.mobile &&
              constraints.maxWidth >= 650;
          final directory = CommunicationDirectory(activeConversationId: id);
          if (!wide && id == null) return directory;
          return Row(
            children: [
              if (wide) ...[
                SizedBox(
                  width:
                      VnlfViewportSize.fromWidth(viewport) ==
                          VnlfViewportSize.desktop
                      ? 240
                      : 205,
                  child: directory,
                ),
                const VerticalDivider(width: 1),
              ],
              Expanded(
                child: id == null
                    ? Center(child: Text(vi.app.directMessages.chonMotCuocTro))
                    : DmRealtimeBinding(
                        conversationId: id,
                        child: _DmConversationPane(
                          key: ValueKey('${session.userId}-$id'),
                          conversationId: id,
                          conversation: inbox.conversations
                              .where((item) => item.id == id)
                              .firstOrNull,
                          viewerUserId: session.userId,
                          wide: wide,
                          onOpenInboxSheet: () => context.go('/messages'),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
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
  });

  final String conversationId;
  final DmConversation? conversation;
  final String viewerUserId;
  final bool wide;
  final VoidCallback onOpenInboxSheet;

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
                tooltip: vi.app.directMessages.danhSachCuocTro,
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
                      title: vi.app.directMessages.khongMoDuocCuoc,
                      message: dmFailureMessage(context, state.failure),
                      isError: true,
                      actionLabel: vi.common.thuLai,
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
                    vi.app.directMessages.dangXemNguCanh,
                    style: VnlfTypography.caption(colors.ink),
                  ),
                ),
                TextButton(
                  onPressed: controller.returnToLatestMessages,
                  child: Text(vi.app.directMessages.veTinNhanMoi),
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
                  ? vi.app.common.mayChuDaXac
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
              format(vi.app.directMessages.daGuiBaoCao, {
                'statusNotice': state.statusNotice,
              }),
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
                              child: Text(vi.app.common.taiTinNhanCu),
                            ),
                          );
                        }
                        if (state.loaded && state.messages.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                vi.app.directMessages.chuaCoTinNhan,
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
          title: vi.app.directMessages.chanNguoiDung,
          message: format(vi.app.directMessages.banVaSeKhong, {
            'displayName': conversation.peer.displayName,
          }),
          confirmLabel: vi.common.chan,
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
          title: vi.app.directMessages.xoaCuocTroChuyen,
          message: vi.app.directMessages.cuocTroChuyenSe,
          confirmLabel: vi.common.xoa,
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
        title: Text(vi.app.common.chinhSuaTinNhan),
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
            child: Text(vi.common.huy),
          ),
          FilledButton(
            key: const Key('dm-edit-message-save'),
            onPressed: () =>
                Navigator.pop(dialogContext, textController.text.trim()),
            child: Text(vi.common.luu),
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
      title: vi.chatUi.xoaTinNhan,
      message: vi.app.directMessages.tinNhanNaySe,
      confirmLabel: vi.common.xoa,
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
            child: Text(vi.common.huy),
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
