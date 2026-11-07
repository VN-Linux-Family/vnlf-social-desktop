import 'dart:convert';

import '../../../core/api_client.dart';
import '../../../core/request_identity.dart';
import '../domain/article_comment.dart';
import '../domain/comment_upload.dart';
import 'comment_media_repository.dart';
import 'comment_pending_store.dart';

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
  CommentAttachmentController(this.articleId, this._media, this._comments, ApiClient client, {CommentPendingStore? store, String? ownerId})
      : _session = client.captureSession(), _store = store, _ownerId = ownerId;
  final CommentPendingStore? _store;
  final String? _ownerId;
  Future<void>? _initialization;
  PendingComment? _pending;
  PendingComment? get pending => _pending;
  Future<void> initialize() => _initialization ??= _restore();
  Future<void> _restore() async {
    if (_store == null) return;
    final pending = await _store.read(_ownerId!, articleId);
    _session.ensureCurrent();
    _pending = pending;
    if (pending != null) {
      _signature = jsonEncode([pending.content, pending.parentId, pending.attachmentIds]);
      _identity = pending.identity;
    }
  }
  final String articleId;
  final CommentMediaRepository _media;
  final CommentsRepository _comments;
  final ApiSessionScope _session;
  final List<CommentAttachment> _items = [];
  bool _submitting = false;
  String? _signature;
  String? _identity;

  bool get submissionPending => _signature != null;

  List<CommentAttachment> get attachments => List.unmodifiable(_items);
  List<String> get readyIds => _pending?.attachmentIds ?? List.unmodifiable(_items.where((item) => item.state == CommentAttachmentState.ready).map((item) => item.assetId!));

  CommentAttachment add(CommentUploadFile file) {
    _session.ensureCurrent();
    if (_submitting || submissionPending || _items.length >= 10) throw StateError('Attachment limit or submission in progress');
    final item = CommentAttachment._(file, _media.begin(articleId, file));
    _items.add(item);
    return item;
  }

  void remove(CommentAttachment item) {
    _session.ensureCurrent();
    if (_submitting || submissionPending || item.state == CommentAttachmentState.presigning || item.state == CommentAttachmentState.uploading || item.state == CommentAttachmentState.completing) {
      throw StateError('Operation in progress');
    }
    if (!_items.remove(item)) throw StateError('Unknown attachment');
  }

  Future<void> upload(CommentAttachment item, {void Function()? onChange}) async {
    _check(item, CommentAttachmentState.selected);
    item.state = CommentAttachmentState.presigning;
    onChange?.call();
    try {
      await item.transfer.presign();
    } catch (error) {
      item.error = error;
      item.state = CommentAttachmentState.presignFailed;
      onChange?.call();
      rethrow;
    }
    item.state = CommentAttachmentState.uploading;
    onChange?.call();
    try {
      await item.transfer.put();
    } catch (error) {
      item.error = error;
      item.state = CommentAttachmentState.uploadFailed;
      onChange?.call();
      rethrow;
    }
    await _complete(item, onChange);
  }

  Future<void> retryCompletion(CommentAttachment item, {void Function()? onChange}) async {
    _check(item, CommentAttachmentState.completeFailed);
    await _complete(item, onChange);
  }

  Future<void> _complete(CommentAttachment item, void Function()? onChange) async {
    item.state = CommentAttachmentState.completing;
    onChange?.call();
    item.error = null;
    try {
      await item.transfer.complete();
      item.state = CommentAttachmentState.ready;
      onChange?.call();
    } catch (error) {
      item.error = error;
      item.state = CommentAttachmentState.completeFailed;
      onChange?.call();
      rethrow;
    }
  }

  void _check(CommentAttachment item, CommentAttachmentState state) {
    _session.ensureCurrent();
    if (_submitting || submissionPending || !_items.contains(item) || item.state != state) throw StateError('Attachment unavailable');
  }

  /// The same payload keeps the same identity after an uncertain response.
  Future<ArticleComment> submit(String content, {String? parentId}) async {
    await initialize();
    _session.ensureCurrent();
    if (_submitting || _items.any((item) => item.state != CommentAttachmentState.ready)) throw StateError('Attachments not ready');
    final text = content.trim();
    final ids = readyIds;
    if ((text.isEmpty && ids.isEmpty) || text.length > 4000) throw const ParseFailure('comment.content');
    final signature = jsonEncode([text, parentId, ids]);
    if (_signature != null && _signature != signature) {
      throw StateError('Resolve the pending submission before changing the draft');
    }
    final hadUncertainAttempt = _signature != null;
    _signature ??= signature;
    _identity ??= newRequestIdentity();
    _submitting = true;
    final payload = PendingComment(identity: _identity!, content: text, parentId: parentId, attachmentIds: ids);
    try {
      if (_store != null && !hadUncertainAttempt) {
        await _store.write(_ownerId!, articleId, payload);
        _session.ensureCurrent();
      }
      _pending = payload;
      final result = await _comments.create(articleId, text, parentId: parentId, attachmentIds: ids, clientCommentId: _identity);
      _session.ensureCurrent();
      if (result.content != text || result.parentId != parentId ||
          jsonEncode(result.attachments.map((item) => item.id).toList()) != jsonEncode(ids)) {
        throw const ParseFailure('comment.createAck');
      }
      if (_store != null) await _store.clear(_ownerId!, articleId);
      _session.ensureCurrent();
      _pending = null;
      _items.clear();
      _signature = null;
      _identity = null;
      return result;
    } on HttpFailure catch (error) {
      // These source-defined errors happen before the comment transaction.
      final rejected = (error.statusCode == 400 && const {
        'COMMENT_EMPTY', 'COMMENT_ATTACHMENTS_INVALID', 'COMMENT_REPLY_DEPTH',
      }.contains(error.code)) ||
          (error.statusCode == 404 && error.code == 'ARTICLE_NOT_FOUND');
      if (!hadUncertainAttempt && rejected) {
        if (_store != null) await _store.clear(_ownerId!, articleId);
        _pending = null;
        _signature = null;
        _identity = null;
      }
      rethrow;
    } finally {
      _submitting = false;
    }
  }
}
