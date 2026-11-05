import 'package:flutter/material.dart';

import '../models/vnlf_models.dart';
import '../tokens/vnlf_colors.dart';
import '../tokens/vnlf_dimensions.dart';
import '../tokens/vnlf_typography.dart';
import 'vnlf_author_identity.dart';
import 'vnlf_avatar.dart';
import 'vnlf_code_block.dart';
import 'vnlf_media_preview.dart';
import 'vnlf_rich_content.dart';
import 'vnlf_media_gallery.dart';
import 'vnlf_skeleton.dart';
import 'vnlf_state_cards.dart';
import 'vnlf_vote_capsule.dart';

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
  final VoidCallback? onMoreTap;
  final VoidCallback? onReportTap;
  final bool showBottomActions;
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

    final card = Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(VnlfDimensions.radiusLg),
        border: Border.all(color: colors.line),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onAuthorTap,
            child: VnlfAvatar(
              author: loadedPost.author,
              size: 40,
              semanticLabel: authorAvatarSemanticLabel,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: onAuthorTap,
                        child: VnlfAuthorNameRow(author: loadedPost.author),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      loadedPost.relativeTime,
                      style: VnlfTypography.meta(colors.textSubtle),
                    ),
                    const SizedBox(width: 6),
                    Semantics(
                      label: moreOptionsSemanticLabel,
                      child: onMoreTap != null
                          ? InkWell(
                              borderRadius: BorderRadius.circular(999),
                              onTap: onMoreTap,
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  Icons.more_horiz_rounded,
                                  size: 16,
                                  color: colors.muted,
                                ),
                              ),
                            )
                          : PopupMenuButton<String>(
                              tooltip: moreOptionsSemanticLabel ?? 'Tùy chọn',
                              icon: Icon(
                                Icons.more_horiz_rounded,
                                size: 16,
                                color: colors.muted,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 24,
                                minHeight: 24,
                              ),
                              color: colors.surface,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  VnlfDimensions.radiusMd,
                                ),
                                side: BorderSide(color: colors.line),
                              ),
                              onSelected: (value) {
                                switch (value) {
                                  case 'copy':
                                    onShareTap?.call();
                                  case 'bookmark':
                                    onBookmarkToggle?.call();
                                  case 'report':
                                    onReportTap?.call();
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'copy',
                                  height: 38,
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.link_rounded,
                                        size: 18,
                                        color: colors.ink,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Sao chép liên kết',
                                        style: VnlfTypography.caption(
                                          colors.ink,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'bookmark',
                                  height: 38,
                                  child: Row(
                                    children: [
                                      Icon(
                                        loadedPost.isBookmarked
                                            ? Icons.bookmark_remove_rounded
                                            : Icons.bookmark_add_rounded,
                                        size: 18,
                                        color: colors.ink,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        loadedPost.isBookmarked
                                            ? 'Bỏ lưu bài viết'
                                            : 'Lưu bài viết',
                                        style: VnlfTypography.caption(
                                          colors.ink,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'report',
                                  enabled: onReportTap != null,
                                  height: 38,
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.flag_outlined,
                                        size: 18,
                                        color: colors.red,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Báo cáo bài viết',
                                        style: VnlfTypography.caption(
                                          colors.red,
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
                if (loadedPost.title != null &&
                    loadedPost.title!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(loadedPost.title!, style: VnlfTypography.h2(colors.ink)),
                ],
                const SizedBox(height: 6),
                if (loadedPost.richContent != null)
                  VnlfRichContent(
                    document: loadedPost.richContent!,
                    showImages: loadedPost.showInlineImages,
                    selectable: loadedPost.selectableContent,
                  )
                else
                  for (var i = 0; i < loadedPost.paragraphs.length; i++) ...[
                    if (i > 0) const SizedBox(height: 8),
                    Text(
                      loadedPost.paragraphs[i],
                      style: VnlfTypography.body(colors.ink),
                    ),
                  ],
                // Optional Attachment
                if (loadedPost.attachment != null) ...[
                  const SizedBox(height: 12),
                  switch (loadedPost.attachment!) {
                    final MediaGalleryAttachment gallery => VnlfMediaGallery(
                      items: gallery.items,
                    ),
                    final ImagePlaceholderAttachment imagePlaceholder =>
                      VnlfImagePlaceholder(
                        imageUrl: imagePlaceholder.imageUrl,
                        aspectRatio: imagePlaceholder.aspectRatio,
                        label: imagePlaceholder.label,
                        semanticLabel: imagePlaceholder.semanticLabel,
                      ),
                    final CodeBlockAttachment codeBlock => VnlfCodeBlock(
                      code: codeBlock.code,
                      showHorizontalScrollbar:
                          codeBlock.showHorizontalScrollbar,
                      copyLabel: codeBlock.copyLabel.isNotEmpty
                          ? codeBlock.copyLabel
                          : codeCopyLabel,
                      copiedLabel: codeBlock.copiedLabel.isNotEmpty
                          ? codeBlock.copiedLabel
                          : codeCopiedLabel,
                      semanticLabel:
                          codeBlock.semanticLabel ?? codeBlockSemanticLabel,
                      copyButtonSemanticLabel:
                          codeBlock.copyButtonSemanticLabel,
                    ),
                    final ProjectPreviewAttachment projectPreview =>
                      VnlfProjectPreviewCard(project: projectPreview.project),
                  },
                ],
                if (loadedPost.actionError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      loadedPost.actionError!,
                      style: VnlfTypography.meta(colors.red),
                    ),
                  ),
                // Optional Category Tags
                if (loadedPost.tags.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final tag in loadedPost.tags)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: colors.surfaceSoft,
                            borderRadius: BorderRadius.circular(
                              VnlfDimensions.radiusSm,
                            ),
                            border: Border.all(color: colors.line),
                          ),
                          child: Text(
                            '#$tag',
                            style: VnlfTypography.caption(colors.muted),
                          ),
                        ),
                    ],
                  ),
                ],
                if (showBottomActions) ...[
                  const SizedBox(height: 12),
                  VnlfPostInteractionBar(
                    voteScore: loadedPost.voteScore,
                    voteState: loadedPost.viewerVote,
                    commentCount: loadedPost.commentCount,
                    isBookmarked: loadedPost.isBookmarked,
                    onVoteChanged: loadedPost.actionPending
                        ? null
                        : onVoteChanged,
                    onCommentTap: onCommentTap,
                    onShareTap: onShareTap,
                    onBookmarkToggle: onBookmarkToggle,
                    voteSemanticLabel: voteSemanticLabel,
                    upvoteSemanticLabel: upvoteSemanticLabel,
                    downvoteSemanticLabel: downvoteSemanticLabel,
                    commentSemanticLabel: commentSemanticLabel,
                    shareSemanticLabel: shareSemanticLabel,
                    bookmarkSemanticLabel: bookmarkSemanticLabel,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    if (semanticLabel == null) {
      return card;
    }
    return Semantics(label: semanticLabel, container: true, child: card);
  }
}
