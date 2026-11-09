import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../domain/models.dart';
import '../../../i18n/vi.dart';

/// The website's public article route uses the server-provided slug.
Uri? canonicalPostUri(FeedPost post) => post.slug.isEmpty
    ? null
    : Uri(
        scheme: 'https',
        host: 'vietnamlinuxfamily.net',
        pathSegments: ['a', post.slug],
      );

Future<void> copyPostLink(BuildContext context, FeedPost post) async {
  final uri = canonicalPostUri(post);
  String message;
  if (uri == null) {
    message = vi.app.shared.baiVietChuaCo;
  } else {
    try {
      await Clipboard.setData(ClipboardData(text: uri.toString()));
      message = vi.socialOverlays.daSaoChepLienKet;
    } on PlatformException {
      message = vi.app.shared.khongTheSaoChep;
    }
  }
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
