import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/design_system.dart';
import '../../../app/providers.dart';
import '../../../i18n/vi.dart';
import 'dm_attachment_picker.dart';
import '../domain/direct_message_models.dart';
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
  bool _selecting = false;
  String? _pickerError;

  Future<void> _pick() async {
    if (_selecting) return;
    final owner = ref.read(sessionStateProvider)?.userId;
    if (owner == null) return;
    final controller = ref.read(
      dmTimelineProvider(widget.conversationId).notifier,
    );
    bool current() =>
        mounted &&
        ref.read(sessionStateProvider)?.userId == owner &&
        identical(
          controller,
          ref.read(dmTimelineProvider(widget.conversationId).notifier),
        );
    setState(() {
      _selecting = true;
      _pickerError = null;
    });
    try {
      final files = await ref.read(dmAttachmentPickerProvider)();
      if (!current()) return;
      final remaining =
          4 -
          ref
              .read(dmTimelineProvider(widget.conversationId))
              .pendingAttachments
              .length;
      if (files.length > remaining) {
        setState(() => _pickerError = vi.app.directMessages.moiTinNhanCo);
        return;
      }
      for (final file in files) {
        if (!current()) return;
        await controller.uploadAndAttach(file);
        if (!current() ||
            ref
                    .read(dmTimelineProvider(widget.conversationId))
                    .operationFailure !=
                null) {
          break;
        }
      }
    } catch (_) {
      if (current()) {
        setState(() => _pickerError = vi.app.directMessages.khongMoDuocAnh);
      }
    } finally {
      if (mounted) setState(() => _selecting = false);
    }
  }

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
        message: vi.app.directMessages.banDaChanNguoi,
        actions: <Widget>[
          OutlinedButton.icon(
            key: const Key('dm-unblock-button'),
            onPressed: state.mutatingConversation
                ? null
                : controller.unblockPeer,
            icon: const Icon(Icons.lock_open_outlined, size: 18),
            label: Text(vi.directMessageLiveView.boChan),
          ),
        ],
      );
    }

    if (conversation != null && conversation.isIncomingRequest) {
      return _LockedComposerCard(
        key: const Key('dm-incoming-request-banner'),
        icon: Icons.mark_chat_unread_outlined,
        message: format(vi.app.directMessages.muonNhanTinCho, {
          'displayName': conversation.peer.displayName,
        }),
        actions: <Widget>[
          FilledButton.icon(
            key: const Key('dm-accept-request-button'),
            onPressed: state.mutatingConversation
                ? null
                : controller.acceptRequest,
            icon: const Icon(Icons.check_rounded, size: 18),
            label: Text(vi.app.directMessages.chapNhan),
          ),
          OutlinedButton.icon(
            key: const Key('dm-decline-request-button'),
            onPressed: state.mutatingConversation
                ? null
                : controller.declineRequest,
            icon: const Icon(Icons.close_rounded, size: 18),
            label: Text(vi.app.directMessages.tuChoi),
          ),
        ],
      );
    }

    if (conversation != null && conversation.requiresNewRequest) {
      return _LockedComposerCard(
        key: const Key('dm-request-required-banner'),
        icon: Icons.outgoing_mail,
        message: vi.app.directMessages.cuocTroChuyenNay,
        actions: <Widget>[
          FilledButton.icon(
            key: const Key('dm-send-request-button'),
            onPressed: state.mutatingConversation
                ? null
                : controller.sendNewRequest,
            icon: const Icon(Icons.send_outlined, size: 18),
            label: Text(vi.app.directMessages.guiYeuCauNhan),
          ),
        ],
      );
    }

    if (!state.canSend) {
      return _LockedComposerCard(
        key: const Key('dm-awaiting-acceptance-banner'),
        icon: Icons.hourglass_top_rounded,
        message: viewerState == DmViewerState.awaitingAcceptance
            ? vi.app.directMessages.dangChoNguoiNhan
            : vi.app.directMessages.hienKhongTheGui,
      );
    }

    final peerName = conversation?.peer.displayName ?? '';
    final canSubmit =
        !_selecting &&
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
          if (_pickerError != null)
            Text(
              _pickerError!,
              key: const Key('dm-picker-error'),
              style: TextStyle(color: colors.red),
            ),
          if (_selecting || state.uploadingAttachment)
            const LinearProgressIndicator(),
          if (conversation != null &&
              conversation.isAwaitingAcceptance &&
              conversation.status == DmConversationStatus.requested)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                vi.app.directMessages.banCoTheGui,
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
                      '${'Đang trả lời'} ${reply.author.displayName}: ${reply.content}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: VnlfTypography.caption(colors.muted),
                    ),
                  ),
                  IconButton(
                    tooltip: vi.chatUi.huyTraLoi,
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
                        asset.fileName.isEmpty
                            ? vi.common.anhDinhKem
                            : asset.fileName,
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
              IconButton(
                key: const Key('dm-attach-button'),
                tooltip: vi.chatUi.dinhKemAnh,
                onPressed:
                    _selecting ||
                        state.uploadingAttachment ||
                        state.sending ||
                        state.pendingAttachments.length >= 4
                    ? null
                    : _pick,
                icon: const Icon(Icons.add_photo_alternate_outlined),
              ),
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
                        ? vi.app.directMessages.nhapTinNhan
                        : '${'Nhắn tin cho'} $peerName...',
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
                tooltip: vi.chatUi.guiTinNhan,
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
