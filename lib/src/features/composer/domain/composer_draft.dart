final class DraftMedia {
  const DraftMedia({
    required this.id,
    required this.url,
    required this.mime,
    this.alt = '',
  });
  final String id;
  final String url;
  final String mime;
  final String alt;
}

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

  ComposerDraft copyWith({
    int? version,
    String? format,
    String? title,
    String? excerpt,
    Map<String, dynamic>? document,
    List<String>? tags,
    List<DraftMedia>? media,
  }) => ComposerDraft(
    id: id,
    version: version ?? this.version,
    format: format ?? this.format,
    title: title ?? this.title,
    excerpt: excerpt ?? this.excerpt,
    document: document ?? this.document,
    tags: tags ?? this.tags,
    media: media ?? this.media,
    status: status,
    slug: slug,
    coverAssetId: coverAssetId,
    coverAlt: coverAlt,
  );
}

abstract interface class ComposerRepository {
  Future<ComposerDraft> create();
  Future<ComposerDraft> load(String id);
  Future<List<ComposerDraft>> drafts();
  Future<ComposerDraft> save(ComposerDraft draft);
  Future<ComposerDraft> publish(
    ComposerDraft draft, {
    required String idempotencyKey,
  });
  Future<void> delete(String id);
  Future<DraftMedia> upload(String id, ComposerUpload file);
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
