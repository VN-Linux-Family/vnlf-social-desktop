import '../../../domain/models.dart';
import 'composer_draft.dart';

void validateDraft(ComposerDraft draft, {bool publishing = false}) {
  if (draft.pollChanged &&
      (draft.publishedAt != null || draft.status == 'PUBLISHED')) {
    throw const ParseFailure('composer.pollLocked');
  }
  if (draft.format == 'ARTICLE' && draft.pollDraft != null) {
    throw const ParseFailure('composer.pollPostOnly');
  }
  if (publishing &&
      draft.pollDraft != null &&
      draft.pollDraft!.validated == null) {
    throw const ParseFailure('composer.pollInvalid');
  }
  if (!const {'POST', 'ARTICLE'}.contains(draft.format)) {
    throw const ParseFailure('composer.format');
  }
  if (draft.title.length > 180 ||
      draft.excerpt.length > 220 ||
      draft.coverAlt.length > 300) {
    throw const ParseFailure('composer.metadata');
  }
  if (draft.tags.length > 3 ||
      draft.tags.any((tag) => tag.trim().isEmpty || tag.length > 40)) {
    throw const ParseFailure('composer.tags');
  }
  if (draft.media.length > 20 ||
      draft.media.map((m) => m.id).toSet().length != draft.media.length ||
      draft.media.any((m) => m.alt.length > 300)) {
    throw const ParseFailure('composer.attachments');
  }
  final inlineIds = <String>{};
  void collect(Map<String, dynamic> node) {
    final attrs = node['attrs'];
    if (node['type'] == 'image' &&
        attrs is Map &&
        attrs['assetId'] is String &&
        (attrs['assetId'] as String).isNotEmpty) {
      inlineIds.add(attrs['assetId'] as String);
    }
    for (final child
        in node['content'] is List ? node['content'] as List : const []) {
      if (child is Map<String, dynamic>) collect(child);
    }
  }

  collect(draft.document);
  String text(Map<String, dynamic> node) => node['type'] == 'text'
      ? node['text'] as String? ?? ''
      : (node['content'] as List? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(text)
            .join();
  if (publishing &&
      text(draft.document).trim().isEmpty &&
      inlineIds.isEmpty &&
      draft.media.isEmpty &&
      draft.coverAssetId == null) {
    throw const ParseFailure('composer.empty');
  }
  if (draft.format == 'POST' &&
      (inlineIds.isNotEmpty || draft.coverAssetId != null)) {
    throw const ParseFailure('composer.postInlineImage');
  }
  final videos = draft.media.where((m) => m.isVideo).toList();
  if (videos.length > 1 || (draft.format == 'ARTICLE' && videos.isNotEmpty)) {
    throw const ParseFailure('composer.videoPostOnly');
  }
  if (videos.any((m) => (m.durationMs ?? 0) > 30000)) {
    throw const ParseFailure('composer.videoDuration');
  }
  if ({
        ...inlineIds,
        ...draft.media.map((m) => m.id),
        if (draft.coverAssetId != null) draft.coverAssetId!,
      }.length >
      21) {
    throw const ParseFailure('composer.assetLimit');
  }
  if (publishing &&
      [
        ...draft.media,
        ...draft.assets.values.where(
          (m) => inlineIds.contains(m.id) || m.id == draft.coverAssetId,
        ),
      ].any((m) => !m.isReady)) {
    throw const ParseFailure('composer.mediaNotReady');
  }
}
