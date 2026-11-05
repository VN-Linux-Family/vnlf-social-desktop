import '../core/api_client.dart';
import '../domain/models.dart';
import '../domain/repositories.dart';
import 'field_reader.dart';

final class LivePostRepository implements PostRepository {
  LivePostRepository(this._client, this._fallback);

  final ApiClient _client;
  final PostRepository _fallback;

  @override
  Future<FeedPost?> getPost(String id) async {
    try {
      return await _client.get<FeedPost?>(
        '/api/v1/articles/$id',
        decode: (json) {
          final authorMap = json['author'] is Map<String, dynamic>
              ? json['author'] as Map<String, dynamic>
              : null;
          final excerpt =
              json['contentText'] as String? ??
              json['excerpt'] as String? ??
              json['title'] as String? ??
              '';
          return FeedPost(
            id: json['id'] as String? ?? id,
            excerpt: excerpt,
            title: json['title'] as String?,
            voteScore: json['voteScore'] as int? ?? 0,
            commentCount: json['commentCount'] as int? ?? 0,
            author: Author(
              id:
                  authorMap?['id'] as String? ??
                  json['authorId'] as String? ??
                  '',
              username:
                  authorMap?['username'] as String? ??
                  json['username'] as String? ??
                  '',
              displayName:
                  authorMap?['displayName'] as String? ??
                  authorMap?['username'] as String? ??
                  '',
              avatarUrl:
                  authorMap?['avatarUrl'] as String? ??
                  json['avatarUrl'] as String? ??
                  '',
              style: styleValue(
                authorMap?['style'] ?? json['style'],
                'article.style',
              ),
            ),
          );
        },
      );
    } catch (_) {
      return _fallback.getPost(id);
    }
  }
}
