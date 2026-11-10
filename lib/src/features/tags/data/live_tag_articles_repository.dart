import '../../../core/api_client.dart';
import '../../../data/feed_dto.dart';
import '../../../data/field_reader.dart';
import '../domain/tag_articles.dart';

/// `GET /api/v1/tags/:slug/articles?limit=30[&cursor=]`, as the website's
/// tag page (`app/(social)/t/[tag]/page.tsx`) reads it.
final class LiveTagArticlesRepository implements TagArticlesRepository {
  const LiveTagArticlesRepository(this._client);
  final ApiClient _client;

  @override
  Future<TagArticlesPage?> page(String slug, {String? cursor}) async {
    try {
      return await _client.get(
        '/api/v1/tags/${Uri.encodeComponent(slug)}/articles',
        query: {'limit': '30', 'cursor': ?cursor},
        decode: (json) {
          final tag = objectValue(json['tag'], 'tag') ?? const {};
          final page = FeedPageDto.fromJson(json).toDomain();
          return TagArticlesPage(
            name: stringValue(tag['name'], 'tag.name'),
            total: nullableInt(json['total'], 'total'),
            items: page.items,
            nextCursor: page.nextCursor,
          );
        },
      );
    } on HttpFailure catch (failure) {
      if (failure.statusCode == 404) return null;
      rethrow;
    }
  }
}
