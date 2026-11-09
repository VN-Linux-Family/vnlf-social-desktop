import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/design_system.dart';
import '../../../domain/models.dart';
import '../../../i18n/vi.dart';
import '../../feed/presentation/post_mapper.dart';
import '../../polls/presentation/poll_card.dart';
import 'post_interactions.dart';
import 'post_link_preview.dart';
import 'post_menu.dart';
import 'post_share.dart';

/// A post in a list (feed, explore, profile), wired like the website's
/// `ThreadPost`: open, vote, comment, share dialog, save and the "…" menu.
class PostCardTile extends ConsumerWidget {
  const PostCardTile({super.key, required this.post});

  final FeedPost post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final interaction = ref.watch(postInteractionProvider(post.id));
    final detail = interaction.apply(presentPost(post));
    final path = '/thread/${Uri.encodeComponent(post.id)}';
    final voteLabel = vi.contentVote.baiViet;
    final article = post.format.toUpperCase() == 'ARTICLE';
    return InkWell(
      onTap: () => context.push(path),
      child: VnlfPostCard(
        key: ValueKey(post.id),
        poll: post.poll == null
            ? null
            : PollCard(poll: post.poll!, authorId: post.author.id),
        linkPreview: !article && post.attachments.isEmpty && post.poll == null
            ? PostLinkPreview(content: post.contentText)
            : null,
        post: detail,
        onVoteChanged: (vote) => votePost(context, ref, post, vote),
        onBookmarkToggle: () => togglePostBookmark(context, ref, post),
        authorAvatarSemanticLabel: post.author.displayName,
        onAuthorTap: () => context.push(
          '/profile/${Uri.encodeComponent(post.author.username)}',
        ),
        onShareTap: () => showPostShareDialog(context, post),
        onMoreTap: (anchor) => showPostMenu(context, ref, post, anchor: anchor),
        onCommentTap: () => context.push(path),
        moreOptionsSemanticLabel: vi.feedViews.moMenuBaiViet,
        upvoteSemanticLabel: format(vi.contentVote.upvote, {
          'label': voteLabel,
        }),
        downvoteSemanticLabel: format(vi.contentVote.downvote, {
          'label': voteLabel,
        }),
        commentSemanticLabel: vi.feedViews.moBinhLuan,
        shareSemanticLabel: vi.common.chiaSeBaiViet,
        bookmarkSemanticLabel: detail.isBookmarked
            ? vi.common.boLuuBaiViet
            : vi.common.luuBaiViet,
      ),
    );
  }
}
