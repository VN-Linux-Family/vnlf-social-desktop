import '../../../i18n/vi.dart';
import '../../polls/presentation/poll_card.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/design_system.dart';
import '../../../domain/models.dart';
import '../../feed/presentation/post_mapper.dart';
import '../../shared/presentation/post_share.dart';
import '../../shared/presentation/post_interactions.dart';

class DiscoverArticles extends ConsumerWidget {
  const DiscoverArticles({
    super.key,
    required this.posts,
    required this.query,
    this.tag,
  });

  final List<FeedPost> posts;
  final String query;
  final String? tag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visible = posts.where((post) {
      final text =
          '${post.title ?? ''} ${post.excerpt} ${post.contentText} ${post.tags.join(' ')}'
              .toLowerCase();
      return text.contains(query.toLowerCase()) &&
          (tag == null || text.contains(tag!.toLowerCase()));
    }).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (visible.isEmpty)
          VnlfStateCard(
            icon: Icons.search_off,
            title: vi.app.discover.khongCoKetQua,
            message: vi.app.discover.hayThuTuKhoa,
          ),
        for (final post in visible)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () =>
                  context.push('/thread/${Uri.encodeComponent(post.id)}'),
              child: VnlfPostCard(
                poll: post.poll == null
                    ? null
                    : PollCard(poll: post.poll!, authorId: post.author.id),
                post: ref
                    .watch(postInteractionProvider(post.id))
                    .apply(presentPost(post)),
                onVoteChanged: (vote) => ref
                    .read(postInteractionsProvider.notifier)
                    .vote(post.id, vote),
                onBookmarkToggle: () => ref
                    .read(postInteractionsProvider.notifier)
                    .toggleBookmark(
                      post.id,
                      initialValue: post.viewerBookmarked,
                    ),
                upvoteSemanticLabel: vi.app.common.ungHo,
                downvoteSemanticLabel: vi.app.common.phanDoi,
                bookmarkSemanticLabel: vi.app.common.luuBaiViet,
                commentSemanticLabel: vi.common.binhLuan,
                onShareTap: () => copyPostLink(context, post),
                shareSemanticLabel: vi.miscViews.chiaSe,
                onCommentTap: () =>
                    context.push('/thread/${Uri.encodeComponent(post.id)}'),
                onAuthorTap: () => context.push(
                  '/profile/${Uri.encodeComponent(post.author.username)}',
                ),
              ),
            ),
          ),
      ],
    );
  }
}
