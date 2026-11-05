import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../design_system/design_system.dart';
import '../../shared/presentation/feature_samples.dart';
import 'channel_directory.dart';
import 'channel_state.dart';

class ChannelsScreen extends ConsumerStatefulWidget {
  const ChannelsScreen({super.key});

  @override
  ConsumerState<ChannelsScreen> createState() => _ChannelsScreenState();
}

class _ChannelsScreenState extends ConsumerState<ChannelsScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _drafts = <String, String>{};

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send(String channel) {
    if (_input.text.trim().isEmpty) return;
    final session =
        ref.read(sessionStateProvider) ?? ref.read(sessionProvider).valueOrNull;
    AuthorData? author;
    if (session != null) {
      author = AuthorData(
        id: session.userId,
        username: session.username,
        displayName: session.displayName,
        avatarUrl: session.avatarUrl,
        role: session.role,
      );
    }
    ref
        .read(channelMessagesProvider.notifier)
        .send(channel, _input.text, author);
    _input.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          0,
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final english = Localizations.localeOf(context).languageCode == 'en';
    final colors = VnlfColors.of(context);
    final session =
        ref.watch(sessionStateProvider) ??
        ref.watch(sessionProvider).valueOrNull;
    final selected = ref.watch(selectedChannelProvider);
    ref.listen(selectedChannelProvider, (previous, next) {
      if (previous != null) _drafts[previous] = _input.text;
      _input.text = _drafts[next] ?? '';
      if (_scroll.hasClients) _scroll.jumpTo(0);
    });
    final channel = localChannels.firstWhere((item) => item.id == selected);
    final messages = ref.watch(
      channelMessagesProvider.select((state) => state[selected]!),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final showDirectory = constraints.maxWidth >= 620;
        return Column(
          children: [
            VnlfCenterPageHeader(
              title: english ? 'Channels & chat' : 'Kênh & trò chuyện',
              leading: showDirectory
                  ? null
                  : IconButton(
                      tooltip: english ? 'Choose channel' : 'Chọn kênh',
                      icon: const Icon(Icons.tag),
                      onPressed: () => showModalBottomSheet<void>(
                        context: context,
                        backgroundColor: colors.surface,
                        builder: (sheetContext) => SafeArea(
                          child: ChannelDirectory(
                            onSelected: () => Navigator.pop(sheetContext),
                          ),
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 8),
            // Guest or Sync Banner
            if (session == null)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: colors.brandSoft,
                  borderRadius: BorderRadius.circular(VnlfDimensions.radiusMd),
                  border: Border.all(
                    color: colors.brand.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: colors.brand,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        english
                            ? 'Guest mode · Sign in to participate with your profile'
                            : 'Chế độ Khách · Đăng nhập để nhắn tin với hồ sơ của bạn',
                        style: VnlfTypography.meta(colors.brand),
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      onPressed: () => context.push('/login'),
                      child: Text(
                        english ? 'Sign In' : 'Đăng nhập',
                        style: TextStyle(
                          color: colors.brand,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (showDirectory) ...[
                    const SizedBox(width: 190, child: ChannelDirectory()),
                    const VerticalDivider(width: 16),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Text(
                              '#${channel.id}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                english ? channel.englishTopic : channel.topic,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: VnlfTypography.meta(colors.muted),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          english
                              ? '${channel.members} members'
                              : '${channel.members} thành viên',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: ListView.separated(
                            key: PageStorageKey('messages-$selected'),
                            controller: _scroll,
                            reverse: true,
                            padding: const EdgeInsets.only(bottom: 8),
                            itemCount: messages.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final message =
                                  messages[messages.length - index - 1];
                              return VnlfChatBubble(
                                key: ValueKey(message.id),
                                message: message,
                                avatarSemanticLabel: message.author.displayName,
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (session == null && !offlineFeatures)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: colors.surface,
                              borderRadius: BorderRadius.circular(
                                VnlfDimensions.radiusMd,
                              ),
                              border: Border.all(color: colors.line),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.lock_outline_rounded,
                                  size: 18,
                                  color: colors.muted,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    english
                                        ? 'Sign in to send messages in #${channel.id}'
                                        : 'Đăng nhập để gửi tin nhắn vào #${channel.id}',
                                    style: VnlfTypography.caption(colors.muted),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                FilledButton(
                                  onPressed: () => context.push('/login'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: colors.brand,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 6,
                                    ),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  child: Text(
                                    english ? 'Sign in' : 'Đăng nhập',
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: colors.surface,
                              borderRadius: BorderRadius.circular(
                                VnlfDimensions.radiusMd,
                              ),
                              border: Border.all(color: colors.line),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: TextField(
                                    key: const Key('chat-input'),
                                    controller: _input,
                                    minLines: 1,
                                    maxLines: 4,
                                    textInputAction: TextInputAction.send,
                                    onSubmitted: (_) => _send(selected),
                                    decoration: InputDecoration(
                                      hintText: english
                                          ? 'Message #${channel.id}'
                                          : 'Gửi tin nhắn vào #${channel.id}...',
                                      border: InputBorder.none,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 10,
                                          ),
                                    ),
                                  ),
                                ),
                                ValueListenableBuilder<TextEditingValue>(
                                  valueListenable: _input,
                                  builder: (context, value, child) =>
                                      IconButton(
                                        tooltip: english
                                            ? 'Send message'
                                            : 'Gửi tin nhắn',
                                        onPressed: value.text.trim().isEmpty
                                            ? null
                                            : () => _send(selected),
                                        icon: Icon(
                                          Icons.send_rounded,
                                          color: value.text.trim().isEmpty
                                              ? colors.muted
                                              : colors.brand,
                                        ),
                                      ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
