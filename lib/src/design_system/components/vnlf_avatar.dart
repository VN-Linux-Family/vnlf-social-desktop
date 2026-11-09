import 'package:flutter/material.dart';

import '../models/vnlf_models.dart';
import '../tokens/vnlf_colors.dart';
import '../tokens/vnlf_dimensions.dart';
import '../tokens/vnlf_typography.dart';

/// Renders a user avatar with optional neutral generic ring frame
/// and fallback initials. Network images are explicitly enabled by the app.
/// The website's avatar (avatar-content): the photo, or initials in white
/// on the forest tone, as a circle or a rounded square. A `ring` frame is a
/// 3px ring drawn 5px outside without changing the layout size.
class VnlfAvatar extends StatelessWidget {
  const VnlfAvatar({
    super.key,
    required this.author,
    this.size = 40.0,
    this.cornerRadius,
    this.fallbackInitial = '',
    this.semanticLabel,
  });

  final AuthorData author;
  final double size;

  /// A rounded square with this radius (the sidebar, header and leaderboard
  /// use 10); a circle when null.
  final double? cornerRadius;
  final String fallbackInitial;
  final String? semanticLabel;

  /// First letters of the first and last word, or the first two letters of
  /// a single word, as the website's initials().
  static String initialsOf(String name, [String fallback = '']) {
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    if (words.isEmpty) return fallback;
    final letters = words.length > 1
        ? '${words.first.characters.first}${words.last.characters.first}'
        : words.first.characters.take(2).toString();
    return letters.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final frame = author.style.frame;
    final radius = cornerRadius == null
        ? null
        : BorderRadius.circular(cornerRadius!);

    final initials = Text(
      initialsOf(author.displayName, fallbackInitial),
      textScaler: TextScaler.noScaling,
      style: VnlfTypography.body(const Color(0xFFFFFFFF)).copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.04 * VnlfTypography.baseSize,
        height: 1,
      ),
    );
    final coreAvatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: VnlfGuestAvatarBox.forest,
        shape: radius == null ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: radius,
      ),
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      child: author.loadNetworkAvatar && author.avatarUrl.isNotEmpty
          ? Image.network(
              author.avatarUrl,
              width: size,
              height: size,
              fit: BoxFit.cover,
              cacheWidth: (size * MediaQuery.devicePixelRatioOf(context))
                  .round(),
              errorBuilder: (context, error, stackTrace) => initials,
            )
          : initials,
    );

    final Widget avatarWidget = frame == AvatarFrameType.ring
        ? SizedBox.square(
            dimension: size,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                coreAvatar,
                Positioned(
                  left: -5,
                  top: -5,
                  right: -5,
                  bottom: -5,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: radius == null
                            ? BoxShape.circle
                            : BoxShape.rectangle,
                        borderRadius: radius == null
                            ? null
                            : BorderRadius.circular(cornerRadius! + 5),
                        border: Border.all(
                          color:
                              (colors.isDark
                                  ? author.style.frameDarkColor ??
                                        author.style.frameColor
                                  : author.style.frameColor) ??
                              colors.brand,
                          width: 3,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        : SizedBox.square(dimension: size, child: coreAvatar);

    if (semanticLabel == null) {
      return avatarWidget;
    }
    return Semantics(label: semanticLabel, image: true, child: avatarWidget);
  }
}

/// Fallback avatar placeholder for guest/logged-out states.
class VnlfGuestAvatarBox extends StatelessWidget {
  const VnlfGuestAvatarBox({
    super.key,
    this.size = 36.0,
    this.isCircle = false,
    this.semanticLabel,
  });

  final double size;
  final bool isCircle;
  final String? semanticLabel;

  /// The website's guest avatar: "?" in white on the forest tone.
  static const forest = Color(0xFF2D6644);

  @override
  Widget build(BuildContext context) {
    final box = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: forest,
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircle
            ? null
            : BorderRadius.circular(VnlfDimensions.radiusMd),
      ),
      alignment: Alignment.center,
      child: Text(
        '?',
        textScaler: TextScaler.noScaling,
        style: VnlfTypography.body(const Color(0xFFFFFFFF))
            .copyWith(fontWeight: FontWeight.w800, height: 1),
      ),
    );

    if (semanticLabel == null) {
      return box;
    }
    return Semantics(label: semanticLabel, image: true, child: box);
  }
}
