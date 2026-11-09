import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show OverflowBoxFit;
import 'package:intl/intl.dart';

import '../../core/vnlf_navigation_helper.dart';
import '../../i18n/vi.dart';
import '../models/vnlf_models.dart';
import '../tokens/vnlf_colors.dart';
import '../tokens/vnlf_dimensions.dart';
import '../tokens/vnlf_typography.dart';
import 'vnlf_author_identity.dart';
import 'vnlf_avatar.dart';
import 'vnlf_post_attachment.dart';
import 'vnlf_profile_preview.dart';
import 'vnlf_rich_content.dart';
import 'vnlf_skeleton.dart';
import 'vnlf_state_cards.dart';
import 'vnlf_vote_capsule.dart';
import '../icons/vnlf_icon.dart';

export 'vnlf_skeleton.dart'
    show
        VnlfFeedPostSkeleton,
        VnlfFeedPostsSkeleton,
        VnlfFeedSkeletonList,
        VnlfPostCardSkeleton,
        VnlfSkeletonShimmerScope;
export 'vnlf_state_cards.dart' show VnlfFeedEmptyState, VnlfFeedErrorState;

/// Composer prompt card at the top of the feed.
class VnlfComposerPromptCard extends StatelessWidget {
  const VnlfComposerPromptCard({
    super.key,
    this.promptText = '',
    this.onTap,
    this.semanticLabel,
    this.avatarSemanticLabel,
    this.addMediaSemanticLabel,
  });

  final String promptText;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final String? avatarSemanticLabel;
  final String? addMediaSemanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final effectiveSemantics =
        semanticLabel ?? (promptText.isNotEmpty ? promptText : null);

