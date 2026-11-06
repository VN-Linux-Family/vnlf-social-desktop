import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../../core/api_client.dart';

const feedbackImageLimit = 10 * 1024 * 1024;
const feedbackVideoLimit = 50 * 1024 * 1024;
const feedbackMediaMimes = <String>{
  'image/jpeg', 'image/png', 'image/webp', 'image/gif',
  'video/mp4', 'video/webm',
};

final class FeedbackMediaFile {
  const FeedbackMediaFile({
    required this.name,
    required this.mime,
    required this.length,
    required this.openRead,
  });

  final String name;
  final String mime;
  final int length;
  final Stream<List<int>> Function() openRead;
}

typedef FeedbackMediaTransfer = Future<void> Function(
  Uri url,
  FeedbackMediaFile file,
  Map<String, String> headers,
);

/// A presigned asset remains bound to the session and submission that created it.
/// Keep this handle even if transfer or completion fails so the asset can be
/// explicitly deleted without issuing another presign.
final class PendingFeedbackMedia {
  const PendingFeedbackMedia._(this.assetId, this.submissionId, this._url,
      this._headers, this._file, this._session, this._owner);

  final String assetId;
  final String submissionId;
  final Uri _url;
  final Map<String, String> _headers;
  final FeedbackMediaFile _file;
  final ApiSessionScope _session;
  final FeedbackMediaRepository _owner;
}

final class FeedbackMediaRepository {
  FeedbackMediaRepository(this._client, {FeedbackMediaTransfer? upload})
      : _transfer = upload ?? _uploadNative;

  final ApiClient _client;
  final FeedbackMediaTransfer _transfer;
  static final _uuid = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
  static final _assetId = RegExp(r'^[a-zA-Z0-9_-]{1,80}$');
  static final _headerName = RegExp(r"^[!#\$%&'*+.^_`|~0-9a-zA-Z-]+$");

  Future<PendingFeedbackMedia> presign({
    required String submissionId,
    required FeedbackMediaFile file,
    String? kind,
  }) async {
    if (!_uuid.hasMatch(submissionId) ||
        (kind != null && kind != 'FEEDBACK' && kind != 'BUG')) {
      throw const ParseFailure('feedback.upload.input');
    }
    if (file.name.isEmpty || file.name.length > 255 ||
        !feedbackMediaMimes.contains(file.mime) || file.length < 1 ||
        file.length > (file.mime.startsWith('video/') ? feedbackVideoLimit : feedbackImageLimit)) {
      throw const ParseFailure('feedback.upload.file');
    }
    final session = _client.captureSession();
    final response = await _client.request<Map<String, dynamic>>(
      'POST', '/api/v1/feedback/assets/presign',
      body: jsonEncode({
        'clientSubmissionId': submissionId,
        if (kind != null) 'kind': kind,
        'fileName': file.name,
        'mime': file.mime,
        'size': file.length,
      }),
    );
    session.ensureCurrent();
    final asset = response['assetId'];
    final rawUrl = response['uploadUrl'];
    final uri = rawUrl is String ? Uri.tryParse(rawUrl) : null;
    final expires = response['expiresIn'];
    final rawHeaders = response['headers'];
    if (asset is! String || !_assetId.hasMatch(asset) || uri == null ||
        uri.scheme != 'https' || uri.host.isEmpty || uri.userInfo.isNotEmpty ||
        uri.hasFragment || expires is! int || expires <= 0 ||
        rawHeaders is! Map<String, dynamic>) {
      throw const ParseFailure('feedback.upload.presign');
    }
    final headers = <String, String>{};
    for (final entry in rawHeaders.entries) {
      final name = entry.key;
      final lower = name.toLowerCase();
      final value = entry.value;
      if (!_headerName.hasMatch(name) || value is! String ||
          value.contains('\r') || value.contains('\n') ||
          lower == 'cookie' || lower == 'authorization' ||
          lower == 'x-csrf-token' || lower == 'host' ||
          lower == 'content-length') {
        throw const ParseFailure('feedback.upload.headers');
      }
      headers[name] = value;
    }
    return PendingFeedbackMedia._(asset, submissionId, uri,
        Map.unmodifiable(headers), file, session, this);
  }

  void _check(PendingFeedbackMedia pending) {
    if (!identical(pending._owner, this)) {
      throw const ParseFailure('feedback.upload.owner');
    }
    pending._session.ensureCurrent();
  }

  Future<void> upload(PendingFeedbackMedia pending) async {
    _check(pending);
    final original = pending._file;
    final guarded = FeedbackMediaFile(
      name: original.name, mime: original.mime, length: original.length,
      openRead: () => original.openRead().map((chunk) {
        pending._session.ensureCurrent();
        return chunk;
      }),
    );
    await _transfer(pending._url, guarded, pending._headers);
    _check(pending);
  }

  Future<void> complete(PendingFeedbackMedia pending) async {
    _check(pending);
    final response = await _client.request<Map<String, dynamic>>(
      'POST', '/api/v1/feedback/assets/${Uri.encodeComponent(pending.assetId)}/complete',
      body: jsonEncode({'clientSubmissionId': pending.submissionId}),
    );
    _check(pending);
    if (response['assetId'] != pending.assetId || response['status'] != 'READY') {
      throw const ParseFailure('feedback.upload.complete');
    }
  }

  Future<void> delete(PendingFeedbackMedia pending) async {
    _check(pending);
    final response = await _client.request<Map<String, dynamic>>(
      'DELETE', '/api/v1/feedback/assets/${Uri.encodeComponent(pending.assetId)}',
      query: {'clientSubmissionId': pending.submissionId},
    );
    _check(pending);
    if (response['ok'] != true) throw const ParseFailure('feedback.upload.delete');
  }
}

Future<void> _uploadNative(Uri url, FeedbackMediaFile file,
    Map<String, String> headers) async {
  final client = HttpClient();
  try {
    final request = await client.putUrl(url).timeout(const Duration(seconds: 30));
    request.followRedirects = false;
    request.headers.set(HttpHeaders.contentTypeHeader, file.mime);
    for (final entry in headers.entries) {
      request.headers.set(entry.key, entry.value);
    }
    request.contentLength = file.length;
    await request.addStream(file.openRead()).timeout(const Duration(minutes: 3));
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
