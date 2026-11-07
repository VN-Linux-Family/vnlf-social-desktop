import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../design_system/design_system.dart';
import '../../../design_system/components/vnlf_rich_content.dart';
import '../../../design_system/components/vnlf_media_gallery.dart';
import '../../../domain/models.dart';

/// The website's long-article view has its own header and reading layout.
class ArticleDetailCard extends StatelessWidget {
  const ArticleDetailCard({
    super.key,
    required this.source,
    required this.post,
    this.onAuthor,
    this.onComment,
    this.onShare,
    this.onBookmark,
    this.onVote,
    this.onReport,
    this.onEdit,
    this.poll,
  });
  final FeedPost source;
  final Widget? poll;
  final PostData post;
  final VoidCallback? onAuthor;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final VoidCallback? onBookmark;
  final VoidCallback? onReport;
  final VoidCallback? onEdit;
  final ValueChanged<VoteState>? onVote;
  @override
  Widget build(BuildContext context) {
    final en = Localizations.localeOf(context).languageCode == 'en';
    final compact = MediaQuery.sizeOf(context).width <= 840;
    final colors = VnlfColors.of(context);
    final body = VnlfTypography.body(colors.ink)
        .copyWith(height: 1.7, letterSpacing: 0);
    final minutes = math.max(
      2,
      (source.contentText.split(RegExp(r'\s+')).length / 220).ceil(),
    );
    final title =
        source.title ??
        source.contentText.substring(
          0,
          math.min(88, source.contentText.length),
        );
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 780),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surface,
            border: compact ? null : Border.all(color: colors.line),
            borderRadius: BorderRadius.circular(compact ? 0 : 14),
          ),
          child: Padding(
            padding: compact
                ? const EdgeInsets.fromLTRB(16, 4, 16, 4)
                : const EdgeInsets.fromLTRB(39, 29, 39, 21),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colors.brandSoft,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Article',
                        style: body.copyWith(
                          color: colors.brand,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      en ? '$minutes min read' : '$minutes phút đọc',
                      style: body.copyWith(color: colors.muted),
                    ),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.only(
                    top: compact ? 12 : 19,
                    bottom: compact ? 7 : 10,
                  ),
                  child: Text(
                    title,
                    style: body.copyWith(
                      height: 1.08,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -.65,
                    ),
                  ),
                ),
                Text(
                  source.excerpt,
                  style: body.copyWith(height: 1.65, color: colors.muted),
                ),
                SizedBox(height: compact ? 14 : 24),
                Row(
                  children: [
                    InkWell(
                      onTap: onAuthor,
                      child: VnlfAvatar(author: post.author, size: 40),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: InkWell(
                        onTap: onAuthor,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            VnlfAuthorNameRow(
                              author: post.author,
                              showHandleInline: false,
                              fontSize: 13,
                            ),
                            Text(
                              '@${source.author.username}',
                              style: body.copyWith(color: colors.muted),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (onEdit != null || onShare != null || onReport != null)
                      PopupMenuButton<String>(
                        tooltip: en ? 'Post menu' : 'Menu bài viết',
                        icon: const Icon(Icons.more_horiz, size: 18),
                        onSelected: (value) {
                          if (value == 'edit') onEdit?.call();
                          if (value == 'share') onShare?.call();
                          if (value == 'report') onReport?.call();
                        },
                        itemBuilder: (_) => [
                          if (onEdit != null)
                            PopupMenuItem(
                              value: 'edit',
                              child: Text(en ? 'Edit article' : 'Sửa bài viết'),
                            ),
                          if (onShare != null)
                            PopupMenuItem(
                              value: 'share',
                              child: Text(en ? 'Share' : 'Chia sẻ'),
                            ),
                          if (onReport != null)
                            PopupMenuItem(
                              value: 'report',
                              child: Text(en ? 'Report' : 'Báo cáo'),
                            ),
                        ],
                      ),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: compact ? 14 : 24),
                  child: Divider(height: 1, color: colors.line),
                ),
                if (source.contentJson != null)
                  VnlfRichContent(
                    document: source.contentJson!,
                    showImages: true,
                    selectable: true,
                    articleDetail: true,
                  )
                else
                  SelectableText(source.contentText, style: body),
                if (post.attachment case final MediaGalleryAttachment gallery)
                  VnlfMediaGallery(items: gallery.items),
                ?poll,
                const SizedBox(height: 4),
                Divider(height: 1, color: colors.line),
                const SizedBox(height: 8),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final actions = <Widget>[
                      VnlfVoteCapsule(
                        score: post.voteScore,
                        voteState: post.viewerVote,
                        onVoteChanged: post.actionPending ? null : onVote,
                        upvoteSemanticLabel: en ? 'Upvote' : 'Ủng hộ',
                        downvoteSemanticLabel: en ? 'Downvote' : 'Phản đối',
                      ),
                      TextButton.icon(
                        onPressed: onComment,
                        icon: const Icon(Icons.chat_bubble_outline, size: 17),
                        label: Text('${post.commentCount}'),
                      ),
                      TextButton.icon(
                        onPressed: onShare,
                        icon: const Icon(Icons.link, size: 16),
                        label: Text(en ? 'Share' : 'Chia sẻ'),
                      ),
                      Semantics(
                        toggled: post.isBookmarked,
                        child: TextButton.icon(
                          onPressed: post.actionPending ? null : onBookmark,
                          icon: Icon(
                            post.isBookmarked
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                            size: 17,
                          ),
                          label: Text(
                            post.isBookmarked
                                ? (en ? 'Saved' : 'Đã lưu')
                                : (en ? 'Save' : 'Lưu'),
                          ),
                        ),
                      ),
                      if (onReport != null)
                        TextButton.icon(
                          onPressed: onReport,
                          icon: const Icon(Icons.flag_outlined, size: 16),
                          label: Text(en ? 'Report' : 'Báo cáo'),
                        ),
                    ];
                    return constraints.maxWidth < 560
                        ? Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: actions,
                          )
                        : Row(
                            children: [
                              for (var i = 0; i < actions.length; i++) ...[
                                if (i == 4) const Spacer(),
                                actions[i],
                              ],
                            ],
                          );
                  },
                ),
                if (post.actionError != null)
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      post.actionError!,
                      style: body.copyWith(color: colors.red),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
