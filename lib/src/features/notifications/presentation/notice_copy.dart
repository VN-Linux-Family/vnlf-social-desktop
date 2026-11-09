import '../../../i18n/vi.dart';
import '../domain/notifications_repository.dart';

/// The in-app location for [item], or null when only its link can open it.
String? noticeRoute(CommunityNotice item) {
  if (item.targetType == 'ARTICLE' && item.targetId.isNotEmpty) {
    return '/thread/${Uri.encodeComponent(item.targetId)}';
  }
  if (item.targetType == 'USER' && item.actor.username.isNotEmpty) {
    return '/profile/${Uri.encodeComponent(item.actor.username)}';
  }
  if (item.targetType == 'CONVERSATION' && item.targetId.isNotEmpty) {
    return '/messages/${Uri.encodeComponent(item.targetId)}';
  }
  if (item.targetType == 'FEEDBACK' && item.targetId.isNotEmpty) {
    return '/feedback/${Uri.encodeComponent(item.targetId)}';
  }
  final href = Uri.tryParse(item.href);
  if (item.targetType == 'GUESTBOOK' &&
      href != null &&
      !href.hasScheme &&
      !href.hasAuthority &&
      href.path.startsWith('/') &&
      href.pathSegments.length == 2 &&
      href.pathSegments.first == 'u' &&
      href.pathSegments.last.isNotEmpty &&
      href.queryParameters['tab'] == 'guestbook') {
    return '/profile/${Uri.encodeComponent(href.pathSegments.last)}?tab=guestbook';
  }
  if (href != null &&
      !href.hasScheme &&
      !href.hasAuthority &&
      href.pathSegments.length == 2 &&
      href.pathSegments.first == 'projects' &&
      href.pathSegments.last.isNotEmpty &&
      href.path.startsWith('/')) {
    return '/projects/${Uri.encodeComponent(href.pathSegments.last)}';
  }
  return null;
}

/// The action phrase the notifications list shows for a notice type.
String noticeAction(String type) => switch (type) {
  'article-liked' => vi.app.notifications.daThichBaiViet,
  'comment-liked' => vi.app.notifications.daThichBinhLuan,
  'comment-created' => vi.app.notifications.daBinhLuanBai,
  'comment-replied' => vi.app.notifications.daTraLoiBinh,
  'user-followed' => vi.app.notifications.daTheoDoiBan,
  'guestbook-signed' => vi.app.notifications.daVietVaoSo,
  _ => vi.app.notifications.capNhatCongDong,
};
