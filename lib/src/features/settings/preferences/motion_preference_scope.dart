import 'package:flutter/widgets.dart';

/// Combines the account preference with the operating system's accessibility setting.
final class MotionPreferenceScope extends StatelessWidget {
  const MotionPreferenceScope({
    required this.reduceMotion,
    required this.child,
    super.key,
  });

  final bool reduceMotion;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return MediaQuery(
      data: media.copyWith(
        disableAnimations: media.disableAnimations || reduceMotion,
      ),
      child: child,
    );
  }
}
