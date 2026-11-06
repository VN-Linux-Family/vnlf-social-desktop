import '../features/polls/domain/poll_models.dart';

/// Failures are explicit at repository boundaries and do not expose response bodies.
sealed class AppFailure implements Exception {
  const AppFailure();
}

final class HttpFailure extends AppFailure {
  const HttpFailure(this.statusCode, {this.code});
  final int statusCode;
  final String? code;
}

final class RateLimited extends AppFailure {
  const RateLimited(this.retryAt);
  final DateTime retryAt;
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
  const Session({
    required this.userId,
    required this.displayName,
    this.username = '',
    this.email = '',
    this.avatarUrl = '',
    this.role = '',
    this.style,
  });
  final String userId;
  final String displayName;
  final String username;
  final String email;
  final String avatarUrl;
  final String role;
  final AuthorStyle? style;
}

final class AuthorStyle {
  const AuthorStyle({
    this.nameColor,
    this.nameGradient,
    this.nameEffect,
    this.frame,
    this.icon,
    this.distroBadge,
    this.nameplate,
    this.status,
  });
  final Map<String, dynamic>? nameColor;
  final Map<String, dynamic>? nameGradient;
  final String? nameEffect;
  final Map<String, dynamic>? frame;
  final Map<String, dynamic>? icon;
  final String? distroBadge;
  final Map<String, dynamic>? nameplate;
  final Map<String, dynamic>? status;
}

final class Author {
  const Author({
    required this.username,
    required this.displayName,
    this.id = '',
    this.avatarUrl = '',
    this.role = '',
    this.style,
  });
  final String id;
  final String username;
  final String displayName;
  final String avatarUrl;
  final String role;
  final AuthorStyle? style;
}

final class FeedPost {
  const FeedPost({
    required this.id,
    required this.author,
    required this.excerpt,
    required this.voteScore,
    required this.commentCount,
    this.title,
    this.slug = '',
    this.contentText = '',
    this.contentHtml = '',
    this.contentJson,
    this.coverUrl,
    this.coverAlt = '',
    this.format = '',
    this.status = '',
    this.version = 0,
    this.likeCount = 0,
    this.bookmarkCount = 0,
    this.viewCount,
    this.viewerVote = 0,
    this.viewerLiked = false,
    this.viewerBookmarked = false,
    this.canEdit = false,
    this.tagSlugs = const [],
    this.tags = const [],
    this.attachments = const [],
    this.poll,
    this.publishedAt,
    this.updatedAt,
  });
  final String id;
  final Author author;
  final String excerpt;
  final String? title;
  final String slug;
  final String contentText;
  final String contentHtml;
  final Map<String, dynamic>? contentJson;
  final String? coverUrl;
  final String coverAlt;
  final String format;
  final String status;
  final int version;
  final int likeCount;
  final int commentCount;
  final int bookmarkCount;
  final int? viewCount;
  final int voteScore;
  final int viewerVote;
  final bool viewerLiked;
  final bool viewerBookmarked;
  final bool canEdit;
  final List<String> tagSlugs;
  final List<String> tags;
  final List<ArticleAttachment> attachments;
  final Poll? poll;
  final DateTime? publishedAt;
  final DateTime? updatedAt;
}

final class ArticleAttachment {
  const ArticleAttachment({
    required this.id,
    required this.url,
    this.mime = '',
    this.alt = '',
    this.width,
    this.height,
    this.posterUrl,
    this.durationMs,
    this.state,
  });

  final String id;
  final String url;
  final String mime;
  final String alt;
  final int? width;
  final int? height;
  final String? posterUrl;
  final int? durationMs;
  final String? state;
}

final class LeaderboardItem {
  const LeaderboardItem({
    required this.userId,
    required this.username,
    required this.displayName,
    required this.avatarUrl,
    required this.earnedPoints,
    required this.rank,
    this.style,
  });
  final String userId;
  final String username;
  final String displayName;
  final String avatarUrl;
  final int earnedPoints;
  final int rank;
  final AuthorStyle? style;
}

final class LeaderboardPage {
  LeaderboardPage({
    required this.period,
    this.periodStart,
    this.periodEnd,
    this.computedAt,
    required List<LeaderboardItem> items,
  }) : items = List.unmodifiable(items);
  final String period;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final DateTime? computedAt;
  final List<LeaderboardItem> items;
}

final class ProjectItem {
  const ProjectItem({
    required this.id,
    required this.name,
    this.slug = '',
    this.tagline = '',
    this.type = '',
    this.tier = '',
    this.relation = '',
    this.seeking = false,
    this.featured = false,
    this.status = '',
    this.logoUrl,
    this.accentColor,
    this.owner,
    this.repo,
    this.rating,
    this.commentCount = 0,
    this.approvedAt,
  });
  final String id;
  final String name;
  final String slug;
  final String tagline;
  final String type;
  final String tier;
  final String relation;
  final bool seeking;
  final bool featured;
  final String status;
  final String? logoUrl;
  final String? accentColor;
  final Author? owner;
  final Map<String, dynamic>? repo;
  final Map<String, dynamic>? rating;
  final int commentCount;
  final DateTime? approvedAt;
}

final class ProjectsPage {
  ProjectsPage({required List<ProjectItem> items, this.nextCursor})
    : items = List.unmodifiable(items);
  final List<ProjectItem> items;
  final String? nextCursor;
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

final class ProjectSummary {
  const ProjectSummary({required this.id, required this.name});
  final String id;
  final String name;
}

final class DiscoverPage {
  DiscoverPage({required List<ProjectSummary> items, this.nextCursor})
    : items = List.unmodifiable(items);
  final List<ProjectSummary> items;
  final String? nextCursor;
}

final class DiscoverTag {
  const DiscoverTag({required this.id, required this.slug, required this.name});
  final String id;
  final String slug;
  final String name;
}

final class DiscoverData {
  DiscoverData({
    List<FeedPost> articles = const [],
    List<Author> users = const [],
    List<DiscoverTag> tags = const [],
    List<ProjectSummary> projects = const [],
    this.hasMore = false,
  }) : articles = List.unmodifiable(articles),
       users = List.unmodifiable(users),
       tags = List.unmodifiable(tags),
       projects = List.unmodifiable(projects);

  final List<FeedPost> articles;
  final List<Author> users;
  final List<DiscoverTag> tags;
  final List<ProjectSummary> projects;
  final bool hasMore;
}

final class LeaderboardEntry {
  const LeaderboardEntry({required this.username, required this.points});
  final String username;
  final int points;
}

final class Leaderboard {
  Leaderboard({required this.period, required List<LeaderboardEntry> items})
    : items = List.unmodifiable(items);
  final String period;
  final List<LeaderboardEntry> items;
}
