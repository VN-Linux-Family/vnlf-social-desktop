import 'dart:convert';

import '../../../core/api_client.dart';
import '../../../data/field_reader.dart';
import '../../../data/profile_dto.dart';
import '../../../domain/models.dart';
import '../domain/article_comment.dart';

ArticleComment commentFromJson(Map<String, dynamic> json) {
  final id = stringValue(json['id'], 'comment.id');
  if (id.isEmpty) throw const ParseFailure('comment.id');
  return ArticleComment(
    id: id,
    content: stringValue(json['content'], 'comment.content'),
    parentId: nullableString(json['parentId'], 'comment.parentId'),
    author: ProfileDto.fromJson(
      objectValue(json['author'], 'comment.author') ?? {},
    ).toDomain(),
    createdAt: dateValue(json['createdAt'], 'comment.createdAt'),
    voteScore: intValue(json['voteScore'], 'comment.voteScore'),
    viewerVote: intValue(json['viewerVote'], 'comment.viewerVote'),
    canEdit: boolValue(json['canEdit'], 'comment.canEdit'),
    canDelete: boolValue(json['canDelete'], 'comment.canDelete'),
  );
}

final class LiveCommentsRepository implements CommentsRepository {
  LiveCommentsRepository(this._client);
  final ApiClient _client;
  String _path(String id) =>
      '/api/v1/articles/${Uri.encodeComponent(id)}/comments';

  @override
  Future<List<ArticleComment>> load(String articleId) => _client.get(
    _path(articleId),
    decode: (json) => List.unmodifiable(
      objectList(json['items'], 'comments.items').map(commentFromJson),
    ),
  );

  @override
  Future<ArticleComment> create(
    String articleId,
    String content, {
    String? parentId,
  }) async {
    final result = await _client.request<ArticleComment>(
      'POST',
      _path(articleId),
      body: jsonEncode({'content': content, 'parentId': ?parentId}),
      decode: commentFromJson,
    );
    _client.clearCache();
    return result;
  }
}

/// Explicit offline fixture with state scoped to the provider container.
final class FixtureCommentsRepository implements CommentsRepository {
  final _articles = <String, List<ArticleComment>>{};
  int _nextId = 0;

  @override
  Future<List<ArticleComment>> load(String articleId) async =>
      List.unmodifiable(
        _articles.putIfAbsent(
          articleId,
          () => [
            const ArticleComment(
              id: 'fixture-comment',
              content: 'Cảm ơn bạn đã chia sẻ cùng cộng đồng!',
              author: Author(username: 'thanhvien', displayName: 'Thành viên'),
            ),
          ],
        ),
      );

  @override
  Future<ArticleComment> create(
    String articleId,
    String content, {
    String? parentId,
  }) async {
    await load(articleId);
    final result = ArticleComment(
      id: 'fixture-comment-${++_nextId}',
      content: content,
      parentId: parentId,
      createdAt: DateTime.now(),
      author: const Author(username: 'fixture', displayName: 'Bạn'),
    );
    _articles[articleId]!.add(result);
    return result;
  }
}
