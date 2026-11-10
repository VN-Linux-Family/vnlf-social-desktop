import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../design_system/design_system.dart';
import '../../../domain/models.dart';
import '../../../i18n/vi.dart';
import '../../shared/presentation/author_mapper.dart';
import 'project_accent.dart';
import 'project_detail_sheet.dart';

/// The website's project card (`ProjectCardView`, project-card.tsx), which
/// its project lists share. VNLF's own projects are brand green, partners'
/// amber and members' plain; a project with a logo colour is tinted by it.
class ProjectCard extends StatefulWidget {
  const ProjectCard({super.key, required this.project, this.trending = false});

  final ProjectItem project;

  /// Sorted by "Đang lên": the card adds the stars gained this week.
  final bool trending;

  @override
  State<ProjectCard> createState() => _ProjectCardState();
}

class _ProjectCardState extends State<ProjectCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final project = widget.project;
    final colors = VnlfColors.of(context);
    final look = _CardLook.of(project, colors);
    final radius = BorderRadius.circular(VnlfDimensions.radiusLg);
    final muted = VnlfTypography.meta(colors.muted);
    final badges = _badges(project);
    final repo = project.repo;
    final average = (project.rating?['average'] as num?)?.toDouble();
    final ratings = (project.rating?['count'] as num?)?.toInt() ?? 0;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: radius,
        onHover: (value) => setState(() => _hovered = value),
        onTap: () => project.slug.isEmpty
            ? showProjectDetailSheet(context, project)
            : context.push('/projects/${Uri.encodeComponent(project.slug)}'),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: look.gradient == null ? colors.surface : null,
            gradient: look.gradient,
            border: Border.all(
              color: _hovered ? look.hoverBorder : look.border,
            ),
            borderRadius: radius,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 9,
            children: [
              Row(
                spacing: 10,
                children: [
                  _ProjectLogo(project: project, look: look),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 2,
                      children: [
                        Text(
                          project.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: VnlfTypography.control(
                            colors.ink,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          vi.projects.loai[project.type] ?? project.type,
                          style: muted,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (project.tagline.isNotEmpty)
                Text(
                  project.tagline,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: VnlfTypography.plain(colors.ink).copyWith(height: 1.5),
                ),
              if (project.tier != 'COMMUNITY' || badges.isNotEmpty)
                Wrap(
                  spacing: 5,
                  runSpacing: 5,
                  children: [
                    if (project.tier != 'COMMUNITY')
                      _TierBadge(tier: project.tier),
                    for (final (kind, label) in badges)
                      _Badge(kind: kind, label: label),
                  ],
                ),
              if (ratings > 0 && average != null)
                Semantics(
                  label: format(vi.projects.diemTrenNam, {
                    'average': _decimal(average),
                    'count': ratings,
                  }),
                  excludeSemantics: true,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 6,
                    children: [
                      _RatingStars(value: average),
                      Text(
                        _decimal(average),
                        style: VnlfTypography.meta(
                          colors.ink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text('($ratings)', style: muted),
                    ],
                  ),
                ),
              if (repo != null)
                _RepoFacts(repo: repo, trending: widget.trending),
              _Foot(project: project),
            ],
          ),
        ),
      ),
    );
  }
}

/// `.projects-grid`: as many columns of at least 260px as fit, 12px apart,
/// each row as tall as its tallest card.
class ProjectGrid extends StatelessWidget {
  const ProjectGrid({super.key, required this.items, this.trending = false});

  final List<ProjectItem> items;
  final bool trending;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      // One column on narrow windows (`max-width: 640px`).
      final columns = MediaQuery.sizeOf(context).width <= 640
          ? 1
          : math.max(1, ((constraints.maxWidth + 12) / 272).floor());
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          for (var start = 0; start < items.length; start += columns)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 12,
                children: [
                  for (var index = start; index < start + columns; index++)
                    Expanded(
                      child: index < items.length
                          ? ProjectCard(
                              project: items[index],
                              trending: trending,
                            )
                          : const SizedBox.shrink(),
                    ),
                ],
              ),
            ),
        ],
      );
    },
  );
}

