import 'package:flutter/material.dart';

import '../models/vnlf_models.dart';
import '../tokens/vnlf_colors.dart';
import '../tokens/vnlf_dimensions.dart';
import '../tokens/vnlf_typography.dart';

/// Renders an author's stylized display name (`nameColor`, `nameGradient`,
/// `nameEffect` such as `cursor` `█` or `rainbow`) alongside inline distro
/// and achievement badges.
class VnlfAuthorNameRow extends StatelessWidget {
  const VnlfAuthorNameRow({
    super.key,
    required this.author,
    this.showHandleInline = true,
    this.fontSize = 13.5,
  });

  final AuthorData author;
  final bool showHandleInline;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final style = author.style;

    final baseTextStyle = TextStyle(
      fontFamily: VnlfTypography.fontFamily,
      fontSize: fontSize,
      height: 18 / 13.5,
      fontWeight: FontWeight.w700,
      color: style.nameColor ?? colors.ink,
    );

    final gradientColors = colors.isDark
        ? (style.nameGradientDark ?? style.nameGradientLight)
        : style.nameGradientLight;

    Widget nameText = Text(
      author.displayName,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: style.nameEffect == NameEffectType.glitch
          ? baseTextStyle.copyWith(
              shadows: [
                Shadow(color: colors.cyan, offset: const Offset(-0.8, 0)),
                Shadow(color: colors.red, offset: const Offset(0.8, 0)),
              ],
            )
          : baseTextStyle,
    );

    if (style.nameEffect == NameEffectType.rainbow) {
      nameText = ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (bounds) => LinearGradient(
          colors: [colors.brand, colors.cyan, colors.purple, colors.red],
        ).createShader(bounds),
        child: nameText,
      );
    } else if (gradientColors != null && gradientColors.length >= 2) {
      nameText = ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (bounds) =>
            LinearGradient(colors: gradientColors).createShader(bounds),
        child: nameText,
      );
    }

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      runSpacing: 2,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: nameText),
            if (style.nameEffect == NameEffectType.cursor) ...[
              const SizedBox(width: 2),
              Container(
                width: 7,
                height: fontSize * 0.95,
                decoration: BoxDecoration(
                  color: colors.ink,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ],
          ],
        ),
        if (style.distroBadge != DistroBadgeType.none)
          VnlfInlineDistroIcon(badge: style.distroBadge),
        if (style.hasTerminalBadge) const _TerminalMiniBadge(),
        if (style.hasPixelBadge) const _PixelHelmBadge(),
        if (style.hasPartnerStar) const _GoldStarMiniBadge(),
        if (showHandleInline)
          Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Text(
              '@${author.username}',
              style: VnlfTypography.meta(colors.muted).copyWith(fontSize: 12.5),
            ),
          ),
      ],
    );
  }
}

/// Compact inline distro icon matching the cyan/green/blue mini badges next to
/// author display names in `reference_feed_desktop.png`.
class VnlfInlineDistroIcon extends StatelessWidget {
  const VnlfInlineDistroIcon({
    super.key,
    required this.badge,
    this.size = 15.0,
  });

  final DistroBadgeType badge;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final (Color bg, Color fg, String glyph) = switch (badge) {
      DistroBadgeType.cachyos => (colors.cyan, colors.surface, 'C'),
      DistroBadgeType.caramos => (colors.green, colors.surface, 'C'),
      DistroBadgeType.arch => (colors.blue, colors.surface, 'A'),
      DistroBadgeType.debian => (colors.red, colors.surface, 'D'),
      DistroBadgeType.nixos => (colors.cyan, colors.surface, 'N'),
      DistroBadgeType.fedora => (colors.blue, colors.surface, 'f'),
      DistroBadgeType.none => (Colors.transparent, Colors.transparent, ''),
    };

    if (badge == DistroBadgeType.none) return const SizedBox.shrink();

    return Tooltip(
      message: badge.label,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Text(
          glyph,
          style: TextStyle(
            fontFamily: VnlfTypography.fontFamily,
            fontSize: size * 0.62,
            height: 1.0,
            fontWeight: FontWeight.w800,
            color: fg,
          ),
        ),
      ),
    );
  }
}

/// Full labeled distro badge pill (`caramos`, `cachyos`, `arch`, `debian`, `nixos`)
/// for profile headers, thread details, and the component gallery.
class VnlfDistroBadgePill extends StatelessWidget {
  const VnlfDistroBadgePill({super.key, required this.badge});

  final DistroBadgeType badge;

  @override
  Widget build(BuildContext context) {
    if (badge == DistroBadgeType.none) return const SizedBox.shrink();
    final colors = VnlfColors.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: colors.surfaceSoft,
        borderRadius: BorderRadius.circular(VnlfDimensions.radiusSm),
        border: Border.all(color: colors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          VnlfInlineDistroIcon(badge: badge, size: 13),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              badge.label,
              style: VnlfTypography.caption(colors.ink),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _TerminalMiniBadge extends StatelessWidget {
  const _TerminalMiniBadge();

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    return Container(
      width: 15,
      height: 15,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.brand,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '>_',
        style: TextStyle(
          fontFamily: VnlfTypography.monoFontFamily,
          fontSize: 7.5,
          height: 1.0,
          fontWeight: FontWeight.w700,
          color: colors.surface,
        ),
      ),
    );
  }
}

class _PixelHelmBadge extends StatelessWidget {
  const _PixelHelmBadge();

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    return Container(
      width: 15,
      height: 15,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.surfaceSoft,
        shape: BoxShape.circle,
        border: Border.all(color: colors.muted.withValues(alpha: 0.5)),
      ),
      child: Icon(Icons.terminal_rounded, size: 10, color: colors.ink),
    );
  }
}

class _GoldStarMiniBadge extends StatelessWidget {
  const _GoldStarMiniBadge();

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    return Container(
      width: 15,
      height: 15,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: colors.amber, shape: BoxShape.circle),
      child: Icon(Icons.star_rounded, size: 10.5, color: colors.surface),
    );
  }
}
