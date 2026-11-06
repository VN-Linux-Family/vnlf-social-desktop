import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../../core/api_client.dart';
import '../../../data/field_reader.dart';
import '../domain/direct_message_models.dart';

const int maxDmImageBytes = 10 * 1024 * 1024;

const Set<String> allowedDmImageMimes = <String>{
  'image/jpeg',
  'image/png',
  'image/webp',
  'image/gif',
  'image/avif',
};

typedef DmAssetUpload =
    Future<void> Function(
      Uri url,
      DmUploadFile file,
      Map<String, String> headers,
    );

final class DirectMessageMediaRepository {
  DirectMessageMediaRepository(this._client, {DmAssetUpload? upload})
    : _upload = upload ?? _uploadNative;

  static final RegExp _downloadPathPattern = RegExp(
    r'^/api/v1/assets/[a-zA-Z0-9_-]+/download$',
  );
  static final RegExp _safeAssetIdPattern = RegExp(r'^[a-zA-Z0-9_-]{1,128}$');

  final ApiClient _client;
  final DmAssetUpload _upload;

  /// Resolves a private DM attachment download path (`/api/v1/assets/:id/download`)
  /// into a short-lived signed HTTPS object URL.
  ///
  /// The returned URL is fetched directly from object storage without
  /// forwarding session cookies, CSRF headers, or authorization tokens.
  Future<Uri> resolve(String downloadPath) {
    final path = downloadPath.trim();
    if (!_downloadPathPattern.hasMatch(path)) {
      throw const ParseFailure('attachment.downloadPath');
    }
    return _client.get<Uri>(
      path,
      refresh: true,
      decode: (json) {
        final rawUrl = stringValue(
          json['downloadUrl'] ?? json['url'],
          'attachment.downloadUrl',
        );
        final uri = Uri.tryParse(rawUrl);
        if (uri == null ||
            !uri.hasScheme ||
            uri.scheme != 'https' ||
            uri.host.isEmpty ||
            uri.userInfo.isNotEmpty) {
          throw const ParseFailure('attachment.downloadUrl');
        }
        return uri;
      },
    );
  }

  /// Presigns, uploads, and completes a private DM image attachment via:
  /// 1. `POST /api/v1/dm/assets/presign`
  /// 2. Unauthenticated `PUT` to the presigned object storage URL
  /// 3. `POST /api/v1/dm/assets/:assetId/complete`
  Future<DmUploadedAsset> upload(DmUploadFile file) async {
    final name = file.name.trim();
    final mime = file.mime.trim().toLowerCase();
    if (name.isEmpty || name.length > 180) {
      throw const ParseFailure('upload.fileName');
    }
    if (!allowedDmImageMimes.contains(mime)) {
      throw const ParseFailure('upload.mime');
    }
    if (file.length < 1 || file.length > maxDmImageBytes) {
      throw const ParseFailure('upload.size');
    }

    final presign = await _client.request<Map<String, dynamic>>(
      'POST',
      '/api/v1/dm/assets/presign',
      body: jsonEncode(<String, Object?>{
        'fileName': name,
        'mime': mime,
        'size': file.length,
      }),
    );
    final assetId = stringValue(presign['assetId'], 'upload.assetId');
    final uploadUrl = stringValue(presign['uploadUrl'], 'upload.uploadUrl');
    final uploadUri = Uri.tryParse(uploadUrl);
    if (!_safeAssetIdPattern.hasMatch(assetId) ||
        uploadUri == null ||
        !uploadUri.hasScheme ||
        uploadUri.scheme != 'https' ||
        uploadUri.host.isEmpty ||
        uploadUri.userInfo.isNotEmpty) {
      throw const ParseFailure('upload.presign');
    }

    final rawHeaders =
        objectValue(presign['headers'], 'upload.headers') ??
        const <String, dynamic>{};
    final uploadHeaders = <String, String>{};
    for (final entry in rawHeaders.entries) {
      final key = entry.key.trim();
      final lower = key.toLowerCase();
      // Never forward session cookies, authorization, or CSRF tokens to CDN/S3.
      if (lower == 'cookie' ||
          lower == 'authorization' ||
          lower == 'x-csrf-token') {
        continue;
      }
      final val = entry.value;
      if (val is String && val.isNotEmpty) {
        uploadHeaders[key] = val;
      }
    }

    await _upload(uploadUri, file, Map.unmodifiable(uploadHeaders));

    final encodedAssetId = Uri.encodeComponent(assetId);
    final completed = await _client.request<Map<String, dynamic>>(
      'POST',
      '/api/v1/dm/assets/$encodedAssetId/complete',
      body: jsonEncode(const <String, Object?>{}),
    );
    final completedId = stringValue(
      completed['assetId'] ?? assetId,
      'upload.assetId',
    );
    final status = stringValue(completed['status'], 'upload.status');
    if (completedId.isEmpty || status != 'READY') {
      throw const ParseFailure('upload.complete');
    }

    return DmUploadedAsset(
      assetId: completedId,
      status: status,
      mime: mime,
      size: file.length,
    );
  }
}

Future<void> _uploadNative(
  Uri url,
  DmUploadFile file,
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
