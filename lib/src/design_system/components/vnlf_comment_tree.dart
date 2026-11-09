import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../i18n/vi.dart';
import '../icons/vnlf_icon.dart';
import '../models/vnlf_models.dart';
import '../tokens/vnlf_colors.dart';
import '../tokens/vnlf_dimensions.dart';
import '../tokens/vnlf_typography.dart';
import 'vnlf_author_identity.dart';
import 'vnlf_avatar.dart';
import 'vnlf_profile_preview.dart';
import 'vnlf_vote_capsule.dart';
import 'vnlf_media_gallery.dart';

/// A comment and its replies, laid out like the website's comments panel:
/// rows separated by hairlines, replies indented behind a brand-soft rule.
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
    this.onLink,
  });

  final void Function(String id)? onReply;
  final void Function(String id, VoteState vote)? onVote;
  final void Function(String id)? onEdit, onDelete, onPin;
  final void Function(String username)? onAuthor;

  /// Opens a link from the text, a GIF or a sticker.
  final void Function(String url)? onLink;
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
    final rows = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CommentRow(tree: this, comment: comment, reply: depth > 0),
        for (final reply in comment.replies)
          VnlfCommentTree(
            comment: reply,
            depth: depth + 1,
            onReply: onReply,
            onVote: onVote,
            onEdit: onEdit,
            onDelete: onDelete,
            onPin: onPin,
            onAuthor: onAuthor,
            onLink: onLink,
            replyLabel: replyLabel,
            replySemanticLabel: replySemanticLabel,
            voteSemanticLabel: voteSemanticLabel,
            upvoteSemanticLabel: upvoteSemanticLabel,
            downvoteSemanticLabel: downvoteSemanticLabel,
          ),
      ],
    );
    if (semanticLabel == null) return rows;
    return Semantics(label: semanticLabel, container: true, child: rows);
  }
}

class _CommentRow extends StatelessWidget {
  const _CommentRow({
    required this.tree,
    required this.comment,
    required this.reply,
  });

