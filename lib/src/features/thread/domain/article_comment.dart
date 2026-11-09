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
    this.canPin = false,
    this.pinned = false,
    this.editedAt,
    this.attachments = const [],
    this.gif,
    this.mentions = const [],
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
  final bool canPin;
  final bool pinned;
  final DateTime? editedAt;
  final List<ArticleAttachment> attachments;
  final CommentGif? gif;

  /// Usernames the server matched to @mentions in [content].
  final List<String> mentions;
  ArticleComment copyWith({int? voteScore, int? viewerVote, bool? pinned}) =>
      ArticleComment(
        id: id,
        content: content,
        author: author,
        parentId: parentId,
        createdAt: createdAt,
        voteScore: voteScore ?? this.voteScore,
        viewerVote: viewerVote ?? this.viewerVote,
        canEdit: canEdit,
        canDelete: canDelete,
        canPin: canPin,
        pinned: pinned ?? this.pinned,
        editedAt: editedAt,
        attachments: attachments,
        gif: gif,
        mentions: mentions,
      );
}

final class CommentGif {
  const CommentGif({
    required this.url,
    required this.title,
    required this.provider,
    this.hidden = false,
    this.width,
    this.height,
    this.id = '',
    this.packSlug = '',
    this.kind = '',
  });
  final String url, title, provider, id, packSlug;

  /// `sticker` for stickers; empty for GIFs.
  final String kind;

  bool get isSticker => provider == 'VNLF' || kind == 'sticker';
  final bool hidden;
  final int? width, height;
}

final class CommentVote {
  const CommentVote(this.score, this.value);
  final int score, value;
}

abstract interface class CommentsRepository {
  Future<List<ArticleComment>> load(String articleId);
  Future<ArticleComment> edit(String commentId, String content);
  Future<void> delete(String commentId);
  Future<CommentVote> vote(String commentId, int value);
  Future<void> pin(String articleId, String? commentId);
  Future<ArticleComment> create(
    String articleId,
    String content, {
    String? parentId,
    String? clientCommentId,
    List<String> attachmentIds = const [],

    /// The website's `gif` attachment: a KLIPY GIF or sticker, or a VNLF
    /// sticker.
    Map<String, Object>? gif,
  });
}
