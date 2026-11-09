/// The platforms a profile link can point to, in the website's order
/// (`packages/contracts/src/profile-links.ts`).
enum LinkPlatform {
  facebook(['facebook.com', 'fb.com', 'fb.me', 'fb.watch']),
  instagram(['instagram.com', 'instagr.am']),
  youtube(['youtube.com', 'youtu.be']),
  tiktok(['tiktok.com']),
  github(['github.com']),
  gitlab(['gitlab.com']),
  x(['x.com', 'twitter.com']),
  threads(['threads.net', 'threads.com']),
  reddit(['reddit.com', 'redd.it']),
  telegram(['t.me', 'telegram.me', 'telegram.dog']),
  discord(['discord.gg', 'discord.com', 'discordapp.com']),
  linkedin(['linkedin.com', 'lnkd.in']),
  twitch(['twitch.tv']),
  codeberg(['codeberg.org']),
  bluesky(['bsky.app']),
  zalo(['zalo.me']);

  const LinkPlatform(this.hosts);

  /// Its domains; their subdomains count too.
  final List<String> hosts;
}

/// A link under a profile's bio, made safe to show.
final class ProfileLink {
  const ProfileLink({
    required this.url,
    required this.platform,
    required this.label,
  });

  final String url;

  /// Null for any other site.
  final LinkPlatform? platform;

  /// The handle read from the link (`@dungle`, `u/dungle`,
  /// `dungle/dotfiles`) or, failing that, the domain.
  final String label;
}

/// A profile shows at most this many links.
const profileLinksMax = 4;
const _urlMax = 200;

/// The platform a hostname belongs to, or null for any other site.
/// Lookalikes such as `notgithub.com` or `github.com.evil.io` do not match.
LinkPlatform? linkPlatform(String hostname) {
  final host = hostname.toLowerCase().replaceFirst(RegExp(r'\.$'), '');
  for (final platform in LinkPlatform.values) {
    if (platform.hosts.any(
      (domain) => host == domain || host.endsWith('.$domain'),
    )) {
      return platform;
    }
  }
  return null;
}

// Spaces, control characters and bidirectional overrides have no place in a
// link someone else will click.
final _unsafe = RegExp(
  r'[\s\u0000-\u001f\u007f-\u009f\u00ad\u200b-\u200f\u2028\u2029'
  r'\u202a-\u202e\u2060-\u2064\u2066-\u2069\ufeff]',
);
// A dotted name with an alphabetic (or punycode) top-level label: no
// localhost and no bare IP addresses.
final _domain = RegExp(
  r'^(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+(?:[a-z]{2,63}|xn--[a-z0-9-]{1,59})$',
);
final _handle = RegExp(r'^[\p{L}\p{N}._-]{1,64}$', unicode: true);
final _scheme = RegExp(r'^[a-z][a-z0-9+.-]*:', caseSensitive: false);

String? _segment(String? value) {
  if (value == null || value.isEmpty) return null;
  final String decoded;
  try {
    decoded = Uri.decodeComponent(value);
  } on ArgumentError {
    return null;
  } on FormatException {
    return null;
  }
  return _handle.hasMatch(decoded) ? decoded : null;
}

/// What a link's button says: a handle for the platforms whose links carry
/// one, otherwise the domain.
String linkLabel(LinkPlatform? platform, Uri url) {
  final host = url.host.toLowerCase().replaceFirst(RegExp('^www\\.'), '');
  final parts = url.path.split('/').where((part) => part.isNotEmpty).toList();
  final first = parts.firstOrNull ?? '';
  final second = _segment(parts.elementAtOrNull(1));
  String? at(String? value) =>
      value == null ? null : '@${value.replaceFirst(RegExp('^@'), '')}';
  final handle = _segment(first.replaceFirst(RegExp('^@'), ''));
  final label = switch (platform) {
    LinkPlatform.github || LinkPlatform.gitlab || LinkPlatform.codeberg =>
      handle != null && !first.startsWith('@')
          ? [handle, ?second].join('/')
          : null,
    LinkPlatform.instagram =>
      handle != null &&
              !const [
                'p',
                'reel',
                'reels',
                'stories',
                'explore',
                'tv',
              ].contains(first)
          ? at(handle)
          : null,
    LinkPlatform.x =>
      handle != null &&
              !const [
                'i',
                'home',
                'intent',
                'search',
                'hashtag',
                'share',
              ].contains(first)
          ? at(handle)
          : null,
    LinkPlatform.twitch =>
      handle != null && !const ['videos', 'directory', 'search'].contains(first)
          ? at(handle)
          : null,
    LinkPlatform.telegram =>
      handle != null &&
              !const [
                'joinchat',
                's',
                'c',
                'addstickers',
                'share',
              ].contains(first) &&
              !first.startsWith('+')
          ? at(handle)
          : null,
    LinkPlatform.tiktok ||
    LinkPlatform.threads => first.startsWith('@') ? at(handle) : null,
    LinkPlatform.youtube =>
      first.startsWith('@')
          ? at(handle)
          : const ['c', 'user'].contains(first)
          ? second
          : null,
    LinkPlatform.facebook =>
      handle != null &&
              !first.contains('.php') &&
              !const [
                'people',
                'groups',
                'pages',
                'share',
                'watch',
                'events',
                'photo',
                'reel',
                'story',
                'login',
                'hashtag',
              ].contains(first)
          ? handle
          : null,
    LinkPlatform.reddit =>
      second != null && const ['user', 'u'].contains(first)
          ? 'u/$second'
          : second != null && first == 'r'
          ? 'r/$second'
          : null,
    LinkPlatform.linkedin =>
      second != null && const ['in', 'company', 'school', 'pub'].contains(first)
          ? second
          : null,
    LinkPlatform.discord =>
      host == 'discord.gg' && handle != null
          ? 'discord.gg/$handle'
          : first == 'invite' && second != null
          ? 'discord.gg/$second'
          : null,
    LinkPlatform.bluesky =>
      first == 'profile' && second != null ? at(second) : null,
    // Zalo links carry phone numbers: show only the domain.
    LinkPlatform.zalo || null => null,
  };
  return label ?? host;
}

/// The website's `parseProfileLink`: http(s) only, no user name or password,
/// a real domain, at most 200 characters. Without a scheme, `https://` is
/// assumed. Null when the link is not safe to show.
ProfileLink? parseProfileLink(String input) {
  final raw = input.trim();
  if (raw.isEmpty || raw.length > _urlMax || _unsafe.hasMatch(raw)) {
    return null;
  }
  final parsed = Uri.tryParse(_scheme.hasMatch(raw) ? raw : 'https://$raw');
  if (parsed == null ||
      (parsed.scheme != 'https' && parsed.scheme != 'http') ||
      parsed.userInfo.isNotEmpty) {
    return null;
  }
  // A browser writes an empty path as "/".
  final url = parsed.path.isEmpty ? parsed.replace(path: '/') : parsed;
  final host = url.host.toLowerCase();
  final href = url.toString();
  if (!_domain.hasMatch(host) || href.length > _urlMax) return null;
  final platform = linkPlatform(host);
  return ProfileLink(
    url: href,
    platform: platform,
    label: linkLabel(platform, url),
  );
}
