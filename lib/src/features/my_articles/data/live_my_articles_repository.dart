import '../../../core/api_client.dart';
import '../../../data/feed_dto.dart';
import '../../../domain/models.dart';
import '../domain/my_articles.dart';

/// The calls the website's `MyArticlesView` makes
/// (`article-context.tsx`). Writes are never retried.
final class LiveMyArticlesRepository implements MyArticlesRepository {
  const LiveMyArticlesRepository(this._client);
  final ApiClient _client;

  @override
  Future<List<FeedPost>> drafts() => _list(const {'status': 'DRAFT'});

  @override
  Future<List<FeedPost>> all() => _list(const {});

  Future<List<FeedPost>> _list(Map<String, String> query) => _client.get(
    '/api/v1/me/articles',
    query: query,
    refresh: true,
    decode: (json) => FeedPageDto.fromJson(json).toDomain().items,
  );

  @override
  Future<void> archive(String id) => _client.request<void>(
    'POST',
    '/api/v1/articles/${Uri.encodeComponent(id)}/archive',
  );

  @override
  Future<void> restore(String id) => _client.request<void>(
    'POST',
    '/api/v1/articles/${Uri.encodeComponent(id)}/restore',
  );
}