/// The labels after the tier: featured, looking for contributors, and what
/// the repository says (`ProjectBadges`). Cards never name a fork's parent.
List<(String, String)> _badges(ProjectItem project) {
  final labels = vi.projects.nhan;
  final repo = project.repo;
  return [
    if (project.featured) ('featured', labels['featured']!),
    if (project.seeking) ('seeking', labels['seeking']!),
    if (repo == null)
      ('closed', labels['noSource']!)
    else if (repo['unavailable'] == true)
      ('unavailable', labels['unavailable']!)
    else if (repo['archived'] == true)
      ('archived', labels['archived']!)
    else if (_quiet(repo['pushedAt']))
      ('quiet', labels['inactive']!),
  ];
}

/// No push for more than a year: "Ít hoạt động" (`quietRepo`).
bool _quiet(Object? pushedAt) {
  final date = pushedAt is String ? DateTime.tryParse(pushedAt) : null;
  return date != null && DateTime.now().difference(date).inDays > 365;
}

/// "5,0": one decimal with the Vietnamese comma.
String _decimal(double value) => NumberFormat('0.0', 'vi').format(value);

/// `compactCount`: 999, then "1,2k", and whole thousands from "100k".
String compactCount(int value) {
  if (value < 1000) return '$value';
  final thousands = value / 1000;
  return thousands >= 100
      ? '${thousands.round()}k'
      : '${NumberFormat('0.#', 'vi').format(thousands)}k';
}

/// `sinceText`: "vừa xong", "3 giờ trước" within a week, then the date.
String _sinceText(DateTime date) {
  final now = DateTime.now();
  final minutes = now.difference(date).inMinutes;
  if (minutes < 1) return vi.projects.vuaXong;
  final String text;
  if (minutes < 60) {
    text = format(vi.socialRuntime.phut, {'minutes': minutes});
  } else if (minutes < 24 * 60) {
    text = format(vi.socialRuntime.gio, {'hours': minutes ~/ 60});
  } else if (minutes < 7 * 24 * 60) {
    text = format(vi.socialRuntime.ngay, {'Math': minutes ~/ (24 * 60)});
  } else {
    final local = date.toLocal();
    return local.year == now.year
        ? '${local.day}/${local.month}'
        : '${local.day}/${local.month}/${local.year}';
  }
  return format(vi.projects.truoc, {'time': text});
}

/// Border, tint and logo frame for a card's tier or its logo colour.
final class _CardLook {
  const _CardLook({
    required this.border,
    required this.hoverBorder,
    required this.logoBorder,
    required this.logoBackground,
    required this.logoInk,
    this.gradient,
    this.logoRing,
  });

  factory _CardLook.of(ProjectItem project, VnlfColors colors) {
    Color mix(Color color, double amount, [Color? base]) =>
        Color.lerp(base ?? colors.surface, color, amount)!;
    final partner = project.tier == 'PARTNER';
    final logoBackground = partner
        ? mix(colors.tierPartner, 0.12)
        : colors.brandSoft;
    final logoInk = partner ? colors.tierPartner : colors.brand;
    final accent = ProjectAccent(project.accentColor, colors).own;
    if (accent != null) {
      return _CardLook(
        border: mix(accent, 0.32, colors.line),
        hoverBorder: mix(accent, 0.7, colors.line),
        logoBorder: mix(accent, 0.45, colors.line),
        logoBackground: logoBackground,
        logoInk: logoInk,
        logoRing: accent.withValues(alpha: 0.14),
        gradient: VnlfCssGradient(
          angle: 160,
          colors: [mix(accent, 0.14), mix(accent, 0.04), colors.surface],
          stops: const [0, 0.55, 1],
        ),
      );
    }
    return switch (project.tier) {
      'VNLF' => _CardLook(
        border: mix(colors.brand, 0.38, colors.line),
        hoverBorder: colors.brand,
        logoBorder: mix(colors.brand, 0.5, colors.line),
        logoBackground: logoBackground,
        logoInk: logoInk,
        gradient: VnlfCssGradient(
          angle: 165,
          colors: [colors.brandSoft, colors.surface],
          stops: const [0, 0.48],
        ),
      ),
      'PARTNER' => _CardLook(
        border: mix(colors.tierPartner, 0.38, colors.line),
        hoverBorder: colors.tierPartner,
        logoBorder: mix(colors.tierPartner, 0.5, colors.line),
        logoBackground: logoBackground,
        logoInk: logoInk,
        gradient: VnlfCssGradient(
          angle: 165,
          colors: [mix(colors.tierPartner, 0.11), colors.surface],
          stops: const [0, 0.48],
        ),
      ),
      _ => _CardLook(
        border: colors.line,
        hoverBorder: mix(colors.brand, 0.45, colors.line),
        logoBorder: colors.line,
        logoBackground: logoBackground,
        logoInk: logoInk,
      ),
    };
  }

