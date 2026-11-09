import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/vnlf_models.dart';
import '../tokens/vnlf_colors.dart';
import '../tokens/vnlf_typography.dart';

/// Renders an author's stylized display name (`nameColor`, `nameGradient`,
/// `nameEffect` such as `cursor` `█` or `rainbow`) alongside inline distro
/// and achievement badges.
class VnlfAuthorNameRow extends StatelessWidget {
  const VnlfAuthorNameRow({
    super.key,
    required this.author,
    this.showHandleInline = true,
    this.plate = false,
    this.fontSize = VnlfTypography.baseSize,
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

  /// Draws the nameplate. The website shows plates only in member lists,
  /// conversation lists and the sidebar, never beside posts or messages.
  final bool plate;
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

    final resolvedNameColor = colors.isDark
        ? (style.nameDarkColor ?? style.nameColor ?? colors.ink)
        : (style.nameColor ?? colors.ink);

    final baseTextStyle = TextStyle(
      fontFamily: VnlfTypography.fontFamily,
      fontSize: fontSize,
      height: 18 / 13,
      fontWeight: FontWeight.w700,
      color: resolvedNameColor,
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
      // The website's gradient is three times the name's width, so a resting
      // name shows its red-to-orange start (profile-decor.css).
      nameText = ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (bounds) => LinearGradient(
          colors: colors.isDark ? _rainbowDark : _rainbowLight,
        ).createShader(Rect.fromLTWH(0, 0, bounds.width * 3, bounds.height)),
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

    final nameplateColor = colors.isDark
        ? style.nameplateDarkColor ?? style.nameplateColor
        : style.nameplateColor;
    if (plate && style.nameplateId != null && nameplateColor != null) {
      nameText = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1.5),
        decoration: BoxDecoration(
          color: nameplateColor.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(999),
        ),
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
        if (author.loadNetworkAvatar &&
            style.iconUrl != null &&
            style.iconUrl!.isNotEmpty)
          Tooltip(
            message: style.iconName ?? '',
            child: Image.network(
              style.iconUrl!,
              width: 16,
              height: 16,
              fit: BoxFit.contain,
              filterQuality: style.hasPixelBadge
                  ? FilterQuality.none
                  : FilterQuality.medium,
              semanticLabel: style.iconName,
              errorBuilder: (context, error, stackTrace) =>
                  const SizedBox.shrink(),
            ),
          ),
        if (style.distroBadge != DistroBadgeType.none ||
            (style.distroBadgeLabel != null &&
                style.distroBadgeLabel!.isNotEmpty))
          VnlfInlineDistroIcon(
            badge: style.distroBadge,
            badgeName: style.distroBadgeLabel,
            tooltip: distroBadgeTooltip ?? style.distroBadgeLabel,
            semanticLabel: distroBadgeSemanticLabel ?? style.distroBadgeLabel,
          ),
        if (style.hasTerminalBadge)
          _TerminalMiniBadge(semanticLabel: terminalBadgeSemanticLabel),
        if (style.hasPixelBadge && (style.iconUrl?.isEmpty ?? true))
          _PixelHelmBadge(semanticLabel: pixelBadgeSemanticLabel),
        if (style.hasPartnerStar)
          _GoldStarMiniBadge(semanticLabel: partnerStarSemanticLabel),
        if (showHandleInline)
          Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Text(
              '@${author.username}',
              softWrap: allowWrap,
              style: VnlfTypography.meta(colors.muted),
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
    this.badge = DistroBadgeType.none,
    this.badgeName,
    this.size = 16.0,
    this.tooltip,
    this.semanticLabel,
  });

  final DistroBadgeType badge;
  final String? badgeName;
  final double size;
  final String? tooltip;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final effectiveName =
        (badgeName != null && badgeName!.isNotEmpty
                ? badgeName!
                : (badge != DistroBadgeType.none ? badge.name : ''))
            .toLowerCase();

    if (effectiveName.isEmpty) return const SizedBox.shrink();

    final colors = VnlfColors.of(context);
    final (Color bg, Color fg, String glyph) = switch (badge) {
      DistroBadgeType.cachyos => (colors.cyan, colors.surface, 'C'),
      DistroBadgeType.caramos => (colors.green, colors.surface, 'C'),
      DistroBadgeType.arch => (colors.blue, colors.surface, 'A'),
      DistroBadgeType.debian => (colors.red, colors.surface, 'D'),
      DistroBadgeType.nixos => (colors.cyan, colors.surface, 'N'),
      DistroBadgeType.fedora => (colors.blue, colors.surface, 'f'),
      DistroBadgeType.ubuntu => (colors.orange, colors.surface, 'U'),
      DistroBadgeType.kali => (colors.blue, colors.surface, 'K'),
      DistroBadgeType.gentoo => (colors.purple, colors.surface, 'G'),
      DistroBadgeType.mint => (colors.green, colors.surface, 'M'),
      DistroBadgeType.linux => (colors.brand, colors.surface, 'L'),
      DistroBadgeType.opensuse => (colors.green, colors.surface, 'S'),
      DistroBadgeType.none => (
        colors.brand,
        colors.surface,
        effectiveName[0].toUpperCase(),
      ),
    };

    Widget fallback = Container(
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
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );

    Widget badgeWidget = ClipRRect(
      borderRadius: BorderRadius.circular(
        effectiveName == 'caramos' ? size / 2 : 4,
      ),
      child: SvgPicture.asset(
        'assets/images/distro-badges/$effectiveName.svg',
        width: size,
        height: size,
        fit: BoxFit.contain,
        placeholderBuilder: (_) => fallback,
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
    this.badge = DistroBadgeType.none,
    this.badgeName,
    this.label = '',
    this.iconTooltip,
    this.semanticLabel,
  });

  final DistroBadgeType badge;
  final String? badgeName;
  final String label;
  final String? iconTooltip;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    if (badge == DistroBadgeType.none &&
        (badgeName == null || badgeName!.isEmpty)) {
      return const SizedBox.shrink();
    }
    final colors = VnlfColors.of(context);

    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: colors.surfaceSoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          VnlfInlineDistroIcon(
            badge: badge,
            badgeName: badgeName,
            size: 13,
            tooltip: iconTooltip,
          ),
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

const _rainbowLight = [
  Color(0xFFC62828),
  Color(0xFFC2410C),
  Color(0xFF166534),
  Color(0xFF0369A1),
  Color(0xFF7E22CE),
  Color(0xFFC62828),
];

const _rainbowDark = [
  Color(0xFFFF8A80),
  Color(0xFFFDBA74),
  Color(0xFF86EFAC),
  Color(0xFF7DD3FC),
  Color(0xFFD8B4FE),
  Color(0xFFFF8A80),
];
