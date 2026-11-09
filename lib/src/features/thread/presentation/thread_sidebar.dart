import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/design_system.dart';
import '../../../i18n/vi.dart';
import '../../leaderboard/presentation/leaderboard_screen.dart';
import '../../shared/presentation/author_mapper.dart';
import '../../shared/presentation/feature_widgets.dart';
import 'thread_screen.dart';

class ThreadSidebar extends ConsumerWidget {
  const ThreadSidebar({super.key, required this.postId});

  final String postId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final post = ref.watch(threadPostProvider(postId)).asData?.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (post != null) ...[
          FeatureSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VnlfAvatar(author: presentAuthor(post.author), size: 56),
                const SizedBox(height: 12),
                VnlfAuthorNameRow(author: presentAuthor(post.author)),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => context.push(
                    '/profile/${Uri.encodeComponent(post.author.username)}',
                  ),
                  child: Text(vi.app.thread.xemTrangCaNhan),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        const LeaderboardPanel(sidebar: true),
      ],
    );
  }
}
