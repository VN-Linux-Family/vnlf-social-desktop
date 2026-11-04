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

/// Composer prompt card ("Hôm nay bạn muốn chia sẻ điều gì?") at the top of the feed.
class VnlfComposerPromptCard extends StatelessWidget {
  const VnlfComposerPromptCard({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);

    return Container(
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
                const VnlfGuestAvatarBox(size: 32, isCircle: true),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Hôm nay bạn muốn chia sẻ điều gì?',
                    style: VnlfTypography.body(colors.muted),
                  ),
                ),
                Icon(
                  Icons.add_photo_alternate_outlined,
                  size: 20,
                  color: colors.brand,
                ),
              ],
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
  });

  final PostData post;
  final ValueChanged<VoteState>? onVoteChanged;
  final VoidCallback? onCommentTap;
  final VoidCallback? onBookmarkToggle;
  final VoidCallback? onAuthorTap;
  final bool showBottomActions;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);

    return Container(
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
            child: VnlfAvatar(author: post.author, size: 40),
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
                    Icon(
                      Icons.more_horiz_rounded,
                      size: 16,
                      color: colors.muted,
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
                    final LinuxDesktopAttachment desktop =>
                      VnlfLinuxDesktopPreview(attachment: desktop),
                    final CodeBlockAttachment codeBlock => VnlfCodeBlock(
                      code: codeBlock.code,
                      showHorizontalScrollbar:
                          codeBlock.showHorizontalScrollbar,
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
