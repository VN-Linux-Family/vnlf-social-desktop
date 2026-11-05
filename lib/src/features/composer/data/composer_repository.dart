import 'dart:convert';
import 'dart:io';

import '../../../core/api_client.dart';
import '../../../data/field_reader.dart';
import '../domain/composer_draft.dart';

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
      objectList(json['attachments'], 'draft.attachments').map(
        (item) => DraftMedia(
          id: stringValue(item['id'], 'media.id'),
          url: stringValue(item['url'], 'media.url'),
          mime: stringValue(item['mime'], 'media.mime'),
          alt: stringValue(item['alt'], 'media.alt'),
        ),
      ),
    ),
    status: stringValue(json['status'], 'draft.status'),
    slug: stringValue(json['slug'], 'draft.slug'),
    coverAssetId: nullableString(json['coverAssetId'], 'draft.coverAssetId'),
    coverAlt: stringValue(json['coverAlt'], 'draft.coverAlt'),
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
  Future<ComposerDraft> load(String id) =>
      _client.get(_path(id), decode: draftFromJson);
  @override
  Future<List<ComposerDraft>> drafts() => _client.get(
    '/api/v1/me/articles',
    query: const {'status': 'DRAFT'},
    decode: (json) => List.unmodifiable(
      objectList(json['items'], 'drafts.items').map(draftFromJson),
    ),
  );
  @override
  Future<ComposerDraft> save(ComposerDraft draft) => _client.request(
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
  @override
  Future<ComposerDraft> publish(
    ComposerDraft draft, {
    required String idempotencyKey,
  }) => _client.request(
    'POST',
    '${_path(draft.id)}/publish',
    headers: {'idempotency-key': idempotencyKey},
    decode: draftFromJson,
  );
  @override
  Future<void> delete(String id) => _client.request<void>('DELETE', _path(id));
  @override
  Future<void> deleteMedia(String id, String assetId) => _client.request<void>(
    'DELETE',
    '${_path(id)}/assets/${Uri.encodeComponent(assetId)}',
  );
  @override
  Future<DraftMedia> upload(String id, ComposerUpload file) async {
    if (file.length < 1 || file.length > 209715200) {
      throw const ParseFailure('upload.size');
    }
    final presign = await _client.request<Map<String, dynamic>>(
      'POST',
      '${_path(id)}/assets/presign',
      body: jsonEncode({
        'fileName': file.name,
        'mime': file.mime,
        'size': file.length,
        'placement': 'ATTACHMENT',
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
    return DraftMedia(
      id: stringValue(completed['assetId'], 'upload.assetId'),
      url: stringValue(completed['url'], 'upload.url'),
      mime: file.mime,
    );
  }
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
