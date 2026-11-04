import 'package:flutter/material.dart';

import '../models/vnlf_models.dart';
import '../tokens/vnlf_colors.dart';
import '../tokens/vnlf_dimensions.dart';
import '../tokens/vnlf_typography.dart';
import 'vnlf_author_identity.dart';
import 'vnlf_avatar.dart';
import 'vnlf_vote_capsule.dart';

/// Hierarchical comment node with nested replies and vertical thread guide lines.
class VnlfCommentTree extends StatelessWidget {
  const VnlfCommentTree({super.key, required this.comment, this.depth = 0});

  final CommentNodeData comment;
  final int depth;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            VnlfAvatar(author: comment.author, size: depth == 0 ? 34 : 28),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: VnlfAuthorNameRow(
                          author: comment.author,
                          fontSize: 12.5,
                        ),
                      ),
                      Text(
                        comment.relativeTime,
                        style: VnlfTypography.meta(colors.textSubtle),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(comment.body, style: VnlfTypography.body(colors.ink)),
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
                        style: VnlfTypography.code(colors.codeBlockText)
                            .copyWith(fontSize: 11.5),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      VnlfVoteCapsule(
                        score: comment.voteScore,
                        voteState: comment.viewerVote,
                        compact: true,
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.reply_rounded, size: 14, color: colors.muted),
                      const SizedBox(width: 4),
                      Text(
                        'Trả lời',
                        style: VnlfTypography.meta(
                          colors.muted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        if (comment.replies.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 12),
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: colors.line, width: 1.5),
                ),
              ),
              padding: const EdgeInsets.only(left: 14),
              child: Column(
                children: [
                  for (var i = 0; i < comment.replies.length; i++) ...[
                    if (i > 0) const SizedBox(height: 12),
                    VnlfCommentTree(
                      comment: comment.replies[i],
                      depth: depth + 1,
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Direct Message & Channel Chat bubble with author identity, timestamp,
/// reaction pills, and optional sticker (`DESIGN_REFERENCE.md` Section 6.4).
class VnlfChatBubble extends StatelessWidget {
  const VnlfChatBubble({super.key, required this.message});

  final ChatMessageData message;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(VnlfDimensions.radiusLg),
        border: Border.all(color: colors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VnlfAvatar(author: message.author, size: 36),
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
                  Container(
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
                          child: Text(
                            '${entry.key} ${entry.value}',
                            style: VnlfTypography.caption(colors.ink),
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
  }
}
