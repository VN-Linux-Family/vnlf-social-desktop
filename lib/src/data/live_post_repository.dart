import '../core/api_client.dart';
import '../domain/models.dart';
import '../domain/repositories.dart';
import 'feed_dto.dart';

final class LivePostRepository implements PostRepository {
  LivePostRepository(this._client, [PostRepository? fallback]);
  final ApiClient _client;

  @override
  Future<FeedPost?> getPost(String id) => _client.get<FeedPost>(
    '/api/v1/articles/${Uri.encodeComponent(id)}',
    decode: (json) => FeedPostDto.fromJson(json).toDomain(),
  );
}
