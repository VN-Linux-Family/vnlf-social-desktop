import 'dart:convert';
import 'dart:io';

import '../../../core/api_client.dart';
import '../../../data/field_reader.dart';
import '../domain/composer_draft.dart';
import '../domain/composer_validation.dart';

typedef AssetUpload = Future<void> Function(Uri url, ComposerUpload file);

ComposerDraft draftFromJson(Map<String, dynamic> json) {
  final id = stringValue(json['id'], 'draft.id');
  if (id.isEmpty) throw const ParseFailure('draft.id');
  return ComposerDraft(
    id: id,
    version: intValue(json['version'], 'draft.version'),
    format: stringValue(json['format'], 'draft.format').isEmpty
        ? 'POST'
        : stringValue(json['format'], 'draft.format'),
    title: stringValue(json['title'], 'draft.title'),
    excerpt: stringValue(json['excerpt'], 'draft.excerpt'),
    document:
        objectValue(json['contentJson'], 'draft.contentJson') ??
        const {'type': 'doc', 'content': <Object>[]},
    tags: stringList(json['tags'], 'draft.tags'),
    media: List.unmodifiable(
      objectList(
        json['attachments'],
        'draft.attachments',
      ).map(draftMediaFromJson),
    ),
    assets: Map.unmodifiable({
      for (final item in objectList(json['assets'], 'draft.assets'))
        stringValue(item['id'], 'asset.id'): draftMediaFromJson(item),
    }),
    status: stringValue(json['status'], 'draft.status'),
    slug: stringValue(json['slug'], 'draft.slug'),
    coverAssetId: nullableString(json['coverAssetId'], 'draft.coverAssetId'),
    coverAlt: stringValue(json['coverAlt'], 'draft.coverAlt'),
    coverUrl: nullableString(json['coverUrl'], 'draft.coverUrl'),
    publishedAt: nullableString(json['publishedAt'], 'draft.publishedAt'),
  );
}

DraftMedia draftMediaFromJson(Map<String, dynamic> json) {
  final state = stringValue(json['state'], 'media.state');
  final status = stringValue(json['status'], 'media.status');
  return DraftMedia(
    id: stringValue(json['id'] ?? json['assetId'], 'media.id'),
    url: stringValue(json['url'], 'media.url'),
    mime: stringValue(json['mime'], 'media.mime'),
    alt: stringValue(json['alt'], 'media.alt'),
    status: status.isEmpty
        ? (state == 'PROCESSING'
              ? 'PENDING'
              : state == 'FAILED'
              ? 'FAILED'
              : 'READY')
        : status,
    state: state.isEmpty
        ? (status == 'PENDING'
              ? 'PROCESSING'
              : status.isEmpty
              ? 'READY'
              : status)
        : state,
    placement:
        nullableString(json['placement'], 'media.placement') ?? 'ATTACHMENT',
    error: nullableString(json['error'], 'media.error'),
    width: json['width'] is num ? (json['width'] as num).toInt() : null,
    height: json['height'] is num ? (json['height'] as num).toInt() : null,
    posterUrl: nullableString(json['posterUrl'], 'media.posterUrl'),
    durationMs: json['durationMs'] is num
        ? (json['durationMs'] as num).toInt()
        : null,
  );
}

final class LiveComposerRepository implements ComposerRepository {
  LiveComposerRepository(this._client, {AssetUpload? upload})
    : _upload = upload ?? _uploadNative;
  final ApiClient _client;
  final AssetUpload _upload;
  String _path(String id) => '/api/v1/articles/${Uri.encodeComponent(id)}';
  @override
  Future<ComposerDraft> create() =>
      _client.request('POST', '/api/v1/articles', decode: draftFromJson);
  @override
  Future<ComposerDraft> load(String id, {bool refresh = false}) =>
      _client.get(_path(id), refresh: refresh, decode: draftFromJson);
  @override
  Future<List<ComposerDraft>> drafts() => _client.get(
    '/api/v1/me/articles',
    query: const {'status': 'DRAFT'},
    decode: (json) => List.unmodifiable(
      objectList(json['items'], 'drafts.items').map(draftFromJson),
    ),
  );
  @override
  Future<ComposerDraft> save(ComposerDraft draft) async {
    validateDraft(draft);
    return _client.request(
      'PATCH',
      _path(draft.id),
      body: jsonEncode({
        'version': draft.version,
        'format': draft.format,
        'title': draft.title.trim().isEmpty ? null : draft.title.trim(),
        'excerpt': draft.excerpt,
        'tags': draft.tags,
        'coverAssetId': draft.coverAssetId,
        'coverAlt': draft.coverAlt,
        'contentJson': draft.document,
        'attachments': [
          for (final media in draft.media)
            {'assetId': media.id, 'alt': media.alt},
        ],
      }),
      decode: draftFromJson,
    );
  }

