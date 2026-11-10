import '../../../i18n/vi.dart';
import '../../realtime/presentation/chat_realtime_bindings.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../design_system/design_system.dart';
import '../domain/channel_models.dart';
import 'channel_feedback.dart';
import 'live_channel_composer.dart';
import '../../communication/presentation/communication_directory.dart';
import 'live_channel_state.dart';
import 'live_message_tile.dart';

class LiveChannelsScreen extends ConsumerWidget {
  const LiveChannelsScreen({super.key, this.channelSlug});
  final String? channelSlug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionStateProvider);
    if (session == null) {
      return Center(
        child: VnlfStateCard(
          icon: Icons.forum_outlined,
          title: (vi.app.channels.dangNhapDeXem),
          message: (vi.app.channels.kenhVaLichSu),
          actionLabel: (vi.common.dangNhap),
          onAction: () => context.push('/login'),
        ),
      );
    }
    final channels = ref.watch(liveChannelsProvider);
    final channel = channels.valueOrNull
        ?.where((item) => item.slug == channelSlug && !item.isArchived)
        .firstOrNull;
    return PopScope(
      canPop: channelSlug == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          context.go('/channels');
        }
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final viewport = MediaQuery.sizeOf(context).width;
          final wide =
              VnlfViewportSize.fromWidth(viewport) != VnlfViewportSize.mobile &&
              constraints.maxWidth >= 650;
          final directory = CommunicationDirectory(
            activeChannelId: channel?.id,
          );
          if (!wide && channelSlug == null) return directory;
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
                child: channel == null
                    ? Center(
                        child: channels.isLoading
                            ? const CircularProgressIndicator()
                            : channelSlug == null
                            ? Text((vi.app.channels.chonMotKenhHoac))
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text((vi.app.channels.khongMoDuocKenh)),
                                  TextButton(
                                    onPressed: () =>
                                        ref.invalidate(liveChannelsProvider),
                                    child: Text((vi.common.thuLai)),
                                  ),
                                  if (!wide)
                                    TextButton(
                                      onPressed: () => context.go('/channels'),
                                      child: Text(
                                        (vi.app.channels.danhSachTroChuyen),
                                      ),
                                    ),
                                ],
                              ),
                      )
                    : Column(
                        children: [
                          SizedBox(
                            height: 54,
                            child: Row(
                              children: [
                                if (!wide)
                                  IconButton(
                                    tooltip:
                                        (vi.app.channels.danhSachTroChuyen),
                                    onPressed: () => context.go('/channels'),
                                    icon: const Icon(Icons.arrow_back),
                                  ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    '#${channel.slug}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  tooltip: (vi.app.common.lamMoiTinNhan),
                                  icon: const Icon(Icons.refresh),
                                  onPressed: () {
                                    ref.read(apiClientProvider).clearCache();
                                    ref
                                        .read(
                                          channelTimelineProvider(channel.id)
                                              .notifier,
                                        )
                                        .refresh();
                                  },
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          Expanded(
                            child: ChannelRealtimeBinding(
                              channelId: channel.id,
                              child: _ChannelHistory(
                                key: ValueKey(
                                  '${session.userId}-${channel.id}',
                                ),
                                channel: channel,
                                userId: session.userId,
                                canPost: channel.canPost(session.role),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ChannelHistory extends ConsumerWidget {
  const _ChannelHistory({
    super.key,
    required this.channel,
    required this.userId,
    required this.canPost,
  });
  final ChatChannel channel;
  final String userId;
  final bool canPost;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(channelTimelineProvider(channel.id));
    final controller = ref.read(channelTimelineProvider(channel.id).notifier);
    final colors = VnlfColors.of(context);
    return Column(
      children: [
        if (state.loading && state.loaded) const LinearProgressIndicator(),
        if (state.failure != null)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              state.confirmedRefreshFailed
                  ? (vi.app.common.mayChuDaXac)
                  : channelFailure(context, state.failure),
              style: TextStyle(color: colors.red),
            ),
          ),
        if (state.operationFailure != null)
          Padding(
            key: const Key('channel-operation-error'),
            padding: const EdgeInsets.all(8),
            child: Text(
              channelFailure(context, state.operationFailure, mutation: true),
              style: TextStyle(color: colors.red),
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
                    separatorBuilder: (_, index) => const SizedBox(height: 8),
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
                              onPressed: controller.loadOlder,
                              child: Text((vi.app.common.taiTinNhanCu)),
                            ),
                          );
                        }
                        if (state.loaded && state.messages.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text((vi.app.channels.chuaCoTinNhan)),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      }
                      final message =
                          state.messages[state.messages.length - index - 1];
                      return LiveMessageTile(
                        key: ValueKey(message.id),
                        message: message,
                        own: message.author.id == userId,
                        canAct:
                            canPost &&
                            !state.sending &&
                            state.busyMessageId == null,
                        busy: state.busyMessageId == message.id,
                        onReply: () => controller.replyTo(message),
                        onReact: (emoji) => controller.react(message.id, emoji),
                        onEdit: () => _edit(context, ref, message),
                        onDelete: () => _delete(context, ref, message),
                      );
                    },
                  ),
                ),
        ),
        if (channel.slowModeSeconds > 0)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Text(
              format(vi.app.channels.cheDoCham, {
                'seconds': channel.slowModeSeconds,
              }),
              style: VnlfTypography.caption(colors.muted),
            ),
          ),
        if (canPost)
          LiveChannelComposer(key: ValueKey(channel.id), channel: channel)
        else
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              channel.isArchived
                  ? (vi.app.channels.kenhDaLuuTru)
                  : (vi.app.channels.banChuaCoQuyenGui),
            ),
          ),
      ],
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    ChannelMessage message,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text((vi.chatUi.xoaTinNhan)),
        content: Text((vi.app.channels.tinNhanSeBi)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: Text((vi.common.huy)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: Text((vi.common.xoa)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref
          .read(channelTimelineProvider(channel.id).notifier)
          .delete(message.id);
    }
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    ChannelMessage message,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (_) =>
          _EditMessageDialog(channelId: channel.id, message: message),
    );
  }
}

