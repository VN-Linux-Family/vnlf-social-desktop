import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../design_system/design_system.dart';
import '../../../i18n/vi.dart';
import '../domain/profile_links.dart';
import '../domain/public_profile.dart';
import 'profile_brand_icons.dart';

/// "GitHub: dungle", "Website: example.com": what a link button reads out
/// and shows on hover.
String profileLinkName(ProfileLink link) =>
    format(vi.profileLinks.nhanLienKet, {
      'platform': link.platform == null
          ? vi.profileLinks.trangWeb
          : vi.profileLinks.nenTang[link.platform!.name] ?? link.platform!.name,
      'label': link.label,
    });

/// The website's `ProfileLinks`: icon buttons for the links under the bio,
/// each checked again before it opens, then the linked Discord account,
/// which copies its username. [compact] is the profile card's smaller row.
class ProfileLinksRow extends StatelessWidget {
  const ProfileLinksRow({
    super.key,
    required this.decor,
    required this.name,
    required this.accent,
    this.compact = false,
  });

  final ProfileDecor decor;

  /// The profile's display name, for the list's label.
  final String name;

  /// Hovered buttons take the profile's accent.
  final Color accent;
  final bool compact;

  /// Whether [decor] has anything to show.
  static bool shows(ProfileDecor decor) =>
      decor.discordUsername != null || decor.links.any(_safe);

  static bool _safe(String url) => parseProfileLink(url) != null;

  @override
  Widget build(BuildContext context) {
    final links = decor.links
        .map(parseProfileLink)
        .nonNulls
        .take(profileLinksMax)
        .toList();
    final discord = decor.discordUsername;
    if (links.isEmpty && discord == null) return const SizedBox.shrink();
    // Phones keep 48dp targets where the website's touch size is 44.
    final phone = MediaQuery.sizeOf(context).width < 841;
    final size = phone
        ? 48.0
        : compact
        ? 32.0
        : 36.0;
    final iconSize = compact ? 16.0 : 18.0;
    return Semantics(
      container: true,
      label: format(vi.profileLinks.danhSach, {'name': name}),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final link in links)
            _PillButton(
              size: size,
              accent: accent,
              tooltip: profileLinkName(link),
              semanticLabel: profileLinkName(link),
              link: true,
              onTap: () => launchUrl(
                Uri.parse(link.url),
                mode: LaunchMode.externalApplication,
              ),
              builder: (color) =>
                  ProfileBrandIcon(link.platform, size: iconSize, color: color),
            ),
          if (discord != null)
            _PillButton(
              size: size,
              accent: accent,
              padding: compact ? 8 : 12,
              tooltip: vi.profileLinks.discordXacMinh,
              semanticLabel: format(vi.profileLinks.discordNhan, {
                'username': discord,
              }),
              onTap: () => _copy(context, discord),
              builder: (color) => _DiscordLabel(
                username: discord,
                iconSize: iconSize,
                color: color,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _copy(BuildContext context, String username) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    String message;
    try {
      await Clipboard.setData(ClipboardData(text: username));
      message = vi.profileLinks.daSaoChepDiscord;
    } on PlatformException {
      message = vi.profileLinks.chuaSaoChepDuoc;
    }
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

/// A platform's logo, or lucide's LinkedIn and link icons like the website.
class ProfileBrandIcon extends StatelessWidget {
  const ProfileBrandIcon(
    this.platform, {
    super.key,
    required this.size,
    required this.color,
  });

  final LinkPlatform? platform;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final path = brandIconPaths[platform];
    if (path == null) {
      return VnlfIcon(
        platform == LinkPlatform.linkedin
            ? VnlfLucide.linkedin
            : VnlfLucide.link2,
        size: size,
        color: color,
      );
    }
    return SvgPicture.string(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" '
      'fill="currentColor"><path d="$path"/></svg>',
      width: size,
      height: size,
      theme: SvgTheme(currentColor: color),
      excludeFromSemantics: true,
    );
  }
}

class _DiscordLabel extends StatelessWidget {
  const _DiscordLabel({
    required this.username,
    required this.iconSize,
    required this.color,
  });

  final String username;
  final double iconSize;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [
        ProfileBrandIcon(LinkPlatform.discord, size: iconSize, color: color),
        Flexible(
          child: Text(
            '@$username',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: VnlfTypography.plain(color, fontWeight: FontWeight.w600),
          ),
        ),
        // Discord's blurple keeps its colour on hover.
        VnlfIcon(
          VnlfLucide.badgeCheck,
          size: 14,
          color: dark ? const Color(0xFF8C95F7) : const Color(0xFF5865F2),
        ),
      ],
    );
  }
}

/// A round (or pill-shaped) outlined button whose border and content take
/// the accent on hover and focus.
class _PillButton extends StatefulWidget {
  const _PillButton({
    required this.size,
    required this.accent,
    required this.tooltip,
    required this.semanticLabel,
    required this.onTap,
    required this.builder,
    this.padding = 0,
    this.link = false,
  });

  final double size;
  final Color accent;
  final String tooltip;
  final String semanticLabel;
  final VoidCallback onTap;
  final Widget Function(Color color) builder;
  final double padding;
  final bool link;

  @override
  State<_PillButton> createState() => _PillButtonState();
}

class _PillButtonState extends State<_PillButton> {
  var _active = false;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final tint = _active ? widget.accent : colors.ink;
    final shape = StadiumBorder(
      side: BorderSide(color: _active ? widget.accent : colors.line),
    );
    return Tooltip(
      message: widget.tooltip,
      child: Semantics(
        button: !widget.link,
        link: widget.link,
        label: widget.semanticLabel,
        excludeSemantics: true,
        onTap: widget.onTap,
        child: Material(
          color: colors.surface,
          shape: shape,
          child: InkWell(
            customBorder: shape,
            onTap: widget.onTap,
            onHover: (value) => setState(() => _active = value),
            onFocusChange: (value) => setState(() => _active = value),
            hoverColor: Colors.transparent,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: widget.size,
                minHeight: widget.size,
                maxHeight: widget.size,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: widget.padding),
                child: Center(widthFactor: 1, child: widget.builder(tint)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
