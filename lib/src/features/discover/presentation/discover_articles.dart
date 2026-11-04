import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/design_system.dart';
import '../../../domain/models.dart';
import '../../feed/presentation/post_mapper.dart';

class DiscoverArticles extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final english = Localizations.localeOf(context).languageCode == 'en';
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
            title: english ? 'No results' : 'Không có kết quả',
            message: english
                ? 'Try another search or tag.'
                : 'Hãy thử từ khóa hoặc chủ đề khác.',
          ),
        for (final post in visible)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () =>
                  context.push('/thread/${Uri.encodeComponent(post.id)}'),
              child: VnlfPostCard(
                post: presentPost(post, english: english),
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
