import '../../../domain/models.dart';

/// One page of a topic's public posts (`GET /api/v1/tags/:slug/articles`).
final class TagArticlesPage {
  TagArticlesPage({
    required this.name,
    required List<FeedPost> items,
    this.total,
    this.nextCursor,
  }) : items = List.unmodifiable(items);

  /// The tag's own name, such as "Linux" for the slug "linux".
  final String name;

  /// Every public post with the tag; the server sends it on the first page
  /// only.
  final int? total;
  final List<FeedPost> items;
  final String? nextCursor;
}

abstract interface class TagArticlesRepository {
  /// Null when no tag has [slug]; the match is exact, as on the server.
  Future<TagArticlesPage?> page(String slug, {String? cursor});
}

/// A slug the website accepts in `/t/<slug>`; anything else is its 404 page.
bool isTagSlug(String slug) =>
    RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$').hasMatch(slug);
