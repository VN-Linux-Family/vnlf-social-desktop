import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/design_system.dart';
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
    ref.read(channelMessagesProvider.notifier).send(channel, _input.text);
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
                        builder: (sheetContext) => SafeArea(
                          child: ChannelDirectory(
                            onSelected: () => Navigator.pop(sheetContext),
                          ),
                        ),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                english
                    ? 'Local chat · Messages stay in this session.'
                    : 'Trò chuyện cục bộ · Tin nhắn chỉ lưu trong phiên này.',
                style: Theme.of(context).textTheme.bodySmall,
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
                        Text(
                          '#${channel.id}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(english ? channel.englishTopic : channel.topic),
                        Text(
                          english
                              ? '${channel.members} members'
                              : '${channel.members} thành viên',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: ListView.separated(
                            key: PageStorageKey('messages-$selected'),
                            controller: _scroll,
                            reverse: true,
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
                        Row(
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
                                  labelText: english
                                      ? 'Message #$selected'
                                      : 'Nhắn tin #$selected',
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                            ),
                            ValueListenableBuilder<TextEditingValue>(
                              valueListenable: _input,
                              builder: (context, value, child) => IconButton(
                                tooltip: english
                                    ? 'Send message'
                                    : 'Gửi tin nhắn',
                                onPressed: value.text.trim().isEmpty
                                    ? null
                                    : () => _send(selected),
                                icon: const Icon(Icons.send_rounded),
                              ),
                            ),
                          ],
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
