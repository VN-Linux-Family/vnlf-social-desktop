import 'package:flutter/widgets.dart';

import '../../../design_system/design_system.dart';
import '../../../domain/models.dart';
import 'author_mapper.dart';

/// The signed-in member as an author, for avatars and name rows.
AuthorData sessionAuthor(Session session) => presentAuthor(
  Author(
    id: session.userId,
    username: session.username,
    displayName: session.displayName,
    avatarUrl: session.avatarUrl,
    role: session.role,
    style: session.style,
  ),
);

/// The viewer's own avatar, or the website's guest "?" when nobody is
/// signed in. [cornerRadius] makes a rounded square instead of a circle.
Widget sessionAvatar(
  Session? session, {
  required double size,
  double? cornerRadius,
}) {
  if (session == null) {
    return VnlfGuestAvatarBox(size: size, isCircle: cornerRadius == null);
  }
  return VnlfAvatar(
    author: sessionAuthor(session),
    size: size,
    cornerRadius: cornerRadius,
  );
}
