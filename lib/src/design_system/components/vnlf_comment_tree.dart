import 'package:flutter/material.dart';

import '../../i18n/vi.dart';
import '../models/vnlf_models.dart';
import '../tokens/vnlf_colors.dart';
import '../tokens/vnlf_dimensions.dart';
import '../tokens/vnlf_typography.dart';
import 'vnlf_author_identity.dart';
import 'vnlf_avatar.dart';
import 'vnlf_vote_capsule.dart';
import 'vnlf_media_gallery.dart';

/// Hierarchical comment node with nested replies and vertical thread guide lines.
class VnlfCommentTree extends StatelessWidget {
  const VnlfCommentTree({
    super.key,
    required this.comment,
    this.depth = 0,
    this.replyLabel = '',
    this.semanticLabel,
    this.replySemanticLabel,
    this.voteSemanticLabel,
    this.upvoteSemanticLabel,
    this.downvoteSemanticLabel,
    this.onReply,
    this.onVote,
    this.onEdit,
    this.onDelete,
    this.onPin,
    this.onAuthor,
  });

  final void Function(String id)? onReply;
  final void Function(String id, VoteState vote)? onVote;
  final void Function(String id)? onEdit, onDelete, onPin;
  final void Function(String username)? onAuthor;
  final CommentNodeData comment;
  final int depth;
  final String replyLabel;
  final String? semanticLabel;
  final String? replySemanticLabel;
  final String? voteSemanticLabel;
  final String? upvoteSemanticLabel;
  final String? downvoteSemanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);

    final tree = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: onAuthor == null
                  ? null
                  : () => onAuthor!(comment.author.username),
              child: VnlfAvatar(
                author: comment.author,
                size: depth == 0 ? 34 : 28,
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
                        child: InkWell(
                          onTap: onAuthor == null
                              ? null
                              : () => onAuthor!(comment.author.username),
                          child: VnlfAuthorNameRow(
                            author: comment.author,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Text(
                        '${comment.relativeTime}${comment.edited ? vi.commentsPanel.daSua : ''}',
                        style: VnlfTypography.meta(colors.textSubtle),
                      ),
                    ],
                  ),
                  if (comment.pinned)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        vi.commentsPanel.daGhim,
                        style: VnlfTypography.meta(colors.brand),
                      ),
                    ),
                  const SizedBox(height: 5),
                  if (comment.body.isNotEmpty)
                    SelectableText(
                      comment.body,
                      style: VnlfTypography.body(colors.ink),
                    ),
                  if (comment.hiddenSticker)
                    Text(
                      vi.stickers.stickerDaBiAn,
                      style: VnlfTypography.meta(colors.muted),
                    ),
                  if (comment.gif != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 280),
                          child: VnlfMediaGallery(items: [comment.gif!]),
                        ),
                      ),
                    ),
                  if (comment.media.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: VnlfMediaGallery(items: comment.media),
                    ),
                  if (comment.inlineCode != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: colors.codeBlockBg,
                        borderRadius: BorderRadius.circular(
                          VnlfDimensions.radiusSm,
                        ),
                      ),
                      child: Text(
                        comment.inlineCode!,
                        style: VnlfTypography.code(colors.codeBlockText),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      VnlfVoteCapsule(
                        score: comment.voteScore,
                        voteState: comment.viewerVote,
                        compact: true,
                        semanticLabel: voteSemanticLabel,
                        upvoteSemanticLabel:
                            upvoteSemanticLabel ?? vi.app.common.ungHo,
                        downvoteSemanticLabel:
                            downvoteSemanticLabel ?? vi.app.common.phanDoi,
                        onVoteChanged: comment.pending || onVote == null
                            ? null
                            : (value) => onVote!(comment.id, value),
                      ),
                      if (replyLabel.isNotEmpty) ...[
                        Semantics(
                          button: true,
                          label: replySemanticLabel ?? replyLabel,
                          child: InkWell(
                            onTap: onReply == null
                                ? null
                                : () => onReply!(comment.id),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.reply_rounded,
                                  size: 14,
                                  color: colors.muted,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  replyLabel,
                                  style: VnlfTypography.meta(
                                    colors.muted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      if (comment.canEdit && onEdit != null)
                        TextButton(
                          onPressed: comment.pending
                              ? null
                              : () => onEdit!(comment.id),
                          child: Text(vi.common.sua),
                        ),
                      if (comment.canDelete && onDelete != null)
                        TextButton(
                          onPressed: comment.pending
                              ? null
                              : () => onDelete!(comment.id),
                          child: Text(vi.common.xoa),
                        ),
                      if (comment.canPin && onPin != null)
                        TextButton(
                          onPressed: comment.pending
                              ? null
                              : () => onPin!(comment.id),
                          child: Text(
                            comment.pinned
                                ? vi.commentsPanel.boGhim
                                : vi.commentsPanel.ghim,
                          ),
                        ),
                    ],
                  ),
                  if (comment.actionError != null)
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        comment.actionError!,
                        style: VnlfTypography.meta(colors.red),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        if (comment.replies.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(left: depth < 3 ? 16 : 0, top: 12),
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: colors.line, width: 1.5),
                ),
              ),
              padding: EdgeInsets.only(left: depth < 3 ? 14 : 4),
              child: Column(
                children: [
                  for (var i = 0; i < comment.replies.length; i++) ...[
                    if (i > 0) const SizedBox(height: 12),
                    VnlfCommentTree(
                      comment: comment.replies[i],
                      depth: depth + 1,
                      onReply: onReply,
                      onVote: onVote,
                      onEdit: onEdit,
                      onDelete: onDelete,
                      onPin: onPin,
                      onAuthor: onAuthor,
                      replyLabel: replyLabel,
                      replySemanticLabel: replySemanticLabel,
                      voteSemanticLabel: voteSemanticLabel,
                      upvoteSemanticLabel: upvoteSemanticLabel,
                      downvoteSemanticLabel: downvoteSemanticLabel,
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );

    if (semanticLabel == null) {
      return tree;
    }
    return Semantics(label: semanticLabel, container: true, child: tree);
  }
}

/// Direct Message & Channel Chat bubble with author identity, timestamp,
/// reaction pills, and optional sticker (`DESIGN_REFERENCE.md` Section 6.4).
class VnlfChatBubble extends StatelessWidget {
  const VnlfChatBubble({
    super.key,
    required this.message,
    this.semanticLabel,
    this.avatarSemanticLabel,
    this.stickerSemanticLabel,
  });

  final ChatMessageData message;
  final String? semanticLabel;
  final String? avatarSemanticLabel;
  final String? stickerSemanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);

    final bubble = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(VnlfDimensions.radiusLg),
        border: Border.all(color: colors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VnlfAvatar(
            author: message.author,
            size: 36,
            semanticLabel: avatarSemanticLabel,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: VnlfAuthorNameRow(
                        author: message.author,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      message.timestamp,
                      style: VnlfTypography.meta(colors.textSubtle),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(message.text, style: VnlfTypography.body(colors.ink)),
                if (message.stickerLabel != null) ...[
                  const SizedBox(height: 8),
                  Semantics(
                    label: stickerSemanticLabel ?? message.stickerLabel,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: colors.brandSoft,
                        borderRadius: BorderRadius.circular(
                          VnlfDimensions.radiusMd,
                        ),
                        border: Border.all(
                          color: colors.brand.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.terminal_rounded,
                            size: 18,
                            color: colors.brand,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            message.stickerLabel!,
                            style: VnlfTypography.meta(
                              colors.brand,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (message.reactions.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      for (final entry in message.reactions.entries)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: colors.surfaceSoft,
                            borderRadius: BorderRadius.circular(
                              VnlfDimensions.radiusFull,
                            ),
                            border: Border.all(color: colors.line),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (entry.key == '👍' || entry.key == '❤️')
                                Icon(
                                  entry.key == '👍'
                                      ? Icons.thumb_up_alt_outlined
                                      : Icons.favorite_outline,
                                  size: 13,
                                  color: colors.muted,
                                  semanticLabel: entry.key,
                                )
                              else
                                Text(
                                  entry.key,
                                  style: VnlfTypography.caption(colors.ink),
                                ),
                              const SizedBox(width: 4),
                              Text(
                                '${entry.value}',
                                style: VnlfTypography.caption(colors.ink),
                              ),
                            ],
                          ),
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

    if (semanticLabel == null) {
      return bubble;
    }
    return Semantics(label: semanticLabel, container: true, child: bubble);
  }
}
