import '../../../domain/models.dart';

final class PublicProfile {
  const PublicProfile({
    required this.author,
    this.bio,
    this.totalPoints,
    this.level,
    this.currentStreak,
    this.followerCount,
    this.followingCount,
    this.coverUrl,
    this.guestbookEnabled = true,
    this.isSample = false,
    this.followedByViewer,
    this.blockedByViewer,
  });
  final Author author;
  final String? bio;
  final int? totalPoints;
  final int? level;
  final int? currentStreak;
  final int? followerCount;
  final int? followingCount;
  final String? coverUrl;
  final bool guestbookEnabled;
  final bool isSample;

  /// Null means the server did not provide the viewer's relationship state.
  final bool? followedByViewer;
  final bool? blockedByViewer;
}

final class ProfileComment {
  const ProfileComment({
    required this.id,
    required this.articleId,
    required this.articleSlug,
    required this.content,
    this.createdAt,
  });
  final String id;
  final String articleId;
  final String articleSlug;
  final String content;
  final DateTime? createdAt;
}

final class ProfileCommentsPage {
  ProfileCommentsPage({required List<ProfileComment> items, this.nextCursor})
    : items = List.unmodifiable(items);
  final List<ProfileComment> items;
  final String? nextCursor;
}

final class GuestbookEntry {
  const GuestbookEntry({
    required this.id,
    required this.author,
    required this.content,
    this.createdAt,
  });
  final String id;
  final Author author;
  final String content;
  final DateTime? createdAt;
}

final class GuestbookPage {
  GuestbookPage({
    required List<GuestbookEntry> items,
    required this.enabled,
    required this.total,
    this.nextCursor,
  }) : items = List.unmodifiable(items);
  final List<GuestbookEntry> items;
  final bool enabled;
  final int total;
  final String? nextCursor;
}

abstract interface class PublicProfileRepository {
  Future<PublicProfile?> getProfile(String username);
  Future<FeedPage> getPosts(String username);
  Future<ProfileCommentsPage> getComments(String username);
  Future<ProjectsPage> getProjects(String username);
  Future<GuestbookPage> getGuestbook(String username, {String? cursor});
}
