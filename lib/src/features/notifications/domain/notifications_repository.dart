import '../../../domain/models.dart';

enum NotificationKind { all, like, comment, follow, system }

final class CommunityNotice {
  const CommunityNotice({
    required this.id,
    required this.type,
    required this.targetId,
    required this.targetType,
    required this.href,
    this.title = '',
    this.excerpt = '',
    this.summarized = false,
    this.actors = const [],
    this.actorCount = 0,
    this.payload = const {},
    this.updatedAt,
    this.unread = true,
  });
  final String id, type, targetId, targetType, href, title, excerpt;

  /// Whether the server described the target: a comment that no longer shows
  /// has no summary, which the list says in words.
  final bool summarized;

  /// The people the notice is about, newest first; the server sends a few.
  final List<Author> actors;

  /// How many people in all, which can be more than [actors].
  final int actorCount;

  /// Type-specific details the action text reads, such as a ticket status.
  final Map<String, Object?> payload;

  /// When the notice last changed; grouped notices move up when it does.
  final DateTime? updatedAt;
  final bool unread;

  /// The newest actor, or an empty author for a notice from the system.
  Author get actor => actors.isEmpty
      ? const Author(username: '', displayName: '')
      : actors.first;

  CommunityNotice read() => CommunityNotice(
    id: id,
    type: type,
    targetId: targetId,
    targetType: targetType,
    href: href,
    title: title,
    excerpt: excerpt,
    summarized: summarized,
    actors: actors,
    actorCount: actorCount,
    payload: payload,
    updatedAt: updatedAt,
    unread: false,
  );
}

final class NotificationsPage {
  NotificationsPage({
    required List<CommunityNotice> items,
    this.nextCursor,
    this.unreadCount = 0,
    this.unseenCount = 0,
  }) : items = List.unmodifiable(items);
  final List<CommunityNotice> items;
  final String? nextCursor;
  final int unreadCount, unseenCount;
}

abstract interface class NotificationsRepository {
  Future<NotificationsPage> load({
    String? cursor,
    bool unreadOnly = false,
    NotificationKind kind = NotificationKind.all,
  });
  Future<void> seen();
  Future<void> read({List<String>? ids});
}
