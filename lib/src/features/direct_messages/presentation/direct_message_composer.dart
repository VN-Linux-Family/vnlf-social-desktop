import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/design_system.dart';
import '../domain/direct_message_models.dart';
import 'direct_message_feedback.dart';
import 'direct_message_state.dart';

class DirectMessageComposer extends ConsumerStatefulWidget {
  const DirectMessageComposer({super.key, required this.conversationId});

  final String conversationId;

  @override
  ConsumerState<DirectMessageComposer> createState() =>
      _DirectMessageComposerState();
}

class _DirectMessageComposerState extends ConsumerState<DirectMessageComposer> {
  final TextEditingController _input = TextEditingController();

  @override
  void initState() {
    super.initState();
    _input.text = ref.read(dmTimelineProvider(widget.conversationId)).draft;
  }

  @override
  void didUpdateWidget(covariant DirectMessageComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.conversationId != widget.conversationId) {
      _input.text = ref.read(dmTimelineProvider(widget.conversationId)).draft;
    }
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dmTimelineProvider(widget.conversationId));
    final controller = ref.read(
      dmTimelineProvider(widget.conversationId).notifier,
    );
    ref.listen<String>(
      dmTimelineProvider(widget.conversationId).select((s) => s.draft),
      (_, next) {
        if (_input.text != next) {
          _input.value = TextEditingValue(
            text: next,
            selection: TextSelection.collapsed(offset: next.length),
          );
        }
      },
    );

    final colors = VnlfColors.of(context);
    final conversation = state.conversation;
    final viewerState = conversation?.viewerState ?? state.viewerState;

    if (viewerState == DmViewerState.blockedByMe) {
      return _LockedComposerCard(
        key: const Key('dm-blocked-banner'),
        icon: Icons.block_outlined,
        message: dmText(
          context,
          'Bạn đã chặn người dùng này. Bỏ chặn để có thể gửi lại yêu cầu trò chuyện.',
          'You blocked this user. Unblock them to send a new message request.',
        ),
        actions: <Widget>[
          OutlinedButton.icon(
            key: const Key('dm-unblock-button'),
            onPressed: state.mutatingConversation
                ? null
                : controller.unblockPeer,
            icon: const Icon(Icons.lock_open_outlined, size: 18),
            label: Text(dmText(context, 'Bỏ chặn', 'Unblock')),
          ),
        ],
      );
    }

    if (conversation != null && conversation.isIncomingRequest) {
      return _LockedComposerCard(
        key: const Key('dm-incoming-request-banner'),
        icon: Icons.mark_chat_unread_outlined,
        message: dmText(
          context,
          '${conversation.peer.displayName} muốn nhắn tin cho bạn. Chấp nhận để bắt đầu trò chuyện hoặc từ chối yêu cầu này.',
          '${conversation.peer.displayName} wants to message you. Accept to start chatting or decline this request.',
        ),
        actions: <Widget>[
          FilledButton.icon(
            key: const Key('dm-accept-request-button'),
            onPressed: state.mutatingConversation
                ? null
                : controller.acceptRequest,
            icon: const Icon(Icons.check_rounded, size: 18),
            label: Text(dmText(context, 'Chấp nhận', 'Accept')),
          ),
          OutlinedButton.icon(
            key: const Key('dm-decline-request-button'),
            onPressed: state.mutatingConversation
                ? null
                : controller.declineRequest,
            icon: const Icon(Icons.close_rounded, size: 18),
            label: Text(dmText(context, 'Từ chối', 'Decline')),
          ),
        ],
      );
    }

    if (conversation != null && conversation.requiresNewRequest) {
      return _LockedComposerCard(
        key: const Key('dm-request-required-banner'),
        icon: Icons.outgoing_mail,
        message: dmText(
          context,
          'Cuộc trò chuyện này cần gửi lại yêu cầu nhắn tin trước khi tiếp tục.',
          'A new message request is required before continuing this conversation.',
        ),
        actions: <Widget>[
          FilledButton.icon(
            key: const Key('dm-send-request-button'),
            onPressed: state.mutatingConversation
                ? null
                : controller.sendNewRequest,
            icon: const Icon(Icons.send_outlined, size: 18),
            label: Text(
              dmText(context, 'Gửi yêu cầu nhắn tin', 'Send message request'),
            ),
          ),
        ],
      );
    }

    if (!state.canSend) {
      return _LockedComposerCard(
        key: const Key('dm-awaiting-acceptance-banner'),
        icon: Icons.hourglass_top_rounded,
        message: viewerState == DmViewerState.awaitingAcceptance
            ? dmText(
                context,
                'Đang chờ người nhận chấp nhận yêu cầu nhắn tin của bạn.',
                'Waiting for the recipient to accept your message request.',
              )
            : dmText(
                context,
                'Hiện không thể gửi tin nhắn trong cuộc trò chuyện này.',
                'You cannot send messages in this conversation right now.',
              ),
      );
    }

    final peerName = conversation?.peer.displayName ?? '';
    final canSubmit =
        !state.sending &&
        !state.uploadingAttachment &&
        state.busyMessageId == null &&
        !state.mutatingConversation &&
        (tidyDmMessageText(state.draft).isNotEmpty ||
            state.pendingAttachments.isNotEmpty);

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(VnlfDimensions.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (conversation != null &&
              conversation.isAwaitingAcceptance &&
              conversation.status == DmConversationStatus.requested)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                dmText(
                  context,
                  'Bạn có thể gửi tin nhắn mở đầu cho yêu cầu trò chuyện này.',
                  'You can send an opening message with this chat request.',
                ),
                style: VnlfTypography.caption(colors.muted),
              ),
            ),
          if (state.replyTarget case final reply?)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      '${dmText(context, 'Đang trả lời', 'Replying to')} ${reply.author.displayName}: ${reply.content}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: VnlfTypography.caption(colors.muted),
                    ),
                  ),
                  IconButton(
                    tooltip: dmText(context, 'Hủy trả lời', 'Cancel reply'),
                    onPressed: state.sending
                        ? null
                        : () => controller.setReplyTarget(null),
                    icon: const Icon(Icons.close, size: 18),
                  ),
                ],
              ),
            ),
          if (state.pendingAttachments.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: <Widget>[
                  for (final asset in state.pendingAttachments)
                    InputChip(
                      label: Text(
                        '${dmText(context, 'Ảnh', 'Image')} (${asset.mime})',
                      ),
                      onDeleted: state.sending
                          ? null
                          : () => controller.removePendingAttachment(
                              asset.assetId,
                            ),
                    ),
                ],
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Expanded(
                child: TextField(
                  key: const Key('dm-chat-input'),
                  controller: _input,
                  enabled: !state.sending,
                  minLines: 1,
                  maxLines: 4,
                  maxLength: 4000,
                  textInputAction: TextInputAction.newline,
                  onChanged: controller.updateDraft,
                  decoration: InputDecoration(
                    hintText: peerName.isEmpty
                        ? dmText(
                            context,
                            'Nhập tin nhắn...',
                            'Write a message...',
                          )
                        : '${dmText(context, 'Nhắn tin cho', 'Message')} $peerName...',
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                  ),
                ),
              ),
              IconButton(
                key: const Key('dm-send-button'),
                tooltip: dmText(context, 'Gửi tin nhắn', 'Send message'),
                onPressed: canSubmit ? controller.send : null,
                icon: state.sending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.send_rounded, color: colors.brand),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LockedComposerCard extends StatelessWidget {
  const _LockedComposerCard({
    super.key,
    required this.icon,
    required this.message,
    this.actions = const <Widget>[],
  });

  final IconData icon;
  final String message;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceSoft,
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(VnlfDimensions.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 18, color: colors.muted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(message, style: VnlfTypography.body(colors.ink)),
              ),
            ],
          ),
          if (actions.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: actions),
          ],
        ],
      ),
    );
  }
}
