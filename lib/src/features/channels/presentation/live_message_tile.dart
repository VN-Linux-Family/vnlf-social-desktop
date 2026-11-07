import '../../polls/presentation/poll_card.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'channel_media.dart';
import '../../../design_system/design_system.dart';
import '../domain/channel_models.dart';
import '../../shared/presentation/author_mapper.dart';
import 'channel_feedback.dart';

class LiveMessageTile extends StatelessWidget {
  const LiveMessageTile({
    super.key,
    required this.message,
    required this.own,
    required this.canAct,
    required this.busy,
    required this.onReply,
    required this.onEdit,
    required this.onDelete,
    required this.onReact,
  });
  final ChannelMessage message;
  final bool own;
  final bool canAct;
  final bool busy;
  final VoidCallback onReply;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<String> onReact;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final author = presentAuthor(message.author);
    final deleted = message.deletedAt != null;
    final date = message.createdAt?.toLocal();
    final time = date == null
        ? ''
        : '${date.day}/${date.month} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    final media = message.attachments
        .where(
          (a) =>
              (a.url.isNotEmpty || a.downloadPath.isNotEmpty) &&
              (a.mime.startsWith('image/') || a.mime.startsWith('video/')),
        )
        .toList();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(VnlfDimensions.radiusLg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: null,
            child: VnlfAvatar(
              author: author,
              size: 36,
              semanticLabel: author.displayName,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: VnlfAuthorNameRow(author: author, fontSize: 13),
                    ),
                    Text(time, style: VnlfTypography.meta(colors.muted)),
                    if (!deleted)
                      PopupMenuButton<String>(
                        tooltip: channelText(
                          context,
                          'Thao tác tin nhắn',
                          'Message actions',
                        ),
                        enabled: !busy,
                        padding: EdgeInsets.zero,
                        iconSize: 18,
                        onSelected: (value) {
                          switch (value) {
                            case 'copy':
                              Clipboard.setData(
                                ClipboardData(text: message.content),
                              );
                            case 'edit':
                              onEdit();
                            case 'delete':
                              onDelete();
                          }
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: 'copy',
                            child: Text(
                              channelText(context, 'Sao chép', 'Copy'),
                            ),
                          ),
                          if (own && canAct) ...[
                            PopupMenuItem(
                              value: 'edit',
                              child: Text(
                                channelText(context, 'Chỉnh sửa', 'Edit'),
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text(
                                channelText(context, 'Xóa', 'Delete'),
                              ),
                            ),
                          ],
                        ],
                      ),
                  ],
                ),
                if (message.replyTo case final reply? when !deleted)
                  Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colors.surfaceSoft,
                      border: Border(
                        left: BorderSide(color: colors.brand, width: 2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reply.name,
                          style: VnlfTypography.meta(colors.brand),
                        ),
                        Text(
                          reply.deleted
                              ? channelText(
                                  context,
                                  'Tin nhắn đã bị xóa',
                                  'Message deleted',
                                )
                              : reply.content,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: VnlfTypography.caption(colors.muted),
                        ),
                      ],
                    ),
                  ),
                SelectableText(
                  deleted
                      ? channelText(
                          context,
                          'Tin nhắn đã bị xóa',
                          'Message deleted',
                        )
                      : message.content,
                  style: VnlfTypography.body(
                    deleted ? colors.muted : colors.ink,
                  ),
                ),
                if (!deleted) ...[
                  if (message.editedAt != null)
                    Text(
                      channelText(context, 'Đã chỉnh sửa', 'Edited'),
                      style: VnlfTypography.meta(colors.muted),
                    ),
                  if (media.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: ChannelMedia(items: media),
                    ),
                  for (final attachment in message.attachments.where(
                    (a) => !media.contains(a),
                  ))
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        attachment.state == 'PROCESSING'
                            ? channelText(
                                context,
                                'Tệp đang được xử lý',
                                'Attachment processing',
                              )
                            : attachment.state == 'FAILED'
                            ? channelText(
                                context,
                                'Không xử lý được tệp',
                                'Attachment processing failed',
                              )
                            : '${channelText(context, 'Tệp đính kèm', 'Attachment')} · ${attachment.mime}',
                        style: VnlfTypography.caption(colors.muted),
                      ),
                    ),
                  if (message.hasGif)
                    Text(
                      channelText(
                        context,
                        'Tin nhắn có GIF / nhãn dán',
                        'Message contains a GIF / sticker',
                      ),
                      style: VnlfTypography.caption(colors.muted),
                    ),
                  if (!deleted && message.poll != null)
                    PollCard(
                      poll: message.poll!,
                      authorId: message.author.id,
                      disabled: busy,
                      maxWidth: 340,
                    ),
                  Wrap(
                    spacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      for (final reaction in message.reactions)
                        FilterChip(
                          selected: reaction.viewerReacted,
                          label: Text('${reaction.emoji} ${reaction.count}'),
                          onSelected: canAct && !busy
                              ? (_) => onReact(reaction.emoji)
                              : null,
                          showCheckmark: false,
                        ),
                      if (canAct) ...[
                        IconButton(
                          tooltip: channelText(context, 'Trả lời', 'Reply'),
                          onPressed: busy ? null : onReply,
                          icon: const Icon(Icons.reply_outlined, size: 18),
                        ),
                        PopupMenuButton<String>(
                          tooltip: channelText(
                            context,
                            'Thêm cảm xúc',
                            'Add reaction',
                          ),
                          enabled: !busy,
                          icon: const Icon(
                            Icons.add_reaction_outlined,
                            size: 18,
                          ),
                          onSelected: onReact,
                          itemBuilder: (_) => [
                            for (final emoji in [
                              '👍',
                              '❤️',
                              '😄',
                              '🎉',
                              '🤔',
                              '👀',
                            ])
                              PopupMenuItem(value: emoji, child: Text(emoji)),
                          ],
                        ),
                      ],
                      if (busy)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
