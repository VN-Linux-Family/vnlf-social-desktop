import '../../../domain/models.dart';

final class ArticleComment {
  const ArticleComment({
    required this.id,
    required this.content,
    required this.author,
    this.parentId,
    this.createdAt,
    this.voteScore = 0,
    this.viewerVote = 0,
    this.canEdit = false,
    this.canDelete = false,
  });
  final String id;
  final String content;
  final Author author;
  final String? parentId;
  final DateTime? createdAt;
  final int voteScore;
  final int viewerVote;
  final bool canEdit;
  final bool canDelete;
}

abstract interface class CommentsRepository {
  Future<List<ArticleComment>> load(String articleId);
  Future<ArticleComment> create(
    String articleId,
    String content, {
    String? parentId,
    String? clientCommentId,
  });
}
