/// A link card's content from `GET /api/v1/link-preview`.
final class LinkPreview {
  const LinkPreview({
    required this.url,
    required this.title,
    required this.description,
    required this.siteName,
    this.imageUrl,
  });

  final String url;
  final String title;
  final String description;
  final String siteName;
  final String? imageUrl;
}

abstract interface class LinkPreviewRepository {
  /// The card for [url], or null when the server has none.
  Future<LinkPreview?> preview(String url);

  /// The address that loads [imageUrl] through the server's image proxy,
  /// as the website does, so the photo's site never sees the reader.
  String proxiedImage(String imageUrl);
}

final _link = RegExp(
  r'''\b(?:https?://|www\.)[^\s<>"']+''',
  caseSensitive: false,
);

/// The first web link in [content], cleaned like the website's
/// `contentLinks`: trailing punctuation and unmatched closing brackets go.
String? firstContentLink(String content) {
  for (final match in _link.allMatches(content)) {
    var text = match[0]!.replaceFirst(RegExp(r'[.,!?;:]+$'), '');
    for (final (open, close) in const [('(', ')'), ('[', ']'), ('{', '}')]) {
      while (text.endsWith(close) &&
          close.allMatches(text).length > open.allMatches(text).length) {
        text = text.substring(0, text.length - 1);
      }
    }
    final uri = Uri.tryParse(
      text.toLowerCase().startsWith('www.') ? 'https://$text' : text,
    );
    if (uri == null ||
        !{'http', 'https'}.contains(uri.scheme.toLowerCase()) ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty) {
      continue;
    }
    return uri.toString();
  }
  return null;
}

const _youtubeHosts = {
  'youtube.com',
  'www.youtube.com',
  'm.youtube.com',
  'music.youtube.com',
  'youtu.be',
  'www.youtube-nocookie.com',
  'youtube-nocookie.com',
};
final _youtubeId = RegExp(r'^[A-Za-z0-9_-]{11}$');

/// The YouTube video id in [url], for the links people paste (watch,
/// youtu.be, music, shorts, embed, live), like the website's parser.
String? youtubeVideoId(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null || !_youtubeHosts.contains(uri.host.toLowerCase())) {
    return null;
  }
  final parts = uri.pathSegments.where((part) => part.isNotEmpty).toList();
  final first = parts.isEmpty ? null : parts.first;
  final String? id;
  if (uri.host.toLowerCase() == 'youtu.be') {
    id = first;
  } else if (first == 'watch') {
    id = uri.queryParameters['v'];
  } else if (const {'shorts', 'embed', 'live', 'v'}.contains(first) &&
      parts.length > 1) {
    id = parts[1];
  } else {
    id = null;
  }
  return id != null && _youtubeId.hasMatch(id) ? id : null;
}
