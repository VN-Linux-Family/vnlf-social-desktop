import 'package:flutter/material.dart';

import '../models/vnlf_models.dart';
import '../tokens/vnlf_colors.dart';
import '../tokens/vnlf_dimensions.dart';
import '../tokens/vnlf_typography.dart';

/// Renders a user avatar with optional neutral generic ring frame
/// and fallback initials / icon. Zero network calls or bundled third-party photos.
class VnlfAvatar extends StatelessWidget {
  const VnlfAvatar({
    super.key,
    required this.author,
    this.size = 40.0,
    this.fallbackInitial = '',
    this.semanticLabel,
  });

  final AuthorData author;
  final double size;
  final String fallbackInitial;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final frame = author.style.frame;

    final initial = author.displayName.isNotEmpty
        ? author.displayName.characters.first.toUpperCase()
        : fallbackInitial;

    final coreAvatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colors.brandSoft,
        shape: BoxShape.circle,
        border: Border.all(color: colors.line),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: VnlfTypography.caption(
          colors.brand,
          fontWeight: FontWeight.w700,
        ).copyWith(fontSize: size * 0.42),
      ),
    );

    final Widget avatarWidget = frame == AvatarFrameType.ring
        ? Container(
            width: size + 6,
            height: size + 6,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: colors.brand, width: 1.5),
            ),
            child: coreAvatar,
          )
        : SizedBox(width: size, height: size, child: coreAvatar);

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

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);

    final box = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colors.surfaceSoft,
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircle
            ? null
            : BorderRadius.circular(VnlfDimensions.radiusMd),
        border: Border.all(color: colors.line),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.person_outline_rounded,
        size: size * 0.55,
        color: colors.muted,
      ),
    );

    if (semanticLabel == null) {
      return box;
    }
    return Semantics(label: semanticLabel, image: true, child: box);
  }
}
