import '../../../i18n/vi.dart';
import '../../polls/presentation/poll_card.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../design_system/design_system.dart';
import '../../../domain/models.dart';
import '../../feed/presentation/post_mapper.dart';
import '../../shared/presentation/feature_widgets.dart';
import '../../shared/presentation/post_share.dart';
import '../../shared/presentation/post_interactions.dart';
import '../domain/public_profile.dart';
import 'profile_data.dart';

class ProfileContent extends ConsumerWidget {
  const ProfileContent({super.key, required this.username, required this.tab});
  final String username;
  final int tab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (tab) {
      0 => _section<FeedPage>(
        ref.watch(profilePostsProvider(username)),
        () => ref.invalidate(profilePostsProvider(username)),
        (page) => [
          if (page.items.isEmpty) _empty(vi.app.profile.chuaCoBaiViet),
          for (final post in page.items)
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
                  onAuthorTap: () => context.push(
                    '/profile/${Uri.encodeComponent(post.author.username)}',
                  ),
                  onCommentTap: () =>
                      context.push('/thread/${Uri.encodeComponent(post.id)}'),
                  onShareTap: () => copyPostLink(context, post),
                  shareSemanticLabel: vi.miscViews.chiaSe,
                ),
              ),
            ),
          if (page.nextCursor != null) _empty(vi.app.profile.dangHienThi50Bai),
        ],
      ),
      1 => _section<ProfileCommentsPage>(
        ref.watch(profileCommentsProvider(username)),
        () => ref.invalidate(profileCommentsProvider(username)),
        (page) => [
          if (page.items.isEmpty) _empty(vi.accountViews.chuaCoBinhLuanPublic),
          for (final comment in page.items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: FeatureSurface(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.mode_comment_outlined, size: 16),
                  title: Text(comment.content),
                  subtitle: comment.createdAt == null
                      ? null
                      : Text(
                          DateFormat.yMd(vi.app.profile.vi)
                              .format(comment.createdAt!.toLocal()),
                        ),
                  trailing: const Icon(Icons.arrow_outward, size: 16),
                  onTap: comment.articleId.isEmpty
                      ? null
                      : () => context.push(
                          '/thread/${Uri.encodeComponent(comment.articleId)}',
                        ),
                ),
              ),
            ),
          if (page.nextCursor != null) _empty(vi.app.profile.dangHienThi50),
        ],
      ),
      _ => _section<ProjectsPage>(
        ref.watch(profileProjectsProvider(username)),
        () => ref.invalidate(profileProjectsProvider(username)),
        (page) => [
          if (page.items.isEmpty) _empty(vi.app.common.chuaCoDuAn),
          for (final item in page.items)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: VnlfProjectPreviewCard(
                project: ProjectShowcaseData(
                  id: item.id,
                  name: item.name,
                  description: item.tagline,
                  primaryLanguage: item.repo?['language'] as String? ?? '',
                  tag: item.type,
                  stars: (item.repo?['stars'] as num?)?.toInt() ?? 0,
                  forks: (item.repo?['forks'] as num?)?.toInt() ?? 0,
                  rating: (item.rating?['average'] as num?)?.toDouble() ?? 0,
                ),
              ),
            ),
        ],
      ),
    };
  }

  Widget _empty(String text) => FeatureSurface(child: Text(text));

  Widget _section<T>(
    AsyncValue<T> value,
    VoidCallback retry,
    List<Widget> Function(T) content,
  ) => value.when(
    loading: () => const Center(child: CircularProgressIndicator()),
    error: (error, stack) => FeatureLoadError(onRetry: retry),
    data: (data) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: content(data),
    ),
  );
}
