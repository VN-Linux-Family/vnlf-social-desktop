import '../../../domain/models.dart';

enum SearchScope { all, posts, projects, users, topics }

final class SearchTopic {
  const SearchTopic({required this.name, required this.slug, this.count});
  final String name;
  final String slug;
  final int? count;
}

final class SearchResults {
  SearchResults({
    List<FeedPost> posts = const [],
    List<ProjectItem> projects = const [],
    List<Author> users = const [],
    List<SearchTopic> topics = const [],
    Map<String, String> biographies = const {},
    Set<SearchScope> hasMore = const {},
  }) : posts = List.unmodifiable(posts),
       projects = List.unmodifiable(projects),
       users = List.unmodifiable(users),
       topics = List.unmodifiable(topics),
       biographies = Map.unmodifiable(biographies),
       hasMore = Set.unmodifiable(hasMore);

  final List<FeedPost> posts;
  final List<ProjectItem> projects;
  final List<Author> users;
  final List<SearchTopic> topics;
  final Map<String, String> biographies;
  final Set<SearchScope> hasMore;

  SearchResults matching(String query) {
    final normalized = query.trim().toLowerCase();
    bool contains(Iterable<String> values) =>
        values.any((value) => value.toLowerCase().contains(normalized));
    return SearchResults(
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
      topics: topics
          .where((topic) => contains([topic.name, topic.slug]))
          .toList(),
      biographies: biographies,
    );
  }
}

abstract interface class SearchRepository {
  Future<SearchResults> search(String query);
  Future<List<SearchTopic>> popularTopics();
}
