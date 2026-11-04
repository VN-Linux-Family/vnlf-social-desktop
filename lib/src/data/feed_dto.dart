import '../domain/models.dart';
import 'profile_dto.dart';

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.isEmpty) throw ParseFailure(key);
  return value;
}

String _optionalString(Object? value, String field) {
  if (value == null) return '';
  if (value is! String) throw ParseFailure(field);
  return value;
}

int _optionalInt(Object? value, String field) {
  if (value == null) return 0;
  if (value is! int) throw ParseFailure(field);
  return value;
}

final class FeedPostDto {
  const FeedPostDto({
    required this.id,
    required this.username,
    required this.displayName,
    required this.excerpt,
    required this.voteScore,
    required this.commentCount,
  });
  factory FeedPostDto.fromJson(Map<String, dynamic> json) {
    final rawAuthor = json['author'];
    if (rawAuthor != null && rawAuthor is! Map<String, dynamic>) {
      throw const ParseFailure('author');
    }
    final author =
        rawAuthor as Map<String, dynamic>? ?? const <String, dynamic>{};
    final profile = ProfileDto.fromJson(author);
    return FeedPostDto(
      id: _requiredString(json, 'id'),
      username: profile.username,
      displayName: profile.displayName,
      excerpt: _optionalString(json['excerpt'], 'excerpt'),
      voteScore: _optionalInt(json['voteScore'], 'voteScore'),
      commentCount: _optionalInt(json['commentCount'], 'commentCount'),
    );
  }
  final String id;
  final String username;
  final String displayName;
  final String excerpt;
  final int voteScore;
  final int commentCount;
  FeedPost toDomain() => FeedPost(
    id: id,
    author: Author(username: username, displayName: displayName),
    excerpt: excerpt,
    voteScore: voteScore,
    commentCount: commentCount,
  );
}

final class FeedPageDto {
  FeedPageDto.fromJson(Map<String, dynamic> json)
    : items = _parseItems(json['items']),
      nextCursor = _parseCursor(json['nextCursor']);
  final List<FeedPostDto> items;
  final String? nextCursor;
  static List<FeedPostDto> _parseItems(Object? value) {
    if (value == null) return const [];
    if (value is! List) throw const ParseFailure('items');
    return value
        .map((item) {
          if (item is! Map<String, dynamic>) throw const ParseFailure('items');
          return FeedPostDto.fromJson(item);
        })
        .toList(growable: false);
  }

  static String? _parseCursor(Object? value) {
    if (value != null && value is! String) {
      throw const ParseFailure('nextCursor');
    }
    return value as String?;
  }

  FeedPage toDomain() => FeedPage(
    items: items.map((item) => item.toDomain()).toList(),
    nextCursor: nextCursor,
  );
}
