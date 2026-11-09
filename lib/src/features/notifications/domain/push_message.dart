import 'dart:convert';

/// A message from the server's push worker (`pushCopy` in
/// `apps/worker/src/push.ts`), read the way the website's service worker
/// reads it (`apps/web/public/push-sw.js`).
final class PushMessage {
  const PushMessage({
    required this.path,
    required this.tag,
    this.body,
    this.urgent = false,
    this.requireInteraction = false,
  });

  /// The page the service worker opens when the payload names none.
  static const fallbackPath = '/notifications';

  /// The service worker's tag when the payload has none.
  static const fallbackTag = 'vnlf-notification';

  /// A page of the website, such as `/messages/<id>`.
  final String path;

  /// A newer message with the same tag replaces the one on screen.
  final String tag;

  /// The text to show, or null when the payload has none.
  final String? body;

  /// Shown even while the app is in front: account and security changes.
  final bool urgent;

  /// Stays on screen until dismissed: direct messages, message requests and
  /// account changes.
  final bool requireInteraction;

  /// Reads a decrypted push body. Returns null for what the service worker
  /// drops: a body that is not a JSON object, or a page off the website.
  static PushMessage? decode(List<int> bytes) {
    final Object? json;
    try {
      json = jsonDecode(utf8.decode(bytes));
    } on FormatException {
      return null;
    }
    if (json is! Map<String, Object?>) return null;
    final url = json['url'];
    final path = url is String && url.startsWith('/') && !url.startsWith('//')
        ? url
        : fallbackPath;
    if (!_staysOnSite(path)) return null;
    final tag = json['tag'];
    final body = json['body'];
    return PushMessage(
      path: path,
      tag: tag is String ? tag : fallbackTag,
      body: body is String ? body : null,
      urgent: json['urgent'] == true,
      requireInteraction: json['requireInteraction'] == true,
    );
  }
}

/// The service worker resolves the path with `new URL`, which drops tabs and
/// line breaks and reads a backslash as a slash, and shows nothing when the
/// result is on another host.
bool _staysOnSite(String path) {
  final resolved = path
      .replaceAll(RegExp('[\t\n\r]'), '')
      .replaceAll(r'\', '/');
  return resolved.startsWith('/') && !resolved.startsWith('//');
}
