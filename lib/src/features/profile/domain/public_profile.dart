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
    this.decor = const ProfileDecor(),
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

  /// The look its owner picked; the defaults when they changed nothing.
  final ProfileDecor decor;
}

/// The parts of the website's `decor` a profile page and card show.
final class ProfileDecor {
  const ProfileDecor({
    this.themeId = 'vnlf',
    this.accentColor,
    this.coverSmallUrl,
    this.status,
    this.links = const [],
    this.discordUsername,
    this.visits,
  });

  /// A `PROFILE_THEMES` id; `profileThemeColors` falls back to `vnlf`.
  final String themeId;
  final String? accentColor;

  /// The 750×250 cover, which the card shows.
  final String? coverSmallUrl;

  /// The emoji and line shown under the bio.
  final ({String emoji, String text})? status;

  /// The links under the bio as stored; `parseProfileLink` checks each again
  /// before it is shown.
  final List<String> links;

  /// The linked Discord account, when its owner shows it.
  final String? discordUsername;

  /// Different visitors per day, summed. Null for visitors when the owner
  /// hid it; [hidden] tells the owner that only they see it.
  final ({int count, bool hidden})? visits;
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
    this.status = GuestbookStatus.visible,
    this.mine = false,
  });
  final String id;
  final Author author;
  final String content;
  final DateTime? createdAt;
  final GuestbookStatus status;
  final bool mine;
}

enum GuestbookStatus { visible, hidden }

final class GuestbookPage {
  GuestbookPage({
    required List<GuestbookEntry> items,
    required this.enabled,
    required this.total,
    this.nextCursor,
    this.blockedReason,
  }) : items = List.unmodifiable(items);
  final String? blockedReason;
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