    return Semantics(
      button: true,
      label: effectiveSemantics,
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(VnlfDimensions.radiusLg),
          border: Border.all(color: colors.line),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(VnlfDimensions.radiusLg),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              child: Row(
                children: [
                  VnlfGuestAvatarBox(
                    size: 32,
                    isCircle: true,
                    semanticLabel: avatarSemanticLabel,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      promptText,
                      style: VnlfTypography.body(colors.muted),
                    ),
                  ),
                  Semantics(
                    label: addMediaSemanticLabel,
                    child: Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 20,
                      color: colors.brand,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Feed & Article Card matching `reference_feed_desktop.png`.
///
/// Places the 40x40 framed avatar in the left column and aligns the header,
/// body paragraphs, attachments, and interaction bar in the right column.
/// Supports loading, empty, and error state variants via constructor parameters
/// without any localization imports.
class VnlfPostCard extends StatelessWidget {
  const VnlfPostCard({
    super.key,
    this.post,
    this.poll,
    this.linkPreview,
    this.isLoading = false,
    this.isEmpty = false,
    this.controller,
    this.shimmerController,
    this.showSkeletonTitle = false,
    this.showSkeletonAttachment = false,
    this.emptyTitle = '',
    this.emptyMessage = '',
    this.emptyActionLabel,
    this.onEmptyAction,
    this.errorTitle = '',
    this.errorMessage,
    this.retryLabel = '',
    this.onRetry,
    this.loadingSemanticLabel,
    this.emptySemanticLabel,
    this.errorSemanticLabel,
    this.actionSemanticLabel,
    this.onVoteChanged,
    this.onCommentTap,
    this.onShareTap,
    this.onBookmarkToggle,
    this.onAuthorTap,
    this.onMoreTap,
    this.onReportTap,
    this.showBottomActions = true,
    this.framed = false,
    this.semanticLabel,
    this.authorAvatarSemanticLabel,
    this.moreOptionsSemanticLabel,
    this.codeCopyLabel = '',
    this.codeCopiedLabel = '',
    this.codeBlockSemanticLabel,
    this.voteSemanticLabel,
    this.upvoteSemanticLabel,
    this.downvoteSemanticLabel,
    this.commentSemanticLabel,
    this.shareSemanticLabel,
    this.bookmarkSemanticLabel,
  });

  const VnlfPostCard.loading({
    super.key,
    this.controller,
    this.shimmerController,
    this.showSkeletonTitle = false,
    this.showSkeletonAttachment = false,
    this.showBottomActions = true,
    this.semanticLabel,
    this.loadingSemanticLabel,
  }) : post = null,
       poll = null,
       linkPreview = null,
       isLoading = true,
       isEmpty = false,
       emptyTitle = '',
       emptyMessage = '',
       emptyActionLabel = null,
       onEmptyAction = null,
       errorTitle = '',
       errorMessage = null,
       retryLabel = '',
       onRetry = null,
       emptySemanticLabel = null,
       errorSemanticLabel = null,
       actionSemanticLabel = null,
       onVoteChanged = null,
       onCommentTap = null,
       onShareTap = null,
       onBookmarkToggle = null,
       onAuthorTap = null,
       onMoreTap = null,
       onReportTap = null,
       framed = false,
       authorAvatarSemanticLabel = null,
       moreOptionsSemanticLabel = null,
       codeCopyLabel = '',
       codeCopiedLabel = '',
       codeBlockSemanticLabel = null,
       voteSemanticLabel = null,
       upvoteSemanticLabel = null,
       downvoteSemanticLabel = null,
       commentSemanticLabel = null,
       shareSemanticLabel = null,
       bookmarkSemanticLabel = null;

  const VnlfPostCard.empty({
    super.key,
    this.emptyTitle = '',
    this.emptyMessage = '',
    this.emptyActionLabel,
    this.onEmptyAction,
    this.onRetry,
    this.semanticLabel,
    this.emptySemanticLabel,
    this.actionSemanticLabel,
  }) : post = null,
       poll = null,
       linkPreview = null,
       isLoading = false,
       isEmpty = true,
       controller = null,
       shimmerController = null,
       showSkeletonTitle = false,
       showSkeletonAttachment = false,
       errorTitle = '',
       errorMessage = null,
       retryLabel = '',
       loadingSemanticLabel = null,
       errorSemanticLabel = null,
       onVoteChanged = null,
       onCommentTap = null,
       onShareTap = null,
       onBookmarkToggle = null,
       onAuthorTap = null,
       onMoreTap = null,
       onReportTap = null,
       showBottomActions = true,
       framed = false,
       authorAvatarSemanticLabel = null,
       moreOptionsSemanticLabel = null,
       codeCopyLabel = '',
       codeCopiedLabel = '',
       codeBlockSemanticLabel = null,
       voteSemanticLabel = null,
       upvoteSemanticLabel = null,
       downvoteSemanticLabel = null,
       commentSemanticLabel = null,
       shareSemanticLabel = null,
       bookmarkSemanticLabel = null;

  const VnlfPostCard.error({
    super.key,
    this.errorTitle = '',
    this.errorMessage = '',
    this.retryLabel = '',
    this.onRetry,
    this.semanticLabel,
    this.errorSemanticLabel,
    this.actionSemanticLabel,
  }) : post = null,
       poll = null,
       linkPreview = null,
       isLoading = false,
       isEmpty = false,
       controller = null,
       shimmerController = null,
       showSkeletonTitle = false,
       showSkeletonAttachment = false,
       emptyTitle = '',
       emptyMessage = '',
       emptyActionLabel = null,
       onEmptyAction = null,
       loadingSemanticLabel = null,
       emptySemanticLabel = null,
       onVoteChanged = null,
       onCommentTap = null,
       onShareTap = null,
       onBookmarkToggle = null,
       onAuthorTap = null,
       onMoreTap = null,
       onReportTap = null,
       showBottomActions = true,
       framed = false,
       authorAvatarSemanticLabel = null,
       moreOptionsSemanticLabel = null,
       codeCopyLabel = '',
       codeCopiedLabel = '',
       codeBlockSemanticLabel = null,
       voteSemanticLabel = null,
       upvoteSemanticLabel = null,
       downvoteSemanticLabel = null,
       commentSemanticLabel = null,
       shareSemanticLabel = null,
       bookmarkSemanticLabel = null;

  final PostData? post;
  final Widget? poll;

  /// The link card under a post without photos or a poll.
  final Widget? linkPreview;
  final bool isLoading;
  final bool isEmpty;
  final Animation<double>? controller;
  final Animation<double>? shimmerController;
  final bool showSkeletonTitle;
  final bool showSkeletonAttachment;
  final String emptyTitle;
  final String emptyMessage;
  final String? emptyActionLabel;
  final VoidCallback? onEmptyAction;
  final String errorTitle;
  final String? errorMessage;
  final String retryLabel;
  final VoidCallback? onRetry;
  final String? loadingSemanticLabel;
  final String? emptySemanticLabel;
  final String? errorSemanticLabel;
  final String? actionSemanticLabel;
  final ValueChanged<VoteState>? onVoteChanged;
  final VoidCallback? onCommentTap;
  final VoidCallback? onShareTap;
  final VoidCallback? onBookmarkToggle;
  final VoidCallback? onAuthorTap;

  /// Opens the post menu under the "…" button, whose global rect is given.
  final ValueChanged<Rect>? onMoreTap;
  final VoidCallback? onReportTap;
  final bool showBottomActions;

  /// Draws the bordered card the detail screen still uses. Lists use the
  /// website's feed post: a plain surface band whose list draws the
  /// separators.
  final bool framed;
  final String? semanticLabel;
  final String? authorAvatarSemanticLabel;
  final String? moreOptionsSemanticLabel;
  final String codeCopyLabel;
  final String codeCopiedLabel;
  final String? codeBlockSemanticLabel;
  final String? voteSemanticLabel;
  final String? upvoteSemanticLabel;
  final String? downvoteSemanticLabel;
  final String? commentSemanticLabel;
  final String? shareSemanticLabel;
  final String? bookmarkSemanticLabel;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return VnlfPostCardSkeleton(
        controller: controller ?? shimmerController,
        showTitle: showSkeletonTitle,
        showAttachment: showSkeletonAttachment,
        showBottomActions: showBottomActions,
        semanticLabel: loadingSemanticLabel ?? semanticLabel,
      );
    }

    if (errorMessage != null || errorTitle.isNotEmpty) {
      return VnlfFeedErrorState(
        title: errorTitle,
        message: errorMessage ?? '',
        retryLabel: retryLabel,
        onRetry: onRetry,
        semanticLabel: errorSemanticLabel ?? semanticLabel,
        actionSemanticLabel: actionSemanticLabel,
      );
    }

    if (isEmpty || post == null) {
      return VnlfFeedEmptyState(
        title: emptyTitle,
        message: emptyMessage,
        actionLabel: emptyActionLabel,
        onRetry: onEmptyAction ?? onRetry,
        semanticLabel: emptySemanticLabel ?? semanticLabel,
        actionSemanticLabel: actionSemanticLabel,
      );
    }

    final loadedPost = post!;
    final colors = VnlfColors.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final phone = VnlfViewportSize.fromWidth(width) == VnlfViewportSize.mobile;

    final avatar = VnlfProfilePreview.wrap(
      context,
      loadedPost.author.username,
      GestureDetector(
        onTap: onAuthorTap,
        child: VnlfAvatar(
          author: loadedPost.author,
          size: phone ? 40 : 43,
          semanticLabel: authorAvatarSemanticLabel,
        ),
      ),
    );
    final head = Row(
      crossAxisAlignment: phone
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: VnlfProfilePreview.wrap(
              context,
              loadedPost.author.username,
              GestureDetector(
                onTap: onAuthorTap,
                child: _FeedAuthorLine(
                  author: loadedPost.author,
                  stacked: width <= 520,
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: phone ? 6 : 8),
        Text(
          loadedPost.relativeTime,
          maxLines: 1,
          style: VnlfTypography.meta(colors.muted),
        ),
        _PostMoreButton(
          phone: phone,
          isBookmarked: loadedPost.isBookmarked,
          semanticLabel: moreOptionsSemanticLabel,
          onMoreTap: onMoreTap,
          onShareTap: onShareTap,
          onBookmarkToggle: onBookmarkToggle,
          onReportTap: onReportTap,
        ),
      ],
    );

    final title = loadedPost.title ?? '';
    final titleStyle = VnlfTypography.body(colors.ink).copyWith(
      fontWeight: FontWeight.w700,
      height: 1.35,
      letterSpacing: -0.025 * VnlfTypography.baseSize,
    );
    final body = <Widget>[
      // The website picks the block by kind: an article shows its title and
      // excerpt, a post its own body.
      if (loadedPost.isArticle && title.isNotEmpty)
        Padding(
          padding: EdgeInsets.only(top: phone ? 4 : 7),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: phone ? 5 : 7,
            children: [
              Text(title, style: titleStyle),
              for (final paragraph in loadedPost.paragraphs)
                if (paragraph.isNotEmpty && paragraph != title)
                  Text(
                    paragraph,
                    style: VnlfTypography.body(colors.muted)
                        .copyWith(height: 1.55),
                  ),
            ],
          ),
        )
      else ...[
        if (title.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(top: phone ? 4 : 7),
            child: Text(title, style: titleStyle),
          ),
        Padding(
          padding: EdgeInsets.only(top: phone ? 4 : 6),
          child: loadedPost.richContent != null
              ? _FeedBodyClamp(
                  clamp: !loadedPost.selectableContent,
                  child: VnlfRichContent(
                    document: loadedPost.richContent!,
                    showImages: loadedPost.showInlineImages,
                    selectable: loadedPost.selectableContent,
                    postStyle: !loadedPost.isArticle,
                    articleDetail:
                        loadedPost.isArticle && loadedPost.selectableContent,
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 8,
                  children: [
                    for (final paragraph in loadedPost.paragraphs)
                      _VnlfPostParagraph(
                        text: paragraph,
                        style: VnlfTypography.body(colors.ink)
                            .copyWith(height: 1.6),
                        linkColor: colors.brand,
                      ),
                  ],
                ),
        ),
      ],
      if (loadedPost.attachment != null)
        Padding(
          padding: EdgeInsets.only(top: phone ? 8 : 12),
          child: VnlfPostAttachmentView(
            attachment: loadedPost.attachment!,
            codeCopyLabel: codeCopyLabel,
            codeCopiedLabel: codeCopiedLabel,
            codeBlockSemanticLabel: codeBlockSemanticLabel,
          ),
        ),
      ?poll,
      ?linkPreview,
      if (loadedPost.actionError != null)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            loadedPost.actionError!,
            style: VnlfTypography.meta(colors.red),
          ),
        ),
      if (loadedPost.tags.isNotEmpty)
        Padding(
          padding: EdgeInsets.only(top: phone ? 5 : 9),
          child: Wrap(
            spacing: 7,
            runSpacing: 4,
            children: [
              for (final tag in loadedPost.tags)
                Text(
                  '#$tag',
                  style: VnlfTypography.meta(colors.brand)
                      .copyWith(fontWeight: FontWeight.w700),
                ),
            ],
          ),
        ),
      if (showBottomActions)
        Padding(
          padding: EdgeInsets.only(top: phone ? 2 : 14),
          child: VnlfPostInteractionBar(
            voteScore: loadedPost.voteScore,
            voteState: loadedPost.viewerVote,
            commentCount: loadedPost.commentCount,
            isBookmarked: loadedPost.isBookmarked,
            onVoteChanged: loadedPost.actionPending ? null : onVoteChanged,
            onCommentTap: onCommentTap,
            onShareTap: onShareTap,
            onBookmarkToggle: loadedPost.actionPending
                ? null
                : onBookmarkToggle,
            voteSemanticLabel: voteSemanticLabel,
            upvoteSemanticLabel: upvoteSemanticLabel,
            downvoteSemanticLabel: downvoteSemanticLabel,
            commentSemanticLabel: commentSemanticLabel,
            shareSemanticLabel: shareSemanticLabel,
            bookmarkSemanticLabel: bookmarkSemanticLabel,
            viewCount: loadedPost.viewCount,
            viewsLabel: loadedPost.viewCount == null
                ? null
                : format(vi.miscViews.luotXem, {
                    'viewCount': NumberFormat.decimalPattern('vi')
                        .format(loadedPost.viewCount),
                  }),
            viewsTooltip: vi.miscViews.chiBanThayLuotXem,
          ),
        ),
    ];

    // Phones put the avatar beside the head row only; every block after it
    // spans the full width, as the website's `display: contents` grid does.
    final content = phone
        ? Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  avatar,
                  const SizedBox(width: 10),
                  Expanded(child: head),
                ],
              ),
              ...body,
            ],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              avatar,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [head, ...body],
                ),
              ),
            ],
          );

    final Widget card = framed
        ? Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(VnlfDimensions.radiusLg),
              border: Border.all(color: colors.line),
            ),
            padding: const EdgeInsets.all(16),
            child: content,
          )
        : ColoredBox(
            color: colors.surface,
            child: Padding(
              padding: phone
                  ? const EdgeInsets.fromLTRB(16, 12, 16, 4)
                  : const EdgeInsets.fromLTRB(18, 18, 18, 14),
              child: content,
            ),
          );

    if (semanticLabel == null) {
      return card;
    }
    return Semantics(label: semanticLabel, container: true, child: card);
  }
}

