import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../data/field_reader.dart';
import '../../../domain/models.dart';
import '../../shared/presentation/feature_samples.dart';

final profileProvider = FutureProvider.autoDispose
    .family<ProfileViewData?, String>((ref, id) async {
      var targetUsername = id;
      if (targetUsername == 'self') {
        final session = ref.watch(sessionProvider).valueOrNull;
        if (session != null && session.username.isNotEmpty) {
          targetUsername = session.username;
        } else {
          return null;
        }
      }

      final client = ref.watch(apiClientProvider);

      if (!offlineFeatures) {
        try {
          final liveUser = await client.get<Map<String, dynamic>?>(
            '/api/v1/users/${Uri.encodeComponent(targetUsername)}',
            decode: (json) => json,
          );
          if (liveUser != null) {
            final feed = await ref.watch(feedRepositoryProvider).getFeed();
            final projects = await ref
                .watch(projectsRepositoryProvider)
                .getProjects();
            final author = Author(
              id: liveUser['id'] as String? ?? '',
              username: liveUser['username'] as String? ?? targetUsername,
              displayName:
                  liveUser['displayName'] as String? ??
                  liveUser['username'] as String? ??
                  targetUsername,
              avatarUrl: liveUser['avatarUrl'] as String? ?? '',
              role: liveUser['role'] as String? ?? '',
              style: styleValue(liveUser['style'], 'user.style'),
            );
            return ProfileViewData(
              author: author,
              posts: [
                ...feed.items.where(
                  (post) => post.author.username == author.username,
                ),
              ],
              projects: projects.items
                  .where((item) => item.owner?.username == author.username)
                  .toList(),
              karma: liveUser['totalPoints'] as int?,
              bio: liveUser['bio'] as String?,
              followerCount: liveUser['followerCount'] as int?,
              followingCount: liveUser['followingCount'] as int?,
              isSample: false,
            );
          }
        } catch (_) {}
      }

      final (feed, rankings, projects) = await (
        ref.watch(feedRepositoryProvider).getFeed(),
        ref.watch(leaderboardRepositoryProvider).getLeaderboard(),
        ref.watch(projectsRepositoryProvider).getProjects(),
      ).wait;

      final authors = [
        ...feed.items.map((post) => post.author),
        ...rankings.items.map(
          (item) => Author(
            id: item.userId,
            username: item.username,
            displayName: item.displayName,
            avatarUrl: item.avatarUrl,
            style: item.style,
          ),
        ),
        if (offlineFeatures) sampleAuthor,
      ];
      final author =
          authors
              .where((item) => item.username == targetUsername)
              .firstOrNull ??
          authors.where((item) => item.id == targetUsername).firstOrNull;
      if (author == null) return null;
      final ranking = rankings.items
          .where((item) => item.username == author.username)
          .firstOrNull;
      return ProfileViewData(
        author: author,
        posts: [
          ...feed.items.where(
            (post) => post.author.username == author.username,
          ),
          if (offlineFeatures && author.username == sampleAuthor.username)
            samplePost,
        ],
        projects: projects.items
            .where((item) => item.owner?.username == author.username)
            .toList(),
        karma: ranking?.earnedPoints,
        isSample: offlineFeatures && author.username == sampleAuthor.username,
      );
    });

class ProfileViewData {
  ProfileViewData({
    required this.author,
    required List<FeedPost> posts,
    required List<ProjectItem> projects,
    required this.isSample,
    this.karma,
    this.bio,
    this.followerCount,
    this.followingCount,
  }) : posts = List.unmodifiable(posts),
       projects = List.unmodifiable(projects);

  final Author author;
  final List<FeedPost> posts;
  final List<ProjectItem> projects;
  final int? karma;
  final bool isSample;
  final String? bio;
  final int? followerCount;
  final int? followingCount;
}