  final VnlfCommentTree tree;
  final CommentNodeData comment;
  final bool reply;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final muted = VnlfTypography.body(colors.muted);
    final author = tree.onAuthor == null
        ? null
        : () => tree.onAuthor!(comment.author.username);
    final row = Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.line)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 9,
        children: [
          Semantics(
            button: author != null,
            label: format(vi.commentsPanel.xemHoSo, {
              'displayName': comment.author.displayName,
            }),
            excludeSemantics: true,
            child: VnlfProfilePreview.wrap(
              context,
              comment.author.username,
              InkWell(
                onTap: author,
                borderRadius: BorderRadius.circular(VnlfDimensions.radiusMd),
                child: VnlfAvatar(
                  author: comment.author,
                  size: reply ? 28 : 31,
                  cornerRadius: VnlfDimensions.radiusMd,
                ),
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    VnlfProfilePreview.wrap(
                      context,
                      comment.author.username,
                      InkWell(
                        onTap: author,
                        child: VnlfAuthorNameRow(
                          author: comment.author,
                          showHandleInline: false,
                        ),
                      ),
                    ),
                    Text(
                      '${comment.date.isEmpty ? comment.relativeTime : comment.date}'
                      '${comment.edited ? vi.commentsPanel.daSua : ''}',
                      style: muted,
                    ),
                    if (comment.pinned)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 3,
                        children: [
                          VnlfIcon(
                            VnlfLucide.pin,
                            size: 12,
                            color: colors.brand,
                          ),
                          Text(
                            vi.commentsPanel.daGhim,
                            style: VnlfTypography.body(colors.brand)
                                .copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                  ],
                ),
                if (comment.body.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, bottom: 8),
                    child: _CommentText(comment: comment, tree: tree),
                  )
                else
                  const SizedBox(height: 6),
                if (comment.hiddenSticker)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: colors.line),
                        borderRadius: BorderRadius.circular(
                          VnlfDimensions.radiusMd,
                        ),
                      ),
                      child: Text(
                        vi.stickers.stickerDaBiAn,
                        style: muted.copyWith(fontStyle: FontStyle.italic),
                      ),
                    ),
                  ),
                if (comment.gif != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _CommentGif(comment: comment, onLink: tree.onLink),
                  ),
                if (comment.media.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: VnlfMediaGallery(
                      items: comment.media,
                      compact: true,
                    ),
                  ),
                if (comment.inlineCode != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
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
                  ),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    VnlfVoteCapsule(
                      score: comment.voteScore,
                      voteState: comment.viewerVote,
                      compact: true,
                      semanticLabel: tree.voteSemanticLabel,
                      upvoteSemanticLabel:
                          tree.upvoteSemanticLabel ??
                          format(vi.contentVote.upvote, {
                            'label': vi.contentVote.binhLuan,
                          }),
                      downvoteSemanticLabel:
                          tree.downvoteSemanticLabel ??
                          format(vi.contentVote.downvote, {
                            'label': vi.contentVote.binhLuan,
                          }),
                      onVoteChanged: comment.pending || tree.onVote == null
                          ? null
                          : (value) => tree.onVote!(comment.id, value),
                    ),
                    if (tree.replyLabel.isNotEmpty)
                      _CommentAction(
                        label: tree.replyLabel,
                        semanticLabel: tree.replySemanticLabel,
                        onPressed: tree.onReply == null
                            ? null
                            : () => tree.onReply!(comment.id),
                      ),
                    if (comment.canEdit && tree.onEdit != null)
                      _CommentAction(
                        label: vi.common.sua,
                        onPressed: comment.pending
                            ? null
                            : () => tree.onEdit!(comment.id),
                      ),
                    if (comment.canDelete && tree.onDelete != null)
                      _CommentAction(
                        label: vi.common.xoa,
                        onPressed: comment.pending
                            ? null
                            : () => tree.onDelete!(comment.id),
                      ),
                    if (comment.canPin && tree.onPin != null)
                      _CommentAction(
                        label: comment.pinned
                            ? vi.commentsPanel.boGhim
                            : vi.commentsPanel.ghim,
                        onPressed: comment.pending
                            ? null
                            : () => tree.onPin!(comment.id),
                      ),
                  ],
                ),
                if (comment.actionError != null)
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      comment.actionError!,
                      style: VnlfTypography.body(colors.red),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
    if (!reply) return row;
    return Container(
      margin: const EdgeInsets.only(left: 38),
      padding: const EdgeInsets.only(left: 12),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: colors.brandSoft, width: 2)),
      ),
      child: row,
    );
  }
}

/// The comment text: server-known @mentions in bold and links that open.
class _CommentText extends StatefulWidget {
  const _CommentText({required this.comment, required this.tree});

  final CommentNodeData comment;
  final VnlfCommentTree tree;

  @override
  State<_CommentText> createState() => _CommentTextState();
}

class _CommentTextState extends State<_CommentText> {
  static final _token = RegExp(
    '@([A-Za-z0-9_.]+)|\\b(?:https?://|www\\.)[^\\s<>"\']+',
  );
  final _recognizers = <TapGestureRecognizer>[];

  void _clear() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  @override
  void dispose() {
    _clear();
    super.dispose();
  }

  TapGestureRecognizer? _tap(VoidCallback? onTap) {
    if (onTap == null) return null;
    final recognizer = TapGestureRecognizer()..onTap = onTap;
    _recognizers.add(recognizer);
    return recognizer;
  }

