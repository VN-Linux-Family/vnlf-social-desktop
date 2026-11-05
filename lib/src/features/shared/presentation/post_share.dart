import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../domain/models.dart';

/// The website's public article route uses the server-provided slug.
Uri? canonicalPostUri(FeedPost post) => post.slug.isEmpty
    ? null
    : Uri(
        scheme: 'https',
        host: 'vietnamlinuxfamily.net',
        pathSegments: ['a', post.slug],
      );

Future<void> copyPostLink(BuildContext context, FeedPost post) async {
  final english = Localizations.localeOf(context).languageCode == 'en';
  final uri = canonicalPostUri(post);
  String message;
  if (uri == null) {
    message = english
        ? 'This post has no public link'
        : 'Bài viết chưa có liên kết công khai';
  } else {
    try {
      await Clipboard.setData(ClipboardData(text: uri.toString()));
      message = english ? 'Link copied' : 'Đã sao chép liên kết';
    } on PlatformException {
      message = english ? 'Unable to copy link' : 'Không thể sao chép liên kết';
    }
  }
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
