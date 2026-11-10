import '../../../domain/models.dart';

/// The signed-in member's own posts, as "Bài viết của bạn" reads and
/// changes them.
abstract interface class MyArticlesRepository {
  /// `?status=DRAFT`: up to 50 drafts, newest change first.
  Future<List<FeedPost>> drafts();

  /// Up to the 50 most recently changed posts of every status.
  Future<List<FeedPost>> all();

  /// Hides a published post from the feed; it can be restored.
  Future<void> archive(String id);

  /// Publishes an archived post again.
  Future<void> restore(String id);
}
