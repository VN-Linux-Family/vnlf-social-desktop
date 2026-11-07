import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

/// Checks if the given host belongs to the VNLF website.
bool isVnlfHost(String? host) {
  if (host == null) return false;
  final h = host.toLowerCase();
  return h == 'vietnamlinuxfamily.net' ||
      h == 'www.vietnamlinuxfamily.net' ||
      h == 'localhost';
}

/// Resolves a URL to an internal in-app route if it belongs to VNLF.
/// Returns null if the URL cannot be resolved to an in-app screen
/// and should be opened externally.
String? resolveInAppVnlfRoute(Uri uri) {
  final isCustomScheme = uri.scheme.toLowerCase() == 'vnlf';
  final isWebVnlf =
      uri.scheme.toLowerCase() == 'http' || uri.scheme.toLowerCase() == 'https';
  final isRelative = uri.scheme.isEmpty && uri.host.isEmpty;

  if (!isCustomScheme && !isRelative && (!isWebVnlf || !isVnlfHost(uri.host))) {
    return null;
  }

  // Normalize path segments
  final segments = uri.scheme.toLowerCase() == 'vnlf' && uri.host.isNotEmpty
      ? [uri.host, ...uri.pathSegments]
      : uri.pathSegments;
  if (segments.isEmpty) {
    return '/';
  }

  final first = segments[0].toLowerCase();
  switch (first) {
    case 'a':
    case 'article':
    case 'articles':
    case 'thread':
    case 'posts':
    case 'post':
      if (segments.length >= 2 && segments[1].isNotEmpty) {
        return '/thread/${Uri.encodeComponent(segments[1])}';
      }
      return '/';

    case 'profile':
    case 'user':
    case 'users':
    case 'u':
      if (segments.length >= 2 && segments[1].isNotEmpty) {
        final username = Uri.encodeComponent(segments[1]);
        final tab = uri.queryParameters['tab'];
        return tab != null
            ? '/profile/$username?tab=$tab'
            : '/profile/$username';
      }
      return null;

    case 'projects':
    case 'project':
      if (segments.length >= 2 && segments[1].isNotEmpty) {
        if (segments[1] == 'submit') return '/projects/submit';
        return '/projects/${Uri.encodeComponent(segments[1])}';
      }
      return '/projects';

    case 'discover':
    case 'explore':
      return '/discover';

    case 'leaderboard':
      return '/leaderboard';

    case 'activity':
      return '/activity';

    case 'channels':
    case 'messages':
      if (segments.length >= 2 && segments[1].isNotEmpty) {
        return '/channels/${Uri.encodeComponent(segments[1])}';
      }
      return '/channels';

    case 'voice':
      return '/voice';

    case 'settings':
      return '/settings';

    case 'search':
      final q = uri.queryParameters['q'];
      return q != null ? '/search?q=${Uri.encodeComponent(q)}' : '/search';

    case 'feedback':
      if (segments.length >= 2 && segments[1].isNotEmpty) {
        return '/feedback/${Uri.encodeComponent(segments[1])}';
      }
      return '/feedback';

    case 'login':
      return '/login';

    case 'compose':
      return '/compose';

    default:
      // Other website pages like /caramos, /privacy, etc. open in external browser
      return null;
  }
}

/// Opens a URL by checking if it can be handled natively in-app first.
/// If not, launches the system browser.
Future<bool> openVnlfLink(BuildContext context, String rawUrl) async {
  final trimmed = rawUrl.trim();
  if (trimmed.isEmpty) return false;

  Uri? uri = Uri.tryParse(trimmed);
  if (uri == null) return false;

  // Handle root-relative paths like /a/my-slug
  if (trimmed.startsWith('/')) {
    uri = Uri.parse('https://vietnamlinuxfamily.net').resolve(trimmed);
  }

  final internalRoute = resolveInAppVnlfRoute(uri);
  if (internalRoute != null && context.mounted) {
    try {
      GoRouter.of(context).push(internalRoute);
      return true;
    } catch (_) {
      // In case router navigation fails, continue to external launch
    }
  }

  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}
