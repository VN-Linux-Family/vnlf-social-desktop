import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../../core/api_client.dart';
import '../../../data/field_reader.dart';
import '../domain/comment_upload.dart';

const int maxCommentImageBytes = 10 * 1024 * 1024;

const Set<String> allowedCommentImageMimes = <String>{
  'image/jpeg',
  'image/png',
  'image/webp',
  'image/gif',
};

typedef CommentAssetUpload = Future<void> Function(
  Uri url,
  CommentUploadFile file,
  Map<String, String> headers,
);

final class CommentMediaRepository {
  CommentMediaRepository(this._client, {CommentAssetUpload? upload})
    : _upload = upload ?? _uploadNative;

  static final RegExp _safeAssetIdPattern = RegExp(r'^[a-zA-Z0-9_-]{1,128}$');
  static final RegExp _headerName = RegExp(r"^[!#\$%&'*+.^_`|~0-9A-Za-z-]+$");

  final ApiClient _client;
  final CommentAssetUpload _upload;

  CommentMediaTransfer begin(String articleId, CommentUploadFile file) =>
      CommentMediaTransfer._(this, articleId, file, _client.captureSession());

  Future<CommentUploadedAsset> upload(String articleId, CommentUploadFile file) async {
    final transfer = begin(articleId, file);
    await transfer.presign();
    await transfer.put();
    return transfer.complete();
  }
}

/// One owner-bound transfer. Every write must be explicitly initiated by the caller.
final class CommentMediaTransfer {
  CommentMediaTransfer._(this._repository, this.articleId, this.file, this._session);
  final CommentMediaRepository _repository;
  final String articleId;
  final CommentUploadFile file;
  final ApiSessionScope _session;
  void ensureCurrent() => _session.ensureCurrent();
  String? _assetId;
  String? get assetId => _assetId;
  bool _completed = false;
  Uri? _uploadUri;
  Map<String, String>? _uploadHeaders;
  bool _presignAttempted = false;
  bool _putAttempted = false;
  bool _putAcknowledged = false;
  bool _busy = false;

  Future<void> presign() async {
    if (_presignAttempted || _busy) throw StateError('Presign already attempted');
    _session.ensureCurrent();
    final name = file.name.trim();
    final mime = file.mime.trim().toLowerCase();
    if (name.isEmpty || name.length > 255) {
      throw const ParseFailure('upload.fileName');
    }
    if (!allowedCommentImageMimes.contains(mime)) {
      throw const ParseFailure('upload.mime');
    }
    if (file.length < 1 || file.length > maxCommentImageBytes) {
      throw const ParseFailure('upload.size');
    }

    _presignAttempted = true;
    _busy = true;
    try {
    final presign = await _repository._client.request<Map<String, dynamic>>(
      'POST',
      '/api/v1/articles/${Uri.encodeComponent(articleId)}/comment-assets/presign',
      body: jsonEncode(<String, Object?>{
        'fileName': name,
        'mime': mime,
        'size': file.length,
      }),
    );
    final id = stringValue(presign['assetId'], 'upload.assetId');
    if (_safeId(id)) _assetId = id;
    final uploadUrl = stringValue(presign['uploadUrl'], 'upload.uploadUrl');
    final uploadUri = Uri.tryParse(uploadUrl);
    if (assetId == null ||
        uploadUri == null ||
        !uploadUri.hasScheme ||
        uploadUri.scheme != 'https' ||
        uploadUri.host.isEmpty ||
        uploadUri.userInfo.isNotEmpty ||
        uploadUri.hasFragment) {
      throw const ParseFailure('upload.presign');
    }

    final rawHeaders = objectValue(presign['headers'], 'upload.headers') ?? const <String, dynamic>{};
    final uploadHeaders = <String, String>{};
    for (final entry in rawHeaders.entries) {
      final name = entry.key;
      final lower = name.toLowerCase();
      final value = entry.value;
      if (!CommentMediaRepository._headerName.hasMatch(name) ||
          value is! String || value.contains('\r') || value.contains('\n') ||
          lower == 'cookie' || lower == 'authorization' ||
          lower == 'proxy-authorization' || lower == 'x-csrf-token' ||
          lower == 'host' || lower == 'content-length') {
        throw const ParseFailure('upload.headers');
      }
      uploadHeaders[name] = value;
    }

    _uploadUri = uploadUri;
    _uploadHeaders = Map.unmodifiable(uploadHeaders);
    _session.ensureCurrent();
    } finally {
      _busy = false;
    }
  }

  bool _safeId(String id) => CommentMediaRepository._safeAssetIdPattern.hasMatch(id);

  Future<void> put() async {
    if (_busy || _putAttempted || _uploadUri == null) throw StateError('Upload unavailable');
    _session.ensureCurrent();
    _putAttempted = true;
    _busy = true;
    try {
    final guardedFile = CommentUploadFile(
      name: file.name,
      mime: file.mime,
      length: file.length,
      openRead: () => file.openRead().map((chunk) {
        _session.ensureCurrent();
        return chunk;
      }),
    );
    await _repository._upload(_uploadUri!, guardedFile, _uploadHeaders!);
    _session.ensureCurrent();
    _putAcknowledged = true;
    } finally {
      _busy = false;
    }
  }

  /// Explicit retries are allowed only for completion after a confirmed PUT.
  Future<CommentUploadedAsset> complete() async {
    if (_busy || _completed || !_putAcknowledged || assetId == null) throw StateError('Completion unavailable');
    _session.ensureCurrent();
    _busy = true;
    try {
    final encodedAssetId = Uri.encodeComponent(assetId!);
    final completed = await _repository._client.request<Map<String, dynamic>>(
      'POST',
      '/api/v1/articles/${Uri.encodeComponent(articleId)}/comment-assets/$encodedAssetId/complete',
      body: jsonEncode(const <String, Object?>{}),
    );
    final completedId = stringValue(completed['assetId'], 'upload.assetId');
    final status = stringValue(completed['status'], 'upload.status');
    if (completedId != assetId || status != 'READY') {
      throw const ParseFailure('upload.complete');
    }

    _session.ensureCurrent();
    _completed = true;
    return CommentUploadedAsset(
      assetId: completedId,
      fileName: file.name.trim(),
      status: status,
      mime: file.mime.trim().toLowerCase(),
      size: file.length,
    );
    } finally {
      _busy = false;
    }
  }
}

Future<void> _uploadNative(
  Uri url,
  CommentUploadFile file,
  Map<String, String> headers,
) async {
  final client = HttpClient();
  try {
    final request = await client
        .putUrl(url)
        .timeout(const Duration(seconds: 30));
    request.followRedirects = false;
    request.headers.set(HttpHeaders.contentTypeHeader, file.mime);
    for (final entry in headers.entries) {
      request.headers.set(entry.key, entry.value);
    }
    request.contentLength = file.length;
    await request
        .addStream(file.openRead())
        .timeout(const Duration(minutes: 3));
    final response = await request.close().timeout(const Duration(seconds: 30));
    await response.drain<void>();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpFailure(response.statusCode);
    }
  } on AppFailure {
    rethrow;
  } catch (_) {
    throw const TransportFailure();
  } finally {
    client.close(force: true);
  }
}
