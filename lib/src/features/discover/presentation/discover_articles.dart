import '../../../i18n/vi.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/design_system.dart';
import '../../../domain/models.dart';
import '../../shared/presentation/post_card_tile.dart';

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
            child: PostCardTile(post: post),
          ),
      ],
    );
  }
}
