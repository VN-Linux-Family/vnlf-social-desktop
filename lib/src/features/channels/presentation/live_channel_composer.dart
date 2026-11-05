import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/design_system.dart';
import '../domain/channel_models.dart';
import 'channel_feedback.dart';
import 'live_channel_state.dart';

class LiveChannelComposer extends ConsumerStatefulWidget {
  const LiveChannelComposer({super.key, required this.channel});
  final ChatChannel channel;
  @override
  ConsumerState<LiveChannelComposer> createState() =>
      _LiveChannelComposerState();
}

class _LiveChannelComposerState extends ConsumerState<LiveChannelComposer> {
  final _input = TextEditingController();
  @override
  void initState() {
    super.initState();
    _input.text = ref.read(channelTimelineProvider(widget.channel.id)).draft;
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(channelTimelineProvider(widget.channel.id));
    final controller = ref.read(
      channelTimelineProvider(widget.channel.id).notifier,
    );
    ref.listen(
      channelTimelineProvider(widget.channel.id).select((s) => s.draft),
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
        children: [
          if (state.reply case final reply?)
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${channelText(context, 'Đang trả lời', 'Replying to')} ${reply.author.displayName}: ${reply.content}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: VnlfTypography.caption(colors.muted),
                  ),
                ),
                IconButton(
                  tooltip: channelText(context, 'Hủy trả lời', 'Cancel reply'),
                  onPressed: state.sending
                      ? null
                      : () => controller.replyTo(null),
                  icon: const Icon(Icons.close, size: 18),
                ),
              ],
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  key: const Key('chat-input'),
                  controller: _input,
                  enabled: !state.sending,
                  minLines: 1,
                  maxLines: 4,
                  maxLength: 4000,
                  textInputAction: TextInputAction.newline,
                  onChanged: controller.updateDraft,
                  decoration: InputDecoration(
                    hintText:
                        '${channelText(context, 'Gửi tin nhắn vào', 'Message')} #${widget.channel.slug}...',
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: channelText(context, 'Gửi tin nhắn', 'Send message'),
                onPressed:
                    state.sending ||
                        state.draft.trim().isEmpty ||
                        state.busyMessageId != null
                    ? null
                    : controller.send,
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
