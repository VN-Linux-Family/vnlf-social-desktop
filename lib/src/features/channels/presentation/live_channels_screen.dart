import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../design_system/design_system.dart';
import '../domain/channel_models.dart';
import 'channel_feedback.dart';
import 'live_channel_composer.dart';
import 'live_channel_directory.dart';
import 'live_channel_state.dart';
import 'live_message_tile.dart';

class LiveChannelsScreen extends ConsumerWidget {
  const LiveChannelsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionStateProvider);
    if (session == null) {
      return Center(
        child: SingleChildScrollView(
          child: VnlfStateCard(
            icon: Icons.forum_outlined,
            title: channelText(
              context,
              'Đăng nhập để xem kênh cộng đồng',
              'Sign in to view community channels',
            ),
            message: channelText(
              context,
              'Kênh và lịch sử trò chuyện chỉ dành cho thành viên.',
              'Channels and chat history are available to members.',
            ),
            actionLabel: channelText(context, 'Đăng nhập', 'Sign in'),
            onAction: () => context.push('/login'),
          ),
        ),
      );
    }
    final channels = ref.watch(liveChannelsProvider);
    return Column(
      children: [
        VnlfCenterPageHeader(
          title: channelText(context, 'Kênh & trò chuyện', 'Channels & chat'),
        ),
        Expanded(
          child: channels.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: SingleChildScrollView(
                child: VnlfStateCard(
                  icon: Icons.cloud_off_outlined,
                  title: channelText(
                    context,
                    'Không tải được kênh',
                    'Channels could not be loaded',
                  ),
                  message: channelFailure(context, error),
                  isError: true,
                  actionLabel: channelText(context, 'Thử lại', 'Try again'),
                  onAction: () {
                    ref.read(apiClientProvider).clearCache();
                    ref.invalidate(liveChannelsProvider);
                  },
                ),
              ),
            ),
            data: (items) {
              if (items.isEmpty) {
                return Center(
                  child: Text(
                    channelText(context, 'Chưa có kênh', 'No channels yet'),
                  ),
                );
              }
              final sorted = [...items]
                ..sort((a, b) => a.position.compareTo(b.position));
              final selected = ref.watch(liveSelectedChannelProvider);
              final channel =
                  sorted.where((c) => c.id == selected).firstOrNull ??
                  sorted.first;
              return LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 700;
                  return Row(
                    children: [
                      if (wide) ...[
                        const SizedBox(
                          width: 210,
                          child: LiveChannelDirectory(),
                        ),
                        const VerticalDivider(width: 12),
                      ],
                      Expanded(
                        child: Column(
                          children: [
                            ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              leading: wide
                                  ? null
                                  : IconButton(
                                      tooltip: channelText(
                                        context,
                                        'Chọn kênh',
                                        'Choose channel',
                                      ),
                                      icon: const Icon(Icons.tag),
                                      onPressed: () =>
                                          showModalBottomSheet<void>(
                                            context: context,
                                            builder: (sheet) => SafeArea(
                                              child: LiveChannelDirectory(
                                                onSelected: () =>
                                                    Navigator.pop(sheet),
                                              ),
                                            ),
                                          ),
                                    ),
                              title: Text(
                                '#${channel.slug}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: channel.description.isEmpty
                                  ? null
                                  : Text(
                                      channel.description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                              trailing: IconButton(
                                tooltip: channelText(
                                  context,
                                  'Làm mới tin nhắn',
                                  'Refresh messages',
                                ),
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
                            ),
                            Expanded(
                              child: _ChannelHistory(
                                key: ValueKey(
                                  '${session.userId}-${channel.id}',
                                ),
                                channel: channel,
                                userId: session.userId,
                                canPost: channel.canPost(session.role),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
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
                  ? channelText(
                      context,
                      'Máy chủ đã xác nhận thao tác, nhưng chưa tải lại được lịch sử. Hãy làm mới; không cần gửi lại.',
                      'The server confirmed the action, but history could not be reloaded. Refresh; do not send again.',
                    )
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
                              child: Text(
                                channelText(
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
                                channelText(
                                  context,
                                  'Chưa có tin nhắn',
                                  'No messages yet',
                                ),
                              ),
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
              '${channelText(context, 'Chế độ chậm', 'Slow mode')}: ${channel.slowModeSeconds} ${channelText(context, 'giây', 'seconds')}',
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
                  ? channelText(
                      context,
                      'Kênh đã lưu trữ. Chỉ có thể xem tin nhắn.',
                      'This channel is archived. Messages are read only.',
                    )
                  : channelText(
                      context,
                      'Bạn chưa có quyền gửi tin nhắn trong kênh này.',
                      'You do not have permission to post in this channel.',
                    ),
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
        title: Text(channelText(context, 'Xóa tin nhắn?', 'Delete message?')),
        content: Text(
          channelText(
            context,
            'Tin nhắn sẽ bị xóa khỏi kênh.',
            'This message will be deleted from the channel.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: Text(channelText(context, 'Hủy', 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: Text(channelText(context, 'Xóa', 'Delete')),
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
      title: Text(channelText(context, 'Chỉnh sửa tin nhắn', 'Edit message')),
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
          child: Text(channelText(context, 'Hủy', 'Cancel')),
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
              : Text(channelText(context, 'Lưu', 'Save')),
        ),
      ],
    ),
  );
}