  final Color border;
  final Color hoverBorder;
  final Color logoBorder;
  final Color logoBackground;
  final Color logoInk;
  final Gradient? gradient;
  final Color? logoRing;
}

/// The 44px logo, or the project's initials when it has none.
class _ProjectLogo extends StatelessWidget {
  const _ProjectLogo({required this.project, required this.look});

  static const _size = 44.0;
  final ProjectItem project;
  final _CardLook look;

  @override
  Widget build(BuildContext context) {
    final initials = Text(
      VnlfAvatar.initialsOf(project.name),
      style: VnlfTypography.control(look.logoInk, fontWeight: FontWeight.w700),
    );
    final url = project.logoUrl ?? '';
    return Container(
      width: _size,
      height: _size,
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: look.logoBackground,
        border: Border.all(color: look.logoBorder),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          if (look.logoRing case final ring?)
            BoxShadow(color: ring, spreadRadius: 3),
        ],
      ),
      child: url.isEmpty
          ? initials
          : Image.network(
              url,
              width: _size,
              height: _size,
              fit: BoxFit.cover,
              cacheWidth: (_size * MediaQuery.devicePixelRatioOf(context))
                  .round(),
              errorBuilder: (context, error, stackTrace) => initials,
            ),
    );
  }
}

/// "VNLF" with the community's mark, or "Đối tác" with a handshake.
class _TierBadge extends StatelessWidget {
  const _TierBadge({required this.tier});

