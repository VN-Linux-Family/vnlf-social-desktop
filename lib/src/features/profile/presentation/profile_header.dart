import 'package:flutter/material.dart';

import '../../../design_system/design_system.dart';
import '../../../i18n/vi.dart';
import '../../shared/presentation/author_mapper.dart';
import '../domain/public_profile.dart';
import 'profile_links_row.dart';
import 'profile_palette.dart';

/// The website's profile header (`account-views.tsx` `ProfileView`): the
/// cover with the avatar over its edge, the name, handle, bio, links and
/// status beside the actions, then the four stats. With [tabs] it closes
/// the same bordered card, as the website stacks them.
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.profile,
    required this.palette,
    this.actions,
    this.tabs,
  });

  final PublicProfile profile;
  final ProfilePalette palette;

  /// Follow, edit or unblock, and the menu.
  final Widget? actions;
  final Widget? tabs;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final phone = MediaQuery.sizeOf(context).width < 841;
    final top = Radius.circular(phone ? 10 : 14);
    const bottom = Radius.circular(14);
    final shape = BorderRadius.vertical(top: top, bottom: bottom);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: colors.surface, borderRadius: shape),
      foregroundDecoration: BoxDecoration(
        border: Border.all(color: colors.line),
        borderRadius: shape,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Cover(profile: profile, palette: palette, phone: phone),
          _Info(
            profile: profile,
            palette: palette,
            phone: phone,
            actions: actions,
          ),
          _Divider(colors.line),
          _Stats(profile: profile, palette: palette),
          if (tabs case final tabs?) ...[_Divider(colors.line), tabs],
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider(this.color);
  final Color color;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: color,
    child: const SizedBox(height: 1, width: double.infinity),
  );
}

class _Cover extends StatelessWidget {
  const _Cover({
    required this.profile,
    required this.palette,
    required this.phone,
  });

  final PublicProfile profile;
  final ProfilePalette palette;
  final bool phone;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final author = presentAuthor(profile.author);
    final avatar = phone ? 54.0 : 66.0;
    final border = phone ? 3.0 : 4.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final pixels = width * MediaQuery.devicePixelRatioOf(context);
        // The website's srcset: 750 wide, or 1500 for a sharper screen.
        final image = pixels > 750
            ? profile.coverUrl ?? profile.decor.coverSmallUrl
            : profile.decor.coverSmallUrl ?? profile.coverUrl;
        final height = image == null ? (phone ? 92.0 : 120.0) : width / 3;
        return SizedBox(
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.surfaceSoft,
                    gradient: image == null
                        ? palette.cover(Size(width, height))
                        : null,
                  ),
                  child: image == null
                      ? null
                      : Image.network(
                          image,
                          fit: BoxFit.cover,
                          errorBuilder: (_, error, stack) =>
                              const SizedBox.expand(),
                        ),
                ),
              ),
              Positioned(
                left: phone ? 10 : 20,
                bottom: phone ? -18 : -22,
                child: Container(
                  width: avatar,
                  height: avatar,
                  padding: EdgeInsets.all(border),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(phone ? 14 : 19),
                    // The website's extra ring around the bordered avatar.
                    boxShadow: [
                      BoxShadow(color: colors.surface, spreadRadius: 4),
                    ],
                  ),
                  child: VnlfAvatar(
                    author: author,
                    size: avatar - 2 * border,
                    cornerRadius: phone ? 11 : 15,
                    semanticLabel: author.displayName,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({
    required this.profile,
    required this.palette,
    required this.phone,
    required this.actions,
  });

  final PublicProfile profile;
  final ProfilePalette palette;
  final bool phone;
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final author = presentAuthor(profile.author);
    final mono = palette.mono ? profileMonoFamilies : null;
    final muted = VnlfTypography.plain(colors.muted)
        .copyWith(fontFamilyFallback: mono);
    final bio = Text(
      _collapse(profile.bio) ?? vi.accountViews.thanhVienVnlfSocial,
      style: VnlfTypography.plain(colors.ink),
    );
    final status = switch (profile.decor.status) {
      final line? => Padding(
        padding: const EdgeInsets.only(bottom: 11),
        child: _StatusPill(status: line, style: muted),
      ),
      null => null,
    };
    final links = ProfileLinksRow.shows(profile.decor);
    final visits = profile.decor.visits;
    final identity = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: VnlfAuthorNameRow(author: author, showHandleInline: false),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 11),
          child: Text('@${author.username}', style: muted),
        ),
        if (profile.isSample)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(vi.app.profile.hoSoMau, style: muted),
          ),
        // The bio is inline on the website, so without a row of links the
        // status pill continues the same line.
        if (links) ...[
          bio,
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: ProfileLinksRow(
              decor: profile.decor,
              name: author.displayName,
              accent: palette.accent,
            ),
          ),
          ?status,
        ] else
          Wrap(
            spacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [bio, ?status],
          ),
        // The website's plain counter; its other skins are not ported.
        if (visits != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              format(
                visits.hidden
                    ? vi.guestbook.luotGheDangAn
                    : vi.guestbook.luotGhe,
                {'count': _thousands(visits.count)},
              ),
              style: VnlfTypography.plain(colors.muted)
                  .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
            ),
          ),
      ],
    );
    final narrow = MediaQuery.sizeOf(context).width <= 520;
    return Padding(
      padding: phone
          ? const EdgeInsets.fromLTRB(8, 26, 8, 10)
          : const EdgeInsets.fromLTRB(20, 34, 20, 16),
      child: actions == null
          ? identity
          : narrow
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 10,
              children: [identity, actions!],
            )
          : Row(
              spacing: phone ? 10 : 18,
              children: [
                Expanded(child: identity),
                actions!,
              ],
            ),
    );
  }

  /// `toLocaleString("vi-VN")`: dots between thousands.
  static String _thousands(int value) => value.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => '.',
  );

  static String? _collapse(String? text) {
    final value = text?.trim().replaceAll(RegExp(r'\s+'), ' ');
    return value == null || value.isEmpty ? null : value;
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status, required this.style});

  final ({String emoji, String text}) status;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: VnlfColors.of(context).surfaceSoft,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: status.emoji, semanticsLabel: ''),
            TextSpan(text: ' ${status.text}'),
          ],
        ),
        style: style.copyWith(height: 1.45),
      ),
    ),
  );
}

