import '../core/api_client.dart';
import '../domain/models.dart';
import '../domain/repositories.dart';
import 'feed_dto.dart';

final _articleId = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

final class LivePostRepository implements PostRepository {
  LivePostRepository(this._client);
  final ApiClient _client;

  /// `GET /api/v1/articles/:id` only matches UUIDs, so public links resolve
  /// through `GET /api/v1/articles/slug/:slug`, which also follows old slugs.
  @override
  Future<FeedPost?> getPost(String idOrSlug) => _client.get<FeedPost>(
    _articleId.hasMatch(idOrSlug)
        ? '/api/v1/articles/${Uri.encodeComponent(idOrSlug)}'
        : '/api/v1/articles/slug/${Uri.encodeComponent(idOrSlug)}',
    decode: (json) => FeedPostDto.fromJson(json).toDomain(),
  );
}