/// Name and @username as the website's feed shows them: on one line, or
/// stacked under 520px.
class _FeedAuthorLine extends StatelessWidget {
  const _FeedAuthorLine({required this.author, required this.stacked});

  final AuthorData author;
  final bool stacked;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final name = VnlfAuthorNameRow(
      author: author,
      showHandleInline: false,
      allowWrap: false,
    );
    if (author.username.isEmpty) return name;
    final handle = Text(
      '@${author.username}',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: VnlfTypography.meta(colors.muted),
    );
    return stacked
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 1,
            children: [name, handle],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: 7,
            children: [
              Flexible(child: name),
              Flexible(child: handle),
            ],
          );
  }
}

/// The feed clamps a text post to four lines (13px × 1.6), as the website
/// does with `line-clamp: 4`.
class _FeedBodyClamp extends StatelessWidget {
  const _FeedBodyClamp({required this.clamp, required this.child});

  final bool clamp;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!clamp) return child;
    final scale = MediaQuery.textScalerOf(context);
    final lineHeight = scale.scale(VnlfTypography.baseSize) * 1.6;
    return ClipRect(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: lineHeight * 4),
        child: OverflowBox(
          alignment: Alignment.topLeft,
          maxHeight: double.infinity,
          fit: OverflowBoxFit.deferToChild,
          child: child,
        ),
      ),
    );
  }
}

