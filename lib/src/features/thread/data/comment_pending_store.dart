import 'dart:async';
import 'dart:convert';

import '../../../core/session_storage_contract.dart';
import '../../../core/api_client.dart';

final class PendingComment {
  const PendingComment({required this.identity, required this.content, required this.parentId, required this.attachmentIds});
  final String identity;
  final String content;
  final String? parentId;
  final List<String> attachmentIds;
}

/// Only the payload and deduplication key are stored; no files or upload URLs.
final class CommentPendingStore {
  const CommentPendingStore(this._storage);
  final SessionStorage _storage;
  static final Map<String, Future<void>> _operations = {};
  Future<T> _serial<T>(String key, Future<T> Function() action) async {
    final previous = _operations[key];
    final done = Completer<void>();
    _operations[key] = done.future;
    try {
      if (previous != null) await previous;
      return await action();
    } finally {
      if (identical(_operations[key], done.future)) _operations.remove(key);
      done.complete();
    }
  }
  String _key(String owner, String article) {
    if (owner.isEmpty || article.isEmpty) throw const ParseFailure('comment.pending.scope');
    return 'vnlf.comment.pending.${Uri.encodeComponent(owner)}.${Uri.encodeComponent(article)}';
  }

  Future<PendingComment?> read(String owner, String article) async {
    final key = _key(owner, article);
    final raw = await _serial(key, () => _storage.read(key));
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final identity = json['identity'] as String;
      final content = json['content'] as String;
      final parent = json['parentId'] as String?;
      final ids = (json['attachmentIds'] as List).cast<String>();
      if (json['schema'] != 1 || identity.isEmpty || content.length > 4000 || ids.length > 10 || ids.any((id) => id.isEmpty) || (content.isEmpty && ids.isEmpty)) throw const FormatException();
      return PendingComment(identity: identity, content: content, parentId: parent, attachmentIds: List.unmodifiable(ids));
    } catch (_) {
      throw const ParseFailure('comment.pending');
    }
  }

  String _encode(PendingComment pending) => jsonEncode({
    'schema': 1, 'identity': pending.identity, 'content': pending.content,
    'parentId': pending.parentId, 'attachmentIds': pending.attachmentIds,
  });

  Future<void> write(String owner, String article, PendingComment pending) {
    final key = _key(owner, article);
    return _serial(key, () async {
      final existing = await _storage.read(key);
      final encoded = _encode(pending);
      if (existing != null && existing != encoded) throw const ParseFailure('comment.pending.exists');
      if (existing == null) await _storage.write(key, encoded);
      if (await _storage.read(key) != encoded) throw const ParseFailure('comment.pending.reservation');
    });
  }

  Future<void> verify(String owner, String article, PendingComment pending) {
    final key = _key(owner, article);
    return _serial(key, () async {
      if (await _storage.read(key) != _encode(pending)) throw const ParseFailure('comment.pending.reservation');
    });
  }
  Future<void> clear(String owner, String article, PendingComment pending) {
    final key = _key(owner, article);
    return _serial(key, () async {
      if (await _storage.read(key) != _encode(pending)) throw const ParseFailure('comment.pending.reservation');
      await _storage.delete(key);
    });
  }
}
