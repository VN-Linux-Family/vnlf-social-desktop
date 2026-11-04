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
    return FeedPost(
      id: id,
      author: ProfileDto.fromJson(author).toDomain(),
      excerpt: stringValue(_json['excerpt'], 'excerpt'),
      title: nullableString(_json['title'], 'title'),
      slug: stringValue(_json['slug'], 'slug'),
      contentText: stringValue(_json['contentText'], 'contentText'),
      contentHtml: stringValue(_json['contentHtml'], 'contentHtml'),
      contentJson: objectValue(_json['contentJson'], 'contentJson'),
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
      publishedAt: dateValue(_json['publishedAt'], 'publishedAt'),
      updatedAt: dateValue(_json['updatedAt'], 'updatedAt'),
    );
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