class _EditMessageDialog extends ConsumerStatefulWidget {
  const _EditMessageDialog({required this.channelId, required this.message});
  final String channelId;
  final ChannelMessage message;
  @override
  ConsumerState<_EditMessageDialog> createState() => _EditMessageDialogState();
}

class _EditMessageDialogState extends ConsumerState<_EditMessageDialog> {
  late final _input = TextEditingController(text: widget.message.content);
  bool _saving = false;
  String? _error;
  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: AlertDialog(
      title: Text((vi.app.common.chinhSuaTinNhan)),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _input,
              enabled: !_saving,
              minLines: 2,
              maxLines: 6,
              maxLength: 4000,
              onChanged: (_) => setState(() {}),
            ),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: VnlfColors.of(context).red),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: Text((vi.common.huy)),
        ),
        FilledButton(
          onPressed: _saving || _input.text.trim().isEmpty
              ? null
              : () async {
                  setState(() {
                    _saving = true;
                    _error = null;
                  });
                  final controller = ref.read(
                    channelTimelineProvider(widget.channelId).notifier,
                  );
                  await controller.edit(widget.message.id, _input.text.trim());
                  if (!mounted || !context.mounted) return;
                  final failure = ref
                      .read(channelTimelineProvider(widget.channelId))
                      .operationFailure;
                  if (failure == null) {
                    Navigator.pop(context);
                  } else {
                    setState(() {
                      _saving = false;
                      _error = channelFailure(context, failure, mutation: true);
                    });
                  }
                },
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text((vi.common.luu)),
        ),
      ],
    ),
  );
}