  final String tier;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final vnlf = tier == 'VNLF';
    final ink = vnlf ? colors.paper : colors.tierPartner;
    return Container(
      constraints: const BoxConstraints(minHeight: 22),
      padding: const EdgeInsets.fromLTRB(6, 0, 9, 0),
      decoration: BoxDecoration(
        color: vnlf
            ? colors.brand
            : Color.lerp(colors.surface, colors.tierPartner, 0.15),
        border: vnlf
            ? null
            : Border.all(color: colors.tierPartner.withValues(alpha: 0.45)),
        borderRadius: BorderRadius.circular(VnlfDimensions.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 5,
        children: [
          if (vnlf)
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: ColoredBox(
                color: colors.surface,
                child: BrandAssets.logo(size: 14),
              ),
            )
          else
            VnlfIcon(VnlfLucide.handshake, size: 13, color: ink),
          Flexible(
            child: Text(
              vi.projects.tierNhan[tier] ?? tier,
              style: VnlfTypography.caption(ink, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.kind, required this.label});

  final String kind;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    Color tint(Color color, double amount) =>
        Color.lerp(colors.surface, color, amount)!;
    final (background, ink) = switch (kind) {
      'featured' => (tint(colors.orange, 0.15), colors.orange),
      'seeking' => (tint(colors.blue, 0.14), colors.blue),
      'unavailable' => (tint(colors.red, 0.13), colors.red),
      _ => (colors.surfaceSoft, colors.muted),
    };
    return Container(
      constraints: const BoxConstraints(minHeight: 22),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(VnlfDimensions.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              style: VnlfTypography.caption(ink, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// Five stars filled up to [value]: members' ratings, never GitHub's stars.
class _RatingStars extends StatelessWidget {
  const _RatingStars({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    Widget stars({required bool filled}) => Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 1,
      children: [
        for (var index = 0; index < 5; index++)
          VnlfIcon(
            VnlfLucide.star,
            size: 14,
            filled: filled,
            color: filled
                ? colors.ratingStar
                : colors.muted.withValues(alpha: 0.55),
          ),
      ],
    );
    return Stack(
      children: [
        stars(filled: false),
        ClipRect(
          child: Align(
            alignment: Alignment.centerLeft,
            widthFactor: value.clamp(0, 5) / 5,
            child: stars(filled: true),
          ),
        ),
      ],
    );
  }
}

/// Stars, forks, language and the last push, as GitHub last said
/// (`ProjectRepoFacts`), behind GitHub's mark.
class _RepoFacts extends StatelessWidget {
  const _RepoFacts({required this.repo, required this.trending});

  final Map<String, dynamic> repo;
  final bool trending;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final style = VnlfTypography.meta(colors.muted);
    final stars = (repo['stars'] as num?)?.toInt();
    if (stars == null) return Text(vi.projects.dangLaySoLieu, style: style);
    final forks = (repo['forks'] as num?)?.toInt();
    final language = repo['language'] as String? ?? '';
    final starsWeek = (repo['starsWeek'] as num?)?.toInt() ?? 0;
    final pushed = repo['pushedAt'] is String
        ? DateTime.tryParse(repo['pushedAt'] as String)
        : null;
    Widget fact(VnlfLucide icon, String text, {String? label}) => Semantics(
      label: label,
      excludeSemantics: label != null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          VnlfIcon(icon, size: 14, color: colors.muted),
          Flexible(child: Text(text, style: style)),
        ],
      ),
    );
    return Tooltip(
      message: vi.projects.soLieuGithub,
      child: Wrap(
        spacing: 12,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          VnlfIcon(VnlfLucide.github, size: 14, color: colors.muted),
          fact(
            VnlfLucide.star,
            compactCount(stars),
            label: format(vi.projects.soStar, {'count': stars}),
          ),
          if (forks != null)
            fact(
              VnlfLucide.gitFork,
              compactCount(forks),
              label: format(vi.projects.soFork, {'count': forks}),
            ),
          if (language.isNotEmpty)
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 4,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color:
                        ProjectAccent(
                          repo['languageColor'] as String?,
                          colors,
                        ).own ??
                        colors.muted,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colors.ink.withValues(alpha: 0.12),
                    ),
                  ),
                ),
                Flexible(child: Text(language, style: style)),
              ],
            ),
          if (trending && starsWeek > 0)
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 4,
              children: [
                VnlfIcon(VnlfLucide.trendingUp, size: 14, color: colors.brand),
                Flexible(
                  child: Text(
                    format(vi.projects.starTuanNay, {'count': starsWeek}),
                    style: VnlfTypography.meta(
                      colors.brand,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          if (pushed != null)
            fact(
              VnlfLucide.history,
              format(vi.projects.capNhat, {'time': _sinceText(pushed)}),
            ),
        ],
      ),
    );
  }
}

/// Who stands behind the project, and how many comments it has.
class _Foot extends StatelessWidget {
  const _Foot({required this.project});

  final ProjectItem project;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final style = VnlfTypography.meta(colors.muted);
    final owner = project.owner;
    final comments = project.commentCount;
    return Row(
      children: [
        Expanded(
          child: Row(
            spacing: 8,
            children: [
              if (project.tier == 'VNLF') ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: BrandAssets.logo(size: 20),
                ),
                Flexible(
                  child: Text(
                    vi.projects.vnlf,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: style,
                  ),
                ),
              ] else if (owner != null) ...[
                VnlfAvatar(author: presentAuthor(owner), size: 22),
                Flexible(
                  child: Text(
                    owner.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: style,
                  ),
                ),
                if (vi.projects.quanHe[project.relation] case final relation?)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 8,
                    children: [
                      Text('·', style: style),
                      Text(relation, style: style),
                    ],
                  ),
              ],
            ],
          ),
        ),
        if (comments != null)
          Semantics(
            label: format(vi.projects.soBinhLuan, {'count': comments}),
            excludeSemantics: true,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 4,
              children: [
                VnlfIcon(
                  VnlfLucide.messageCircle,
                  size: 14,
                  color: colors.muted,
                ),
                Text(
                  compactCount(comments),
                  style: style.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
