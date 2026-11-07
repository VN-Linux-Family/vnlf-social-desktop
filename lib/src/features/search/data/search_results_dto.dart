import '../../../data/feed_dto.dart';
import '../../../data/field_reader.dart';
import '../../../data/profile_dto.dart';
import '../../../data/projects_dto.dart';
import '../domain/search_results.dart';

final class SearchResultsDto {
  const SearchResultsDto(this._json);
  final Map<String, dynamic> _json;

  SearchResults toDomain() {
    final more = objectValue(_json['hasMore'], 'search.hasMore');
    final users = objectList(_json['users'], 'search.users');
    return SearchResults(
      posts: objectList(_json['articles'], 'search.articles').map((article) {
        // Search returns a flat author projection, unlike feed items.
        return FeedPostDto.fromJson({
          ...article,
          'author': {
            'id': article['authorId'],
            'username': article['username'],
            'displayName': article['displayName'],
            'avatarUrl': article['avatarUrl'],
            'style': article['style'],
          },
        }).toDomain();
      }).toList(),
      projects: objectList(
        _json['projects'],
        'search.projects',
      ).map((item) => ProjectItemDto.fromJson(item).toDomain()).toList(),
      users: users.map((item) => ProfileDto.fromJson(item).toDomain()).toList(),
      biographies: {
        for (final user in users)
          stringValue(user['username'], 'search.user.username'): stringValue(
            user['bio'],
            'search.user.bio',
          ),
      },
      topics: objectList(
        _json['tags'],
        'search.tags',
      ).map(topicFromJson).toList(),
      hasMore: {
        for (final entry in const {
          'articles': SearchScope.posts,
          'projects': SearchScope.projects,
          'users': SearchScope.users,
          'tags': SearchScope.topics,
        }.entries)
          if (boolValue(more?[entry.key], 'search.hasMore.${entry.key}'))
            entry.value,
      },
    );
  }
}

SearchTopic topicFromJson(Map<String, dynamic> json) => SearchTopic(
  name: stringValue(json['name'], 'tag.name'),
  slug: stringValue(json['slug'], 'tag.slug'),
  count: nullableInt(json['count'], 'tag.count'),
);
