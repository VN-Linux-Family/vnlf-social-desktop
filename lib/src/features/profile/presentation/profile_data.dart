import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../domain/models.dart';
import '../../shared/presentation/feature_samples.dart';

final profileProvider = FutureProvider.autoDispose
    .family<ProfileViewData?, String>((ref, id) async {
      final feedFuture = ref.watch(feedRepositoryProvider).getFeed();
      final rankingsFuture = ref
          .watch(leaderboardRepositoryProvider)
          .getLeaderboard();
      final projectsFuture = ref
          .watch(projectsRepositoryProvider)
          .getProjects();
      final (feed, rankings, projects) = await (
        feedFuture,
        rankingsFuture,
        projectsFuture,
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
          authors.where((item) => item.username == id).firstOrNull ??
          authors.where((item) => item.id == id).firstOrNull;
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
  }) : posts = List.unmodifiable(posts),
       projects = List.unmodifiable(projects);

  final Author author;
  final List<FeedPost> posts;
  final List<ProjectItem> projects;
  final int? karma;
  final bool isSample;
}
