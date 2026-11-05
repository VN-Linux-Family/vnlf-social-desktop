import '../domain/models.dart';
import 'field_reader.dart';
import 'profile_dto.dart';

final class FeedPostDto {
  FeedPostDto._(this._json);
  factory FeedPostDto.fromJson(Map<String, dynamic> json) {
    final dto = FeedPostDto._(objectValue(json, 'post')!);
    dto.toDomain();
    return dto;
  }
  final Map<String, dynamic> _json;
  FeedPost toDomain() {
    final id = stringValue(_json['id'], 'id');
    if (id.isEmpty) throw const ParseFailure('id');
    final author =
        objectValue(_json['author'], 'author') ?? const <String, dynamic>{};
    final attachmentsRaw = objectList(_json['attachments'], 'attachments');
    final attachments = attachmentsRaw
        .map(
          (a) => ArticleAttachment(
            id: stringValue(a['id'], 'id'),
            url: stringValue(a['url'], 'url'),
            mime: stringValue(a['mime'], 'mime'),
            alt: stringValue(a['alt'], 'alt'),
            width: nullableInt(a['width'], 'width'),
            height: nullableInt(a['height'], 'height'),
            posterUrl: nullableString(a['posterUrl'], 'posterUrl'),
            durationMs: nullableInt(a['durationMs'], 'durationMs'),
            state: nullableString(a['state'], 'state'),
          ),
        )
        .toList();
    return FeedPost(
      id: id,
      author: ProfileDto.fromJson(author).toDomain(),
      excerpt: stringValue(_json['excerpt'], 'excerpt'),
      title: nullableString(_json['title'], 'title'),
      slug: stringValue(_json['slug'], 'slug'),
      contentText: stringValue(_json['contentText'], 'contentText'),
      contentHtml: stringValue(_json['contentHtml'], 'contentHtml'),
      contentJson: _resolveContent(),
      coverUrl: nullableString(_json['coverUrl'], 'coverUrl'),
      coverAlt: stringValue(_json['coverAlt'], 'coverAlt'),
      format: stringValue(_json['format'], 'format'),
      status: stringValue(_json['status'], 'status'),
      version: intValue(_json['version'], 'version'),
      likeCount: intValue(_json['likeCount'], 'likeCount'),
      commentCount: intValue(_json['commentCount'], 'commentCount'),
      bookmarkCount: intValue(_json['bookmarkCount'], 'bookmarkCount'),
      viewCount: nullableInt(_json['viewCount'], 'viewCount'),
      voteScore: intValue(_json['voteScore'], 'voteScore'),
      viewerVote: intValue(_json['viewerVote'], 'viewerVote'),
      viewerLiked: boolValue(_json['viewerLiked'], 'viewerLiked'),
      viewerBookmarked: boolValue(
        _json['viewerBookmarked'],
        'viewerBookmarked',
      ),
      canEdit: boolValue(_json['canEdit'], 'canEdit'),
      tagSlugs: stringList(_json['tagSlugs'], 'tagSlugs'),
      tags: stringList(_json['tags'], 'tags'),
      attachments: attachments,
      publishedAt: dateValue(_json['publishedAt'], 'publishedAt'),
      updatedAt: dateValue(_json['updatedAt'], 'updatedAt'),
    );
  }

  Map<String, dynamic>? _resolveContent() {
    final doc = objectValue(_json['contentJson'], 'contentJson');
    if (doc == null) return null;
    final assets = {
      for (final asset in objectList(_json['assets'], 'assets'))
        stringValue(asset['id'], 'asset.id'): asset,
    };
    Map<String, dynamic> resolve(Map<String, dynamic> node) {
      final attrs = objectValue(node['attrs'], 'content.attrs');
      final assetId = attrs?['assetId'];
      final asset = assetId is String && assetId.isNotEmpty
          ? assets[assetId]
          : null;
      return {
        ...node,
        if (node['type'] == 'image' && attrs != null)
          'attrs': {
            ...attrs,
            if (asset != null) ...{
              'src': nullableString(asset['url'], 'asset.url') ?? attrs['src'],
              'width': nullableInt(asset['width'], 'asset.width'),
              'height': nullableInt(asset['height'], 'asset.height'),
            },
          },
        if (node['content'] is List)
          'content': objectList(
            node['content'],
            'content.nodes',
          ).map(resolve).toList(),
      };
    }

    return objectValue(resolve(doc), 'contentJson');
  }
}

final class FeedPageDto {
  FeedPageDto.fromJson(Map<String, dynamic> json)
    : items = objectList(
        json['items'],
        'items',
      ).map(FeedPostDto.fromJson).toList(growable: false),
      nextCursor = nullableString(json['nextCursor'], 'nextCursor');
  final List<FeedPostDto> items;
  final String? nextCursor;
  FeedPage toDomain() => FeedPage(
    items: items.map((item) => item.toDomain()).toList(),
    nextCursor: nextCursor,
  );
}