/// The post's "…" control: a 26px icon button on wider screens, a 48px
/// target on phones.
class _PostMoreButton extends StatelessWidget {
  const _PostMoreButton({
    required this.phone,
    required this.isBookmarked,
    this.semanticLabel,
    this.onMoreTap,
    this.onShareTap,
    this.onBookmarkToggle,
    this.onReportTap,
  });

  final bool phone;
  final bool isBookmarked;
  final String? semanticLabel;

  /// Opens the post menu under the "…" button, whose global rect is given.
  final ValueChanged<Rect>? onMoreTap;
  final VoidCallback? onShareTap;
  final VoidCallback? onBookmarkToggle;
  final VoidCallback? onReportTap;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final size = phone ? 48.0 : 26.0;
    final icon = VnlfIcon(VnlfLucide.ellipsis, size: 18, color: colors.muted);
    Widget item(VnlfLucide glyph, String label, Color color) => Row(
      spacing: 9,
      children: [
        VnlfIcon(glyph, size: 16, color: color),
        Text(label, style: VnlfTypography.body(color)),
      ],
    );
    return Semantics(
      label: semanticLabel,
      button: true,
      child: SizedBox.square(
        dimension: size,
        child: onMoreTap != null
            ? InkWell(
                customBorder: const CircleBorder(),
                onTap: () {
                  final box = context.findRenderObject() as RenderBox?;
                  if (box != null) {
                    onMoreTap!(box.localToGlobal(Offset.zero) & box.size);
                  }
                },
                child: Center(child: icon),
              )
            : PopupMenuButton<String>(
                tooltip: semanticLabel ?? vi.app.designSystem.tuyChon,
                padding: EdgeInsets.zero,
                icon: icon,
                color: colors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(VnlfDimensions.radiusMd),
                  side: BorderSide(color: colors.line),
                ),
                onSelected: (value) => switch (value) {
                  'copy' => onShareTap?.call(),
                  'bookmark' => onBookmarkToggle?.call(),
                  'report' => onReportTap?.call(),
                  _ => null,
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'bookmark',
                    height: 42,
                    child: item(
                      VnlfLucide.bookmark,
                      isBookmarked
                          ? vi.common.boLuuBaiViet
                          : vi.common.luuBaiViet,
                      colors.ink,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'copy',
                    height: 42,
                    child: item(
                      VnlfLucide.link2,
                      vi.socialOverlays.saoChepLienKet,
                      colors.ink,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'report',
                    enabled: onReportTap != null,
                    height: 42,
                    child: item(
                      VnlfLucide.messageSquareText,
                      vi.common.baoCao,
                      colors.red,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _VnlfPostParagraph extends StatefulWidget {
  const _VnlfPostParagraph({
    required this.text,
    required this.style,
    required this.linkColor,
  });

  final String text;
  final TextStyle style;
  final Color linkColor;

  @override
  State<_VnlfPostParagraph> createState() => _VnlfPostParagraphState();
}

class _VnlfPostParagraphState extends State<_VnlfPostParagraph> {
  static final _urlRegex = RegExp(r'''(https?://[^\s<]+[^<.,:;"')\]\s])''');
  final _recognizers = <TapGestureRecognizer>[];

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();

    final matches = _urlRegex.allMatches(widget.text).toList();
    if (matches.isEmpty) {
      return Text(widget.text, style: widget.style);
    }

    final spans = <InlineSpan>[];
    var lastIndex = 0;

    for (final match in matches) {
      if (match.start > lastIndex) {
        spans.add(
          TextSpan(
            text: widget.text.substring(lastIndex, match.start),
            style: widget.style,
          ),
        );
      }

      final url = match.group(0)!;
      final recognizer = TapGestureRecognizer()
        ..onTap = () {
          openVnlfLink(context, url);
        };
      _recognizers.add(recognizer);

      spans.add(
        TextSpan(
          text: url,
          style: widget.style.copyWith(
            color: widget.linkColor,
            decoration: TextDecoration.underline,
          ),
          recognizer: recognizer,
        ),
      );

      lastIndex = match.end;
    }

    if (lastIndex < widget.text.length) {
      spans.add(
        TextSpan(text: widget.text.substring(lastIndex), style: widget.style),
      );
    }

    return Text.rich(TextSpan(children: spans), style: widget.style);
  }
}
