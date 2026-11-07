import 'dart:convert';

import '../../../core/api_client.dart';
import '../../../core/request_identity.dart';
import '../domain/article_comment.dart';
import '../domain/comment_upload.dart';
import 'comment_media_repository.dart';

enum CommentAttachmentState { selected, presigning, presignFailed, uploading, uploadFailed, completing, completeFailed, ready }

final class CommentAttachment {
  CommentAttachment._(this.file, this.transfer);
  final CommentUploadFile file;
  final CommentMediaTransfer transfer;
  CommentAttachmentState state = CommentAttachmentState.selected;
  Object? error;
  String? get assetId => transfer.assetId;
}

/// A draft belongs to one article and the session active when it was created.
final class CommentAttachmentController {
  CommentAttachmentController(this.articleId, this._media, this._comments, ApiClient client)
      : _session = client.captureSession();
  final String articleId;
  final CommentMediaRepository _media;
  final CommentsRepository _comments;
  final ApiSessionScope _session;
  final List<CommentAttachment> _items = [];
  bool _submitting = false;
  String? _signature;
  String? _identity;

  List<CommentAttachment> get attachments => List.unmodifiable(_items);
  List<String> get readyIds => List.unmodifiable(_items.where((item) => item.state == CommentAttachmentState.ready).map((item) => item.assetId!));

  CommentAttachment add(CommentUploadFile file) {
    _session.ensureCurrent();
    if (_submitting || _items.length >= 10) throw StateError('Attachment limit or submission in progress');
    final item = CommentAttachment._(file, _media.begin(articleId, file));
    _items.add(item);
    return item;
  }

  void remove(CommentAttachment item) {
    _session.ensureCurrent();
    if (_submitting || item.state == CommentAttachmentState.presigning || item.state == CommentAttachmentState.uploading || item.state == CommentAttachmentState.completing) {
      throw StateError('Operation in progress');
    }
    if (!_items.remove(item)) throw StateError('Unknown attachment');
  }

  Future<void> upload(CommentAttachment item) async {
    _check(item, CommentAttachmentState.selected);
    item.state = CommentAttachmentState.presigning;
    try {
      await item.transfer.presign();
    } catch (error) {
      item.error = error;
      item.state = CommentAttachmentState.presignFailed;
      rethrow;
    }
    item.state = CommentAttachmentState.uploading;
    try {
      await item.transfer.put();
    } catch (error) {
      item.error = error;
      item.state = CommentAttachmentState.uploadFailed;
      rethrow;
    }
    await _complete(item);
  }

  Future<void> retryCompletion(CommentAttachment item) async {
    _check(item, CommentAttachmentState.completeFailed);
    await _complete(item);
  }

  Future<void> _complete(CommentAttachment item) async {
    item.state = CommentAttachmentState.completing;
    item.error = null;
    try {
      await item.transfer.complete();
      item.state = CommentAttachmentState.ready;
    } catch (error) {
      item.error = error;
      item.state = CommentAttachmentState.completeFailed;
      rethrow;
    }
  }

  void _check(CommentAttachment item, CommentAttachmentState state) {
    _session.ensureCurrent();
    if (_submitting || !_items.contains(item) || item.state != state) throw StateError('Attachment unavailable');
  }

  /// The same payload keeps the same identity after an uncertain response.
  Future<ArticleComment> submit(String content, {String? parentId}) async {
    _session.ensureCurrent();
    if (_submitting || _items.any((item) => item.state != CommentAttachmentState.ready)) throw StateError('Attachments not ready');
    final text = content.trim();
    final ids = readyIds;
    if ((text.isEmpty && ids.isEmpty) || text.length > 4000) throw const ParseFailure('comment.content');
    final signature = jsonEncode([text, parentId, ids]);
    if (_signature != signature) {
      _signature = signature;
      _identity = newRequestIdentity();
    }
    _submitting = true;
    try {
      final result = await _comments.create(articleId, text, parentId: parentId, attachmentIds: ids, clientCommentId: _identity);
      _session.ensureCurrent();
      _items.clear();
      _signature = null;
      _identity = null;
      return result;
    } finally {
      _submitting = false;
    }
  }
}
