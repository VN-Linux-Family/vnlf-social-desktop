import 'package:flutter/widgets.dart';

/// Builds what a member's name or avatar shows when hovered or long-pressed.
typedef VnlfProfilePreviewBuilder = Widget Function(
  BuildContext context,
  String username,
  Widget child,
);

/// Lets the app give every link to a member's profile the website's profile
/// card (`profile-card.tsx`). Without a scope, [wrap] returns the child as
/// it is.
class VnlfProfilePreview extends InheritedWidget {
  const VnlfProfilePreview({
    super.key,
    required this.builder,
    required super.child,
  });

  final VnlfProfilePreviewBuilder builder;

  /// [child] links to [username]'s profile.
  static Widget wrap(BuildContext context, String username, Widget child) {
    if (username.isEmpty) return child;
    final scope = context
        .dependOnInheritedWidgetOfExactType<VnlfProfilePreview>();
    return scope == null ? child : scope.builder(context, username, child);
  }

  @override
  bool updateShouldNotify(VnlfProfilePreview oldWidget) =>
      builder != oldWidget.builder;
}
