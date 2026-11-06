import '../../../domain/models.dart';
import 'composer_draft.dart';

ComposerDraft asArticle(ComposerDraft draft) {
  if (draft.media.any((media) => media.isVideo)) {
    throw const ParseFailure('composer.videoPostOnly');
  }
  if (draft.media.any((media) => !media.isReady)) {
    throw const ParseFailure('composer.mediaNotReady');
  }
  return draft.copyWith(
    format: 'ARTICLE',
    media: const [],
    assets: Map.unmodifiable({
      ...draft.assets,
      for (final media in draft.media)
        media.id: media.copyWith(placement: 'INLINE'),
    }),
    document: {
      ...draft.document,
      'content': [
        ...draft.document['content'] as List? ?? const [],
        for (final media in draft.media)
          {
            'type': 'image',
            'attrs': {
              'assetId': media.id,
              'src': media.url,
              'alt': media.alt,
              'layout': 'normal',
            },
          },
      ],
    },
  );
}

ComposerDraft asRegularPost(ComposerDraft draft) {
  final attachments = {for (final media in draft.media) media.id: media};
  Map<String, dynamic> convert(Map<String, dynamic> node) {
    final children = <Map<String, dynamic>>[];
    for (final child
        in (node['content'] as List? ?? const [])
            .whereType<Map<String, dynamic>>()) {
      if (child['type'] != 'image') {
        children.add(convert(child));
        continue;
      }
      final attrs = child['attrs'];
      final id = attrs is Map ? attrs['assetId'] : null;
      final asset = id is String ? draft.assets[id] : null;
      if (asset == null) throw const ParseFailure('composer.missingAsset');
      attachments[asset.id] = asset.copyWith(
        placement: 'ATTACHMENT',
        alt: attrs['alt'] as String? ?? '',
      );
    }
    return {...node, if (node['content'] is List) 'content': children};
  }

  final document = convert(draft.document);
  if (attachments.length > 20) throw const ParseFailure('composer.attachments');
  return draft.copyWith(
    format: 'POST',
    document: document,
    media: List.unmodifiable(attachments.values),
    title: '',
    excerpt: '',
    tags: [],
    coverAssetId: null,
    coverUrl: null,
    coverAlt: '',
  );
}
