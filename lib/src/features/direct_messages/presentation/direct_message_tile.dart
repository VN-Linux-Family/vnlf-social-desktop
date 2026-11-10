import '../../../i18n/vi.dart';
import '../../polls/presentation/poll_card.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../design_system/design_system.dart';
import '../../shared/presentation/author_mapper.dart';
import '../domain/direct_message_models.dart';
import 'direct_message_feedback.dart';
import 'direct_message_media.dart';

class DirectMessageTile extends StatelessWidget {
  const DirectMessageTile({
    super.key,
    required this.message,
    required this.own,
    required this.canAct,
    required this.busy,
    required this.onReply,
    required this.onEdit,
    required this.onDelete,
    required this.onReact,
    this.isFirstUnread = false,
    this.isHighlighted = false,
    this.isPeerReadBarrier = false,
    this.onTapReply,
  });

  final DmMessage message;
  final bool own;
  final bool canAct;
  final bool busy;
  final bool isFirstUnread;
  final bool isHighlighted;
  final bool isPeerReadBarrier;
  final VoidCallback onReply;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<String> onReact;
  final ValueChanged<String>? onTapReply;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final author = presentAuthor(message.author);
    final deleted = message.isDeleted;
    final canEdit = own && canAct && message.canEditAt(DateTime.now());
    final time = formatDmTimestamp(message.createdAt);
    final media = message.attachments
        .where(
          (attachment) =>
              (attachment.url.isNotEmpty ||
                  attachment.downloadPath.isNotEmpty) &&
              (attachment.mime.isEmpty ||
                  attachment.mime.startsWith('image/') ||
                  attachment.mime.startsWith('video/')),
        )
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (isFirstUnread)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: <Widget>[
                Expanded(child: Divider(color: colors.brand, thickness: 1)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    vi.app.directMessages.tinNhanChuaDoc,
                    style: VnlfTypography.meta(colors.brand),
                  ),
                ),
                Expanded(child: Divider(color: colors.brand, thickness: 1)),
              ],
            ),
          ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isHighlighted ? colors.brandSoft : colors.surface,
            border: Border.all(
              color: isHighlighted ? colors.brand : colors.line,
              width: isHighlighted ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(VnlfDimensions.radiusLg),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              VnlfAvatar(
                author: author,
                size: 36,
                semanticLabel: author.displayName,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: VnlfAuthorNameRow(
                            author: author,
                            fontSize: 13,
                          ),
                        ),
                        if (time.isNotEmpty)
                          Text(time, style: VnlfTypography.meta(colors.muted)),
                        if (!deleted)
                          PopupMenuButton<String>(
                            tooltip: vi.app.common.thaoTacTinNhan,
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
                            itemBuilder: (_) => <PopupMenuEntry<String>>[
                              PopupMenuItem<String>(
                                value: 'copy',
                                child: Text(vi.chatUi.saoChep),
                              ),
                              if (canEdit)
                                PopupMenuItem<String>(
                                  value: 'edit',
                                  child: Text(vi.app.common.chinhSua),
                                ),
                              if (own && canAct)
                                PopupMenuItem<String>(
                                  value: 'delete',
                                  child: Text(vi.common.xoa),
                                ),
                            ],
                          ),
                      ],
                    ),
                    if (message.replyTo case final reply? when !deleted)
                      InkWell(
                        onTap: onTapReply == null
                            ? null
                            : () => onTapReply!(reply.id),
                        borderRadius: BorderRadius.circular(
                          VnlfDimensions.radiusSm,
                        ),
                        child: Container(
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
                            children: <Widget>[
                              Text(
                                reply.name.isEmpty
                                    ? '@${reply.username}'
                                    : reply.name,
                                style: VnlfTypography.meta(colors.brand),
                              ),
                              Text(
                                reply.deleted
                                    ? vi.common.tinNhanDaDuocXoa
                                    : reply.content.isNotEmpty
                                    ? reply.content
                                    : reply.hasGif
                                    ? vi.app.directMessages.gifNhanDan
                                    : vi.app.directMessages.anhDinhKem,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: VnlfTypography.caption(colors.muted),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (deleted || message.content.isNotEmpty)
                      SelectableText(
                        deleted ? vi.common.tinNhanDaDuocXoa : message.content,
                        style: VnlfTypography.body(
                          deleted ? colors.muted : colors.ink,
                        ),
                      ),
                    if (!deleted) ...<Widget>[
                      if (message.editedAt != null)
                        Text(
                          vi.chatUi.daChinhSua,
                          style: VnlfTypography.meta(colors.muted),
                        ),
                      if (media.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: DirectMessageMedia(items: media),
                        ),
                      for (final attachment in message.attachments.where(
                        (item) => !media.contains(item),
                      ))
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            attachment.state == 'PROCESSING'
                                ? vi.app.directMessages.tepDinhKemDang
                                : attachment.state == 'FAILED'
                                ? vi.app.directMessages.khongXuLyDuoc
                                : format(vi.app.common.tepDinhKemLoai, {
                                    'mime': attachment.mime,
                                  }),
                            style: VnlfTypography.caption(colors.muted),
                          ),
                        ),
                      if (message.gif case final gif?)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            gif.hidden
                                ? vi.app.directMessages.nhanDanTuBo
                                : gif.isSticker
                                ? vi.app.directMessages.tinNhanCoNhan
                                : vi.app.directMessages.tinNhanCoGif,
                            style: VnlfTypography.caption(colors.muted),
                          ),
                        ),
                      if (message.poll case final poll?)
                        PollCard(
                          poll: poll,
                          authorId: message.authorId,
                          disabled: busy,
                          maxWidth: 340,
                        ),
                      Wrap(
                        spacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: <Widget>[
                          for (final reaction in message.reactions)
                            FilterChip(
                              selected: reaction.viewerReacted,
                              label: Text(
                                '${reaction.emoji} ${reaction.count}',
                              ),
                              onSelected: canAct && !busy
                                  ? (_) => onReact(reaction.emoji)
                                  : null,
                              showCheckmark: false,
                            ),
                          if (canAct) ...<Widget>[
                            IconButton(
                              tooltip: vi.chatUi.traLoi,
                              onPressed: busy ? null : onReply,
                              icon: const Icon(Icons.reply_outlined, size: 18),
                            ),
                            PopupMenuButton<String>(
                              tooltip: vi.chatUi.bayToCamXuc,
                              enabled: !busy,
                              icon: const Icon(
                                Icons.add_reaction_outlined,
                                size: 18,
                              ),
                              onSelected: onReact,
                              itemBuilder: (_) => <PopupMenuEntry<String>>[
                                for (final emoji in defaultDmQuickReactions)
                                  PopupMenuItem<String>(
                                    value: emoji,
                                    child: Text(emoji),
                                  ),
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
                    if (isPeerReadBarrier)
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            vi.chatUi.daXem,
                            style: VnlfTypography.meta(colors.muted),
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
    );
  }
}
