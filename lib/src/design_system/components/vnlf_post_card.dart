import 'package:flutter/material.dart';

import '../models/vnlf_models.dart';
import '../tokens/vnlf_colors.dart';
import '../tokens/vnlf_dimensions.dart';
import '../tokens/vnlf_typography.dart';
import 'vnlf_author_identity.dart';
import 'vnlf_avatar.dart';
import 'vnlf_code_block.dart';
import 'vnlf_media_preview.dart';
import 'vnlf_vote_capsule.dart';

export 'vnlf_skeleton.dart'
    show
        VnlfFeedPostSkeleton,
        VnlfFeedPostsSkeleton,
        VnlfFeedSkeletonList,
        VnlfPostCardSkeleton;
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
class VnlfPostCard extends StatelessWidget {
  const VnlfPostCard({
    super.key,
    required this.post,
    this.onVoteChanged,
    this.onCommentTap,
    this.onBookmarkToggle,
    this.onAuthorTap,
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

  final PostData post;
  final ValueChanged<VoteState>? onVoteChanged;
  final VoidCallback? onCommentTap;
  final VoidCallback? onBookmarkToggle;
  final VoidCallback? onAuthorTap;
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
              author: post.author,
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
                        child: VnlfAuthorNameRow(author: post.author),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      post.relativeTime,
                      style: VnlfTypography.meta(colors.textSubtle),
                    ),
                    const SizedBox(width: 6),
                    Semantics(
                      label: moreOptionsSemanticLabel,
                      child: Icon(
                        Icons.more_horiz_rounded,
                        size: 16,
                        color: colors.muted,
                      ),
                    ),
                  ],
                ),
                if (post.title != null && post.title!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(post.title!, style: VnlfTypography.h2(colors.ink)),
                ],
                const SizedBox(height: 6),
                // Paragraphs
                for (var i = 0; i < post.paragraphs.length; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  Text(
                    post.paragraphs[i],
                    style: VnlfTypography.body(colors.ink),
                  ),
                ],
                // Optional Attachment
                if (post.attachment != null) ...[
                  const SizedBox(height: 12),
                  switch (post.attachment!) {
                    final ImagePlaceholderAttachment imagePlaceholder =>
                      VnlfImagePlaceholder(
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
                // Optional Category Tags
                if (post.tags.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final tag in post.tags)
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
                    voteScore: post.voteScore,
                    voteState: post.viewerVote,
                    commentCount: post.commentCount,
                    isBookmarked: post.isBookmarked,
                    onVoteChanged: onVoteChanged,
                    onCommentTap: onCommentTap,
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