  @override
  Widget build(BuildContext context) {
    _clear();
    final colors = VnlfColors.of(context);
    final body = widget.comment.body;
    final mentions = {
      for (final mention in widget.comment.mentions) mention.toLowerCase(),
    };
    final spans = <InlineSpan>[];
    var last = 0;
    for (final match in _token.allMatches(body)) {
      final username = match[1];
      if (username != null && !mentions.contains(username.toLowerCase())) {
        continue;
      }
      if (match.start > last) {
        spans.add(TextSpan(text: body.substring(last, match.start)));
      }
      final onAuthor = widget.tree.onAuthor;
      final onLink = widget.tree.onLink;
      if (username != null) {
        spans.add(
          TextSpan(
            text: match[0],
            style: const TextStyle(fontWeight: FontWeight.w700),
            recognizer: _tap(
              onAuthor == null ? null : () => onAuthor(username),
            ),
          ),
        );
      } else {
        final raw = match[0]!;
        final url = raw.replaceFirst(RegExp(r'[.,!?;:]+$'), '');
        final target = url.toLowerCase().startsWith('www.')
            ? 'https://$url'
            : url;
        spans.add(
          TextSpan(
            text: url,
            style: TextStyle(
              color: colors.brand,
              decoration: TextDecoration.underline,
            ),
            recognizer: _tap(onLink == null ? null : () => onLink(target)),
          ),
        );
        if (url.length < raw.length) {
          spans.add(TextSpan(text: raw.substring(url.length)));
        }
      }
      last = match.end;
    }
    if (last < body.length) spans.add(TextSpan(text: body.substring(last)));
    return SelectableText.rich(
      TextSpan(children: spans),
      style: VnlfTypography.body(colors.ink).copyWith(height: 1.6),
    );
  }
}

/// A GIF names its provider; a sticker has no frame and is smaller.
class _CommentGif extends StatelessWidget {
  const _CommentGif({required this.comment, required this.onLink});

  final CommentNodeData comment;
  final void Function(String url)? onLink;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final gif = comment.gif!;
    final sticker = comment.gifSticker;
    final image = ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: sticker ? 160 : 320,
        maxHeight: sticker ? 160 : 300,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          sticker ? 0 : VnlfDimensions.radiusMd,
        ),
        child: Image.network(
          gif.url,
          fit: BoxFit.contain,
          semanticLabel: gif.alt,
          errorBuilder: (_, _, _) => Text(
            vi.app.designSystem.anhKhongConTrong,
            style: VnlfTypography.body(colors.muted),
          ),
        ),
      ),
    );
    final provider = comment.gifProvider;
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: [
        image,
        if (provider != null && provider.isNotEmpty && provider != 'VNLF')
          Opacity(
            opacity: sticker ? .6 : 1,
            child: Text(
              provider,
              style: VnlfTypography.body(colors.muted)
                  .copyWith(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
    final link = comment.gifLink;
    final open = onLink;
    if (link == null || open == null) return content;
    return InkWell(
      onTap: () => open(link),
      borderRadius: BorderRadius.circular(VnlfDimensions.radiusMd),
      child: content,
    );
  }
}

/// A text action under a comment: Trả lời, Sửa, Xóa, Ghim.
class _CommentAction extends StatefulWidget {
  const _CommentAction({
    required this.label,
    required this.onPressed,
    this.semanticLabel,
  });

  final String label;
  final String? semanticLabel;
  final VoidCallback? onPressed;

  @override
  State<_CommentAction> createState() => _CommentActionState();
}

class _CommentActionState extends State<_CommentAction> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final color = widget.onPressed == null
        ? colors.muted.withValues(alpha: .5)
        : _hovered
        ? colors.brand
        : colors.muted;
    return Semantics(
      button: true,
      label: widget.semanticLabel ?? widget.label,
      excludeSemantics: true,
      child: InkWell(
        onTap: widget.onPressed,
        onHover: (value) => setState(() => _hovered = value),
        borderRadius: BorderRadius.circular(VnlfDimensions.radiusSm),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 36),
          child: Padding(
            padding: const EdgeInsets.only(right: 9),
            child: Align(
              widthFactor: 1,
              child: Text(
                widget.label,
                style: VnlfTypography.body(color)
                    .copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ),
    );
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