class _Stats extends StatelessWidget {
  const _Stats({required this.profile, required this.palette});

  final PublicProfile profile;
  final ProfilePalette palette;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final phone = width < 841;
    final grid =
        width <= 520 || MediaQuery.textScalerOf(context).scale(13) > 20;
    final number = VnlfTypography.plain(
      palette.accent,
      fontWeight: FontWeight.w600,
    ).copyWith(fontFamilyFallback: palette.mono ? profileMonoFamilies : null);
    final cells = [
      _Stat(
        value: profile.totalPoints,
        label: vi.accountViews.xpTong,
        level: profile.level,
        style: number,
      ),
      _Stat(
        value: profile.currentStreak,
        label: vi.accountViews.ngayStreak,
        style: number,
      ),
      _Stat(
        value: profile.followingCount,
        label: vi.accountViews.dangTheoDoi2,
        style: number,
      ),
      _Stat(
        value: profile.followerCount,
        label: vi.accountViews.nguoiTheoDoi,
        style: number,
      ),
    ];
    final line = BorderSide(color: colors.line);
    if (grid) {
      Widget cell(int index) => DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            right: index.isEven ? line : BorderSide.none,
            top: index >= 2 ? line : BorderSide.none,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: cells[index],
        ),
      );
      return Padding(
        padding: EdgeInsets.fromLTRB(phone ? 8 : 20, 0, phone ? 8 : 20, 7),
        child: Column(
          children: [
            for (final row in const [0, 2])
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: cell(row)),
                    Expanded(child: cell(row + 1)),
                  ],
                ),
              ),
          ],
        ),
      );
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(phone ? 8 : 20, 0, phone ? 8 : 20, 12),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var index = 0; index < cells.length; index++)
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border(
                      right: index < cells.length - 1 ? line : BorderSide.none,
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      index == 0 ? 0 : 20,
                      12,
                      0,
                      12,
                    ),
                    child: cells[index],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.value,
    required this.label,
    required this.style,
    this.level,
  });

  final int? value;
  final String label;
  final TextStyle style;
  final int? level;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final accent = style.color ?? colors.ink;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: [
        Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(value?.toString() ?? '—', style: style),
            if (level case final level?)
              DecoratedBox(
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 1,
                  ),
                  child: Text(
                    format(vi.accountViews.levelSo, {'level': '$level'}),
                    style: VnlfTypography.plain(
                      accent,
                      fontWeight: FontWeight.w700,
                    ).copyWith(height: 1.5),
                  ),
                ),
              ),
          ],
        ),
        Text(label, style: VnlfTypography.plain(colors.muted)),
      ],
    );
  }
}
