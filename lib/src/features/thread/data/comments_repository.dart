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
    canPin: boolValue(json['canPin'], 'comment.canPin'),
    pinned: boolValue(json['pinned'], 'comment.pinned'),
    editedAt: dateValue(json['editedAt'], 'comment.editedAt'),
    attachments: List.unmodifiable(
      objectList(json['attachments'], 'comment.attachments').map(
        (a) => ArticleAttachment(
          id: stringValue(a['id'], 'attachment.id'),
          url: stringValue(a['url'], 'attachment.url'),
          mime: stringValue(a['mime'], 'attachment.mime'),
          width: nullableInt(a['width'], 'attachment.width'),
          height: nullableInt(a['height'], 'attachment.height'),
        ),
      ),
    ),
    gif: _gif(json['gif']),
  );
}

CommentGif? _gif(Object? raw) {
  final json = objectValue(raw, 'comment.gif');
  if (json == null) return null;
  return CommentGif(
    url: stringValue(json['url'], 'gif.url'),
    title: stringValue(json['title'], 'gif.title'),
    provider: stringValue(json['provider'], 'gif.provider'),
    id: stringValue(json['id'], 'gif.id'),
    packSlug: stringValue(json['packSlug'], 'gif.packSlug'),
    hidden: boolValue(json['hidden'], 'gif.hidden'),
    width: nullableInt(json['width'], 'gif.width'),
    height: nullableInt(json['height'], 'gif.height'),
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
    refresh: true,
    decode: (json) => List.unmodifiable(
      objectList(json['items'], 'comments.items').map(commentFromJson),
    ),
  );

  String _commentPath(String id) =>
      '/api/v1/comments/${Uri.encodeComponent(id)}';
  @override
  Future<ArticleComment> edit(String commentId, String content) async {
    if (content.length > 4000) throw const ParseFailure('comment.content');
    final comment = await _client.request(
      'PATCH',
      _commentPath(commentId),
      body: jsonEncode({'content': content}),
      decode: commentFromJson,
    );
    _client.clearCache();
    return comment;
  }

  @override
  Future<void> delete(String commentId) async {
    await _client.request(
      'DELETE',
      _commentPath(commentId),
      decode: (json) {
        if (json['ok'] != true) throw const ParseFailure('comment.deleteAck');
        return true;
      },
    );
    _client.clearCache();
  }

  @override
  Future<CommentVote> vote(String commentId, int value) async {
    if (![-1, 0, 1].contains(value)) throw const ParseFailure('comment.vote');
    final vote = await _client.request(
      'PUT',
      '${_commentPath(commentId)}/vote',
      body: jsonEncode({'value': value}),
      decode: (json) {
        if (json['voteScore'] is! int ||
            json['viewerVote'] is! int ||
            ![-1, 0, 1].contains(json['viewerVote'])) {
          throw const ParseFailure('comment.voteAck');
        }
        return CommentVote(json['voteScore'] as int, json['viewerVote'] as int);
      },
    );
    _client.clearCache();
    return vote;
  }

  @override
  Future<void> pin(String articleId, String? commentId) async {
    await _client.request(
      'PUT',
      '/api/v1/articles/${Uri.encodeComponent(articleId)}/pinned-comment',
      body: jsonEncode({'commentId': commentId}),
      decode: (json) {
        if (!json.containsKey('pinnedCommentId') ||
            json['pinnedCommentId'] != commentId) {
          throw const ParseFailure('comment.pinAck');
        }
        return true;
      },
    );
    _client.clearCache();
  }

  @override
  Future<ArticleComment> create(
    String articleId,
    String content, {
    String? parentId,
    String? clientCommentId,
  }) async {
    final result = await _client.request<ArticleComment>(
      'POST',
      _path(articleId),
      body: jsonEncode({
        'content': content,
        'parentId': ?parentId,
        'clientCommentId': ?clientCommentId,
      }),
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

  (List<ArticleComment>, int) _find(String id) {
    for (final items in _articles.values) {
      final index = items.indexWhere((c) => c.id == id);
      if (index >= 0) return (items, index);
    }
    throw const HttpFailure(404);
  }

  @override
  Future<ArticleComment> edit(String commentId, String content) async {
    final (items, index) = _find(commentId);
    final old = items[index];
    return items[index] = ArticleComment(
      id: old.id,
      content: content,
      author: old.author,
      parentId: old.parentId,
      createdAt: old.createdAt,
      editedAt: DateTime.now(),
      voteScore: old.voteScore,
      viewerVote: old.viewerVote,
      canEdit: true,
      canDelete: true,
      pinned: old.pinned,
      canPin: old.canPin,
      attachments: old.attachments,
      gif: old.gif,
    );
  }

  @override
  Future<void> delete(String commentId) async {
    final (items, index) = _find(commentId);
    items.removeAt(index);
  }

  @override
  Future<CommentVote> vote(String commentId, int value) async {
    final (items, index) = _find(commentId);
    final old = items[index];
    final score = old.voteScore - old.viewerVote + value;
    items[index] = old.copyWith(voteScore: score, viewerVote: value);
    return CommentVote(score, value);
  }

  @override
  Future<void> pin(String articleId, String? commentId) async {
    await load(articleId);
    final items = _articles[articleId]!;
    if (commentId != null &&
        !items.any((c) => c.id == commentId && c.parentId == null)) {
      throw const HttpFailure(404);
    }
    for (var i = 0; i < items.length; i++) {
      items[i] = items[i].copyWith(pinned: items[i].id == commentId);
    }
  }

  @override
  Future<ArticleComment> create(
    String articleId,
    String content, {
    String? parentId,
    String? clientCommentId,
  }) async {
    await load(articleId);
    final result = ArticleComment(
      id: 'fixture-comment-${++_nextId}',
      content: content,
      parentId: parentId,
      createdAt: DateTime.now(),
      author: const Author(username: 'fixture', displayName: 'Bạn'),
      canEdit: true,
      canDelete: true,
    );
    _articles[articleId]!.add(result);
    return result;
  }
}
