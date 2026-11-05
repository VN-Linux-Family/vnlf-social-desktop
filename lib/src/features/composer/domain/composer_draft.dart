final class DraftMedia {
  const DraftMedia({
    required this.id,
    required this.url,
    required this.mime,
    this.alt = '',
    this.status = 'READY',
    this.state = 'READY',
    this.placement = 'ATTACHMENT',
    this.error,
    this.width,
    this.height,
    this.posterUrl,
    this.durationMs,
  });
  final String id;
  final String url;
  final String mime;
  final String alt;
  final String status;
  final String state;
  final String placement;
  final String? error;
  final int? width;
  final int? height;
  final String? posterUrl;
  final int? durationMs;
  bool get isVideo => mime.startsWith('video/');
  bool get isReady => status == 'READY' && state == 'READY' && url.isNotEmpty;
  bool get isProcessing => status == 'PENDING' || state == 'PROCESSING';

  DraftMedia copyWith({String? alt, String? placement}) => DraftMedia(
    id: id,
    url: url,
    mime: mime,
    alt: alt ?? this.alt,
    status: status,
    state: state,
    placement: placement ?? this.placement,
    error: error,
    width: width,
    height: height,
    posterUrl: posterUrl,
    durationMs: durationMs,
  );
}

const _unchanged = Object();

final class ComposerDraft {
  const ComposerDraft({
    required this.id,
    required this.version,
    this.format = 'POST',
    this.title = '',
    this.excerpt = '',
    this.document = const {'type': 'doc', 'content': <Object>[]},
    this.tags = const [],
    this.media = const [],
    this.status = 'DRAFT',
    this.slug = '',
    this.coverAssetId,
    this.coverAlt = '',
    this.coverUrl,
    this.assets = const {},
    this.publishedAt,
  });
  final String id;
  final int version;
  final String format;
  final String title;
  final String excerpt;
  final Map<String, dynamic> document;
  final List<String> tags;
  final List<DraftMedia> media;
  final String status;
  final String slug;
  final String? coverAssetId;
  final String coverAlt;
  final String? coverUrl;
  final Map<String, DraftMedia> assets;
  final String? publishedAt;

  ComposerDraft copyWith({
    String? id,
    int? version,
    String? format,
    String? title,
    String? excerpt,
    Map<String, dynamic>? document,
    List<String>? tags,
    List<DraftMedia>? media,
    Object? coverAssetId = _unchanged,
    Object? coverUrl = _unchanged,
    String? coverAlt,
    Map<String, DraftMedia>? assets,
    String? status,
    String? slug,
  }) => ComposerDraft(
    id: id ?? this.id,
    version: version ?? this.version,
    format: format ?? this.format,
    title: title ?? this.title,
    excerpt: excerpt ?? this.excerpt,
    document: document ?? this.document,
    tags: tags ?? this.tags,
    media: media ?? this.media,
    status: status ?? this.status,
    slug: slug ?? this.slug,
    coverAssetId: identical(coverAssetId, _unchanged)
        ? this.coverAssetId
        : coverAssetId as String?,
    coverUrl: identical(coverUrl, _unchanged)
        ? this.coverUrl
        : coverUrl as String?,
    coverAlt: coverAlt ?? this.coverAlt,
    assets: assets ?? this.assets,
    publishedAt: publishedAt,
  );
}

abstract interface class ComposerRepository {
  Future<ComposerDraft> create();
  Future<ComposerDraft> load(String id, {bool refresh = false});
  Future<List<ComposerDraft>> drafts();
  Future<ComposerDraft> save(ComposerDraft draft);
  Future<ComposerDraft> publish(
    ComposerDraft draft, {
    required String idempotencyKey,
  });
  Future<void> delete(String id);
  Future<DraftMedia> upload(
    String id,
    ComposerUpload file, {
    String placement = 'ATTACHMENT',
    String format = 'POST',
  });
  Future<DraftMedia> refreshMedia(String id, DraftMedia media);
  Future<void> deleteMedia(String id, String assetId);
}

final class ComposerUpload {
  const ComposerUpload({
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
