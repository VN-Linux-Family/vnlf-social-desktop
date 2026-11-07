import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../domain/models.dart';
import '../../leaderboard/presentation/leaderboard_screen.dart';
import '../../projects/presentation/projects_screen.dart';
import '../../shared/presentation/feature_samples.dart';
import '../domain/search_results.dart';

final searchIndexProvider = FutureProvider.autoDispose<SearchIndex>((
  ref,
) async {
  final feed = ref.watch(feedProvider(null).future);
  final projects = ref.watch(projectsProvider.future);
  final rankings = ref.watch(leaderboardProvider.future);
  final pages = await Future.wait<Object>([feed, projects, rankings]);
  final posts = (pages[0] as FeedPage).items;
  final projectItems = (pages[1] as ProjectsPage).items;
  final rankingItems = (pages[2] as LeaderboardPage).items;
  final allPosts = [
    ...posts,
    if (offlineFeatures && !posts.any((post) => post.id == samplePost.id))
      samplePost,
  ];
  final users = <String, Author>{};
  for (final author in [
    ...allPosts.map((post) => post.author),
    ...projectItems.map((project) => project.owner).whereType<Author>(),
    ...rankingItems.map(
      (item) => Author(
        id: item.userId,
        username: item.username,
        displayName: item.displayName,
        avatarUrl: item.avatarUrl,
        style: item.style,
      ),
    ),
  ]) {
    users[author.username] = author;
  }
  return SearchIndex(
    posts: allPosts,
    projects: projectItems,
    users: users.values.toList(),
    topics: const [SearchTopic(name: 'Wayland', slug: 'wayland')],
  );
});

typedef SearchIndex = SearchResults;
