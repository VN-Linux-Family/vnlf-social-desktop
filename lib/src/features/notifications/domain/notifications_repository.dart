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
    this.actor = const Author(username: '', displayName: ''),
    this.unread = true,
  });
  final String id, type, targetId, targetType, href, title, excerpt;
  final Author actor;
  final bool unread;
  CommunityNotice read() => CommunityNotice(
    id: id,
    type: type,
    targetId: targetId,
    targetType: targetType,
    href: href,
    title: title,
    excerpt: excerpt,
    actor: actor,
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
