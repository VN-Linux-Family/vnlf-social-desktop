import 'package:flutter/material.dart';

import '../../tokens/vnlf_colors.dart';
import '../../tokens/vnlf_dimensions.dart';
import '../../tokens/vnlf_typography.dart';

class SidebarNavTile extends StatelessWidget {
  const SidebarNavTile({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.hasUnread = false,
    this.semanticLabel,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool hasUnread;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final effectiveSemantics =
        semanticLabel ?? (label.isNotEmpty ? label : null);

    return Semantics(
      button: true,
      selected: selected,
      label: effectiveSemantics,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(VnlfDimensions.radiusMd),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: selected ? colors.brandSoft : Colors.transparent,
              borderRadius: BorderRadius.circular(VnlfDimensions.radiusMd),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 19,
                  color: selected ? colors.brand : colors.muted,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: VnlfTypography.control(
                      selected ? colors.brand : colors.ink,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ),
                if (hasUnread) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFD7473E),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SidebarSupportTile extends StatelessWidget {
  const SidebarSupportTile({
    super.key,
    required this.onTap,
    this.label = '',
    this.badgeText = '',
    this.semanticLabel,
  });

  final VoidCallback onTap;
  final String label;
  final String badgeText;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final effectiveSemantics =
        semanticLabel ?? (label.isNotEmpty ? label : null);

    return Semantics(
      button: true,
      label: effectiveSemantics,
      child: InkWell(
        borderRadius: BorderRadius.circular(VnlfDimensions.radiusMd),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9.5),
          child: Row(
            children: [
              Container(
                width: 18,
                height: 18,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.amber,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.star_rounded,
                  size: 12,
                  color: colors.surface,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(label, style: VnlfTypography.control(colors.muted)),
              ),
              if (badgeText.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6.5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colors.brand,
                    borderRadius: BorderRadius.circular(
                      VnlfDimensions.radiusFull,
                    ),
                  ),
                  child: Text(
                    badgeText,
                    style: VnlfTypography.caption(
                      colors.surface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class SidebarUtilityTile extends StatelessWidget {
  const SidebarUtilityTile({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.semanticLabel,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final effectiveSemantics =
        semanticLabel ?? (label.isNotEmpty ? label : null);

    return Semantics(
      button: true,
      label: effectiveSemantics,
      child: InkWell(
        borderRadius: BorderRadius.circular(VnlfDimensions.radiusSm),
        onTap: onTap ?? () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7.5),
          child: Row(
            children: [
              Icon(icon, size: 17, color: colors.muted),
              const SizedBox(width: 10),
              Expanded(
                child: Text(label, style: VnlfTypography.control(colors.muted)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SocialCircleBadge extends StatefulWidget {
  const SocialCircleBadge({
    super.key,
    this.label,
    this.icon,
    this.assetPath,
    this.semanticLabel,
    this.onTap,
    this.compact = true,
  });

  final String? label;
  final IconData? icon;
  final String? assetPath;
  final String? semanticLabel;
  final VoidCallback? onTap;
  final bool compact;

  @override
  State<SocialCircleBadge> createState() => _SocialCircleBadgeState();
}

class _SocialCircleBadgeState extends State<SocialCircleBadge> {
  bool _hovered = false;
  bool _focused = false;
  bool get _active => _hovered || _focused;
  static const _grayscale = ColorFilter.matrix([
    .2126,
    .7152,
    .0722,
    0,
    0,
    .2126,
    .7152,
    .0722,
    0,
    0,
    .2126,
    .7152,
    .0722,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ]);
  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    Widget badge;
    if (widget.assetPath != null) {
      final image = ClipOval(
        child: Image.asset(
          widget.assetPath!,
          width: 22,
          height: 22,
          fit: BoxFit.cover,
        ),
      );
      badge = AnimatedOpacity(
        opacity: _active ? 1 : .6,
        duration: VnlfDimensions.resolveDuration(
          context,
          VnlfDimensions.motionFast,
        ),
        child: _active
            ? image
            : ColorFiltered(colorFilter: _grayscale, child: image),
      );
    } else {
      badge = Container(
        width: 24,
        height: 24,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.socialIconBg,
          shape: BoxShape.circle,
        ),
        child: widget.label != null
            ? Text(
                widget.label!,
                style: TextStyle(
                  fontFamily: VnlfTypography.fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: colors.surface,
                  height: 1,
                ),
              )
            : Icon(widget.icon, size: 13, color: colors.surface),
      );
    }
    if (!widget.compact) {
      badge = SizedBox(width: 44, height: 44, child: Center(child: badge));
    }
    if (widget.onTap != null) {
      badge = MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) {
          if (mounted) {
            setState(() => _hovered = false);
          }
        },
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: widget.onTap,
          onFocusChange: (focused) {
            if (mounted) {
              setState(() => _focused = focused);
            }
          },
          child: badge,
        ),
      );
    }
    return widget.semanticLabel == null
        ? badge
        : Semantics(label: widget.semanticLabel, button: true, child: badge);
  }
}
