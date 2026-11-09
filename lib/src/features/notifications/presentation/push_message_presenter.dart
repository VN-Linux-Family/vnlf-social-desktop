import 'dart:convert';

import '../../../core/vnlf_navigation_helper.dart';
import '../../../i18n/vi.dart';
import '../domain/push_message.dart';

typedef ShowPushNotification = Future<void> Function({
  required int id,
  required String title,
  required String body,
  String? payload,
  bool persistent,
});

/// Shows the server's push messages as system notifications, the way the
/// website's service worker (`push-sw.js`) does.
final class PushMessagePresenter {
  const PushMessagePresenter({
    required this.show,
    required this.appInFront,
    required this.website,
  });

  final ShowPushNotification show;

  /// Whether the app is visible and focused, like a focused website tab.
  final bool Function() appInFront;

  /// The website the message paths belong to.
  final Uri website;

  Future<void> present(PushMessage message) async {
    // A focused tab shows new activity itself, so the service worker skips
    // every message but the urgent ones.
    if (!message.urgent && appInFront()) return;
    await show(
      id: pushNotificationId(message.tag),
      title: vi.app.notifications.tieuDeThongBaoDay,
      body: message.body ?? vi.app.notifications.banCoHoatDongMoiDay,
      payload: pushTarget(message.path, website),
      persistent: message.requireInteraction,
    );
  }
}

/// The notification id for a tag. It stays the same across launches, so a
/// newer message with the same tag replaces the one on screen, like the
/// website's `tag`.
int pushNotificationId(String tag) {
  // 32-bit FNV-1a, kept positive for the platforms' int notification ids.
  var hash = 0x811c9dc5;
  for (final byte in utf8.encode(tag)) {
    hash = ((hash ^ byte) * 0x01000193) & 0xffffffff;
  }
  return hash & 0x7fffffff;
}

/// The app route for a website path, or the website's page when the app has
/// no screen for it.
String pushTarget(String path, Uri website) {
  final uri = Uri.tryParse(path);
  if (uri == null) return website.resolve(PushMessage.fallbackPath).toString();
  return resolveInAppVnlfRoute(uri) ?? website.resolve(path).toString();
}
