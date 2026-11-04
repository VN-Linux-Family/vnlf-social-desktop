/// Failures are explicit at repository boundaries and do not expose response bodies.
sealed class AppFailure implements Exception {
  const AppFailure();
}

final class HttpFailure extends AppFailure {
  const HttpFailure(this.statusCode);
  final int statusCode;
}

final class ParseFailure extends AppFailure {
  const ParseFailure(this.field);
  final String field;
}

final class TransportFailure extends AppFailure {
  const TransportFailure();
}

final class StorageFailure extends AppFailure {
  const StorageFailure();
}

final class Session {
  const Session({required this.userId, required this.displayName});
  final String userId;
  final String displayName;
}

final class Author {
  const Author({required this.username, required this.displayName});
  final String username;
  final String displayName;
}

final class FeedPost {
  const FeedPost({
    required this.id,
    required this.author,
    required this.excerpt,
    required this.voteScore,
    required this.commentCount,
  });
  final String id;
  final Author author;
  final String excerpt;
  final int voteScore;
  final int commentCount;
}

final class FeedPage {
  FeedPage({required List<FeedPost> items, this.nextCursor})
    : items = List.unmodifiable(items);
  final List<FeedPost> items;
  final String? nextCursor;
}

final class CommunityChannel {
  const CommunityChannel({required this.id, required this.name});
  final String id;
  final String name;
}
