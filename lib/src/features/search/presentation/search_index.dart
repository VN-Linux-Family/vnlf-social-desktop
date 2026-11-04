import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../domain/models.dart';
import '../../leaderboard/presentation/leaderboard_screen.dart';
import '../../projects/presentation/projects_screen.dart';
import '../../shared/presentation/feature_samples.dart';

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
  );
});

class SearchIndex {
  SearchIndex({
    required List<FeedPost> posts,
    required List<ProjectItem> projects,
    required List<Author> users,
  }) : posts = List.unmodifiable(posts),
       projects = List.unmodifiable(projects),
       users = List.unmodifiable(users);

  final List<FeedPost> posts;
  final List<ProjectItem> projects;
  final List<Author> users;

  SearchIndex matching(String query) {
    final normalized = query.trim().toLowerCase();
    bool contains(Iterable<String> values) =>
        values.any((value) => value.toLowerCase().contains(normalized));
    return SearchIndex(
      posts: posts
          .where(
            (post) => contains([
              post.title ?? '',
              post.excerpt,
              post.contentText,
              ...post.tags,
              post.author.displayName,
              post.author.username,
            ]),
          )
          .toList(),
      projects: projects
          .where(
            (project) => contains([
              project.name,
              project.tagline,
              project.type,
              project.repo?['language'] as String? ?? '',
            ]),
          )
          .toList(),
      users: users
          .where(
            (user) => contains([
              user.username,
              user.displayName,
              user.style?.distroBadge ?? '',
            ]),
          )
          .toList(),
    );
  }
}
