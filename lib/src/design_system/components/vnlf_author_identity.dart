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
    this.allowWrap = true,
    this.semanticLabel,
    this.distroBadgeTooltip,
    this.distroBadgeSemanticLabel,
    this.terminalBadgeSemanticLabel,
    this.pixelBadgeSemanticLabel,
    this.partnerStarSemanticLabel,
  });

  final AuthorData author;
  final bool showHandleInline;
  final double fontSize;
  final bool allowWrap;
  final String? semanticLabel;
  final String? distroBadgeTooltip;
  final String? distroBadgeSemanticLabel;
  final String? terminalBadgeSemanticLabel;
  final String? pixelBadgeSemanticLabel;
  final String? partnerStarSemanticLabel;

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
      softWrap: allowWrap,
      maxLines: allowWrap ? null : 1,
      overflow: allowWrap ? null : TextOverflow.ellipsis,
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

    final row = Wrap(
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
          VnlfInlineDistroIcon(
            badge: style.distroBadge,
            tooltip: distroBadgeTooltip ?? style.distroBadgeLabel,
            semanticLabel: distroBadgeSemanticLabel ?? style.distroBadgeLabel,
          ),
        if (style.hasTerminalBadge)
          _TerminalMiniBadge(semanticLabel: terminalBadgeSemanticLabel),
        if (style.hasPixelBadge)
          _PixelHelmBadge(semanticLabel: pixelBadgeSemanticLabel),
        if (style.hasPartnerStar)
          _GoldStarMiniBadge(semanticLabel: partnerStarSemanticLabel),
        if (showHandleInline)
          Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Text(
              '@${author.username}',
              softWrap: allowWrap,
              style: VnlfTypography.meta(colors.muted).copyWith(fontSize: 12.5),
            ),
          ),
      ],
    );

    if (semanticLabel == null) {
      return row;
    }
    return Semantics(label: semanticLabel, container: true, child: row);
  }
}

/// Compact inline distro icon matching the cyan/green/blue mini badges next to
/// author display names in `reference_feed_desktop.png`.
class VnlfInlineDistroIcon extends StatelessWidget {
  const VnlfInlineDistroIcon({
    super.key,
    required this.badge,
    this.size = 15.0,
    this.tooltip,
    this.semanticLabel,
  });

  final DistroBadgeType badge;
  final double size;
  final String? tooltip;
  final String? semanticLabel;

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

    Widget badgeWidget = Container(
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
    );

    if (tooltip != null && tooltip!.isNotEmpty) {
      badgeWidget = Tooltip(message: tooltip!, child: badgeWidget);
    }
    if (semanticLabel != null) {
      badgeWidget = Semantics(label: semanticLabel, child: badgeWidget);
    }
    return badgeWidget;
  }
}

/// Full labeled distro badge pill (`caramos`, `cachyos`, `arch`, `debian`, `nixos`)
/// for profile headers, thread details, and the component gallery.
class VnlfDistroBadgePill extends StatelessWidget {
  const VnlfDistroBadgePill({
    super.key,
    required this.badge,
    this.label = '',
    this.iconTooltip,
    this.semanticLabel,
  });

  final DistroBadgeType badge;
  final String label;
  final String? iconTooltip;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    if (badge == DistroBadgeType.none) return const SizedBox.shrink();
    final colors = VnlfColors.of(context);

    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: colors.surfaceSoft,
        borderRadius: BorderRadius.circular(VnlfDimensions.radiusSm),
        border: Border.all(color: colors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          VnlfInlineDistroIcon(badge: badge, size: 13, tooltip: iconTooltip),
          if (label.isNotEmpty) ...[
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: VnlfTypography.caption(colors.ink),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );

    if (semanticLabel == null) {
      return pill;
    }
    return Semantics(label: semanticLabel, container: true, child: pill);
  }
}

class _TerminalMiniBadge extends StatelessWidget {
  const _TerminalMiniBadge({this.semanticLabel});

  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final badge = Container(
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
    if (semanticLabel == null) return badge;
    return Semantics(label: semanticLabel, child: badge);
  }
}

class _PixelHelmBadge extends StatelessWidget {
  const _PixelHelmBadge({this.semanticLabel});

  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final badge = Container(
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
    if (semanticLabel == null) return badge;
    return Semantics(label: semanticLabel, child: badge);
  }
}

class _GoldStarMiniBadge extends StatelessWidget {
  const _GoldStarMiniBadge({this.semanticLabel});

  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final badge = Container(
      width: 15,
      height: 15,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: colors.amber, shape: BoxShape.circle),
      child: Icon(Icons.star_rounded, size: 10.5, color: colors.surface),
    );
    if (semanticLabel == null) return badge;
    return Semantics(label: semanticLabel, child: badge);
  }
}
