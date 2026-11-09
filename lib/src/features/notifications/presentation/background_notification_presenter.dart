import '../../../domain/models.dart';
import '../../../i18n/vi.dart';
import '../../realtime/domain/community_event.dart';
import '../domain/notifications_repository.dart';
import 'notice_copy.dart';

typedef ShowSystemNotification = Future<void> Function({
  required int id,
  required String title,
  required String body,
  required String payload,
});

/// Turns realtime events that arrive while the app is in the background into
/// system notifications.
final class BackgroundNotificationPresenter {
  const BackgroundNotificationPresenter({
    required this.show,
    required this.loadLatestNotices,
    required this.currentUserId,
    required this.channelSlug,
  });

  final ShowSystemNotification show;
  final Future<NotificationsPage> Function() loadLatestNotices;
  final String? currentUserId;
  final String? Function(String channelId) channelSlug;

  Future<void> present(CommunityEvent event) async {
    final data = event.data;
    if (data is! Map<String, Object?>) return;
    switch (event.type) {
      case 'notification:created' || 'notification:updated':
        await _presentNotice(data);
      case 'dm:message-created':
        if (_ownMessage(data)) return;
        final conversationId = _text(data['conversationId']);
        await show(
          // The same message also arrives on the conversation topic.
          id: (_text(data['id']) ?? event.eventId).hashCode,
          title: _authorName(data) ?? vi.app.tinNhanMoi,
          body: _text(data['content']) ?? vi.app.banCoTinNhanMoi,
          payload: conversationId == null
              ? '/messages'
              : '/messages/${Uri.encodeComponent(conversationId)}',
        );
      case 'message:created':
        if (_ownMessage(data)) return;
        final channelId = _text(data['channelId']);
        final slug = channelId == null ? null : channelSlug(channelId);
        await show(
          id: (_text(data['id']) ?? event.eventId).hashCode,
          title: _authorName(data) ?? vi.app.kenhChat,
          body: _text(data['content']) ?? vi.app.coTinNhanMoiTrongKenh,
          payload: slug == null
              ? '/channels'
              : '/channels/${Uri.encodeComponent(slug)}',
        );
    }
  }

  /// Realtime notification events carry only the notification id, so the
  /// newest page is read to describe it the way the notifications list does.
  Future<void> _presentNotice(Map<String, Object?> data) async {
    final id = _text(data['id']);
    if (id == null) return;
    CommunityNotice? notice;
    try {
      final page = await loadLatestNotices();
      notice = page.items.where((item) => item.id == id).firstOrNull;
    } on AppFailure {
      notice = null;
    }
    if (notice != null && !notice.unread) return;
    await show(
      // An aggregated update replaces the earlier system notification.
      id: id.hashCode,
      title: notice == null || notice.actor.displayName.isEmpty
          ? vi.app.tieuDeUngDung
          : notice.actor.displayName,
      body: notice == null ? vi.app.banCoHoatDongMoi : _noticeBody(notice),
      payload: (notice == null ? null : noticeRoute(notice)) ?? '/',
    );
  }

  String _noticeBody(CommunityNotice notice) {
    final action = noticeAction(notice.type);
    final subject = notice.title.isNotEmpty ? notice.title : notice.excerpt;
    return subject.isEmpty ? action : '$action: $subject';
  }

  bool _ownMessage(Map<String, Object?> data) {
    final author = data['author'];
    final authorId =
        (author is Map ? _text(author['id']) : null) ?? _text(data['authorId']);
    return authorId != null && authorId == currentUserId;
  }

  String? _authorName(Map<String, Object?> data) {
    final author = data['author'];
    if (author is! Map) return null;
    return _text(author['displayName']) ?? _text(author['username']);
  }
}

String? _text(Object? value) =>
    value is String && value.trim().isNotEmpty ? value : null;