  @override
  Future<ComposerDraft> publish(
    ComposerDraft draft, {
    required String idempotencyKey,
  }) async {
    validateDraft(draft, publishing: true);
    return _client.request(
      'POST',
      '${_path(draft.id)}/publish',
      headers: {'idempotency-key': idempotencyKey},
      decode: draftFromJson,
    );
  }

  @override
  Future<void> delete(String id) => _client.request<void>('DELETE', _path(id));
  @override
  Future<void> deleteMedia(String id, String assetId) => _client.request<void>(
    'DELETE',
    '${_path(id)}/assets/${Uri.encodeComponent(assetId)}',
  );
  @override
  Future<DraftMedia> upload(
    String id,
    ComposerUpload file, {
    String placement = 'ATTACHMENT',
    String format = 'POST',
  }) async {
    final video = const {
      'video/mp4',
      'video/quicktime',
      'video/webm',
    }.contains(file.mime);
    final image = const {
      'image/jpeg',
      'image/png',
      'image/webp',
      'image/gif',
    }.contains(file.mime);
    if ((!image && !video) ||
        !const {'COVER', 'INLINE', 'ATTACHMENT'}.contains(placement) ||
        (video && (format != 'POST' || placement != 'ATTACHMENT')) ||
        (format == 'POST' && placement != 'ATTACHMENT')) {
      throw const ParseFailure('upload.placement');
    }
    if (file.name.isEmpty ||
        file.name.length > 255 ||
        file.length < 1 ||
        file.length > (video ? 209715200 : 10485760)) {
      throw const ParseFailure('upload.size');
    }
    final presign = await _client.request<Map<String, dynamic>>(
      'POST',
      '${_path(id)}/assets/presign',
      body: jsonEncode({
        'fileName': file.name,
        'mime': file.mime,
        'size': file.length,
        'placement': placement,
      }),
    );
    final assetId = stringValue(presign['assetId'], 'upload.assetId');
    final url = Uri.tryParse(stringValue(presign['uploadUrl'], 'upload.url'));
    if (assetId.isEmpty ||
        url == null ||
        url.scheme != 'https' ||
        url.host.isEmpty) {
      throw const ParseFailure('upload.url');
    }
    await _upload(url, file);
    final completed = await _client.request<Map<String, dynamic>>(
      'POST',
      '${_path(id)}/assets/${Uri.encodeComponent(assetId)}/complete',
    );
    final result = draftMediaFromJson({
      ...completed,
      'id': completed['assetId'] ?? assetId,
      'mime': file.mime,
      'placement': placement,
    });
    if (result.id.isEmpty || (result.status == 'READY' && result.url.isEmpty)) {
      throw const ParseFailure('upload.complete');
    }
    return result;
  }

  @override
  Future<DraftMedia> refreshMedia(String id, DraftMedia media) => _client.get(
    '${_path(id)}/assets/${Uri.encodeComponent(media.id)}',
    refresh: true,
    decode: (json) => draftMediaFromJson({
      'id': media.id,
      'mime': media.mime,
      'alt': media.alt,
      'placement': media.placement,
      ...json,
    }),
  );
}

Future<void> _uploadNative(Uri url, ComposerUpload file) async {
  final client = HttpClient();
  try {
    final request = await client
        .putUrl(url)
        .timeout(const Duration(seconds: 30));
    request.followRedirects = false;
    request.headers.set(HttpHeaders.contentTypeHeader, file.mime);
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
