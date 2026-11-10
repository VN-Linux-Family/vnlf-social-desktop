import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/models.dart';
import '../../../i18n/vi.dart';
import '../../profile/presentation/profile_data.dart';
import '../../profile/presentation/profile_relationship_controller.dart';
import '../../projects/domain/project_directory.dart';
import '../../projects/presentation/project_card.dart';
import '../../projects/presentation/project_directory_controller.dart';
import '../../shared/presentation/author_mapper.dart';
import '../../shared/presentation/page_header_actions.dart';

/// Topics and people from `GET /api/v1/discover`, read again per account so
/// the follow buttons match the viewer.
final discoverDataProvider = FutureProvider.autoDispose<DiscoverData>((ref) {
  ref.watch(sessionStateProvider.select((session) => session?.userId));
  return ref.watch(discoverRepositoryProvider).getDiscoverData();
});

/// "Dự án nổi bật": the first three projects in the directory's default
/// order (VNLF's own, partners', then members'), as the website lists them.
final featuredProjectsProvider = FutureProvider.autoDispose<List<ProjectItem>>((
  ref,
) async {
  ref.watch(sessionStateProvider.select((session) => session?.userId));
  final directory = await ref
      .watch(projectDirectoryRepositoryProvider)
      .fetch(const ProjectFilters());
  return directory.page.items.take(3).toList();
});

/// The website's Khám phá (`ExploreView`): a search box, three topics, the
/// featured projects and three people to follow.
class DiscoverScreen extends ConsumerWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phone =
        VnlfViewportSize.fromWidth(MediaQuery.sizeOf(context).width) ==
        VnlfViewportSize.mobile;
    final gap = phone ? 8.0 : 25.0;
    final discover = ref.watch(discoverDataProvider);
    final colors = VnlfColors.of(context);
    final list = RefreshIndicator(
      onRefresh: () {
        HapticFeedback.lightImpact();
        ref.invalidate(featuredProjectsProvider);
        return ref.refresh(discoverDataProvider.future);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: phone
            ? EdgeInsets.fromLTRB(
                8,
                10,
                8,
                68 + MediaQuery.viewPaddingOf(context).bottom,
              )
            : const EdgeInsets.only(bottom: 40),
        children: [
          _ExploreHero(phone: phone),
          SizedBox(height: gap),
          ...discover.when(
            loading: () => [
              Semantics(
                liveRegion: true,
                child: Text(
                  vi.feedViews.dangTaiGoiY,
                  style: VnlfTypography.body(colors.ink),
                ),
              ),
            ],
            error: (error, stack) => [
              VnlfStateCard(
                icon: Icons.error_outline,
                title: vi.feedViews.chuaTaiDuocGoiY,
                message: '',
                isError: true,
                actionLabel: vi.common.thuLai,
                onAction: () => ref.invalidate(discoverDataProvider),
              ),
            ],
            data: (data) => [
              _Columns(
                phone: phone,
                children: [
                  for (final tag in data.tags.take(3)) _TopicCard(tag: tag),
                ],
              ),
              // Topics are rail cards, which keep 13px below them.
              SizedBox(height: gap + 13),
              _FeaturedProjects(phone: phone),
              _SectionHeading(
                phone: phone,
                eyebrow: vi.feedViews.goiYChoBan,
                title: vi.feedViews.nguoiVietNenTheoDoi,
                action: _HeadingButton(
                  label: vi.common.chiaSeBaiViet,
                  icon: VnlfLucide.plus,
                  onPressed: () => context.push(
                    ref.read(sessionStateProvider) == null
                        ? '/login'
                        : '/compose',
                  ),
                ),
              ),
              SizedBox(height: gap),
              _Columns(
                phone: phone,
                children: [
                  for (final user in data.users.take(3))
                    _CreatorCard(user: user),
                ],
              ),
            ],
          ),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!phone)
          VnlfCenterPageHeader(
            title: vi.socialLayoutClient.khamPhaCongDong,
            trailing: const PageHeaderActions(),
          ),
        Expanded(child: list),
      ],
    );
  }
}

/// Three equal columns on wider screens, one under another on phones
/// (`.explore-grid`, `.creator-row`).
class _Columns extends StatelessWidget {
  const _Columns({required this.phone, required this.children});

  final bool phone;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (phone) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: children,
      );
    }
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          for (var index = 0; index < 3; index++)
            Expanded(
              child: index < children.length
                  ? children[index]
                  : const SizedBox.shrink(),
            ),
        ],
      ),
    );
  }
}

/// "Góc nhìn mới, mỗi ngày." with the search box that opens /search.
class _ExploreHero extends StatefulWidget {
  const _ExploreHero({required this.phone});

  final bool phone;

  @override
  State<_ExploreHero> createState() => _ExploreHeroState();
}

class _ExploreHeroState extends State<_ExploreHero> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _submit() =>
      context.push('/search?q=${Uri.encodeQueryComponent(_query.text.trim())}');

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final phone = widget.phone;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(
          phone ? VnlfDimensions.radiusMd : VnlfDimensions.radiusLg,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(phone ? 16 : 29),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(
                vi.feedViews.gocNhinMoiMoiNgay,
                style: VnlfTypography.h2(colors.ink),
              ),
            ),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Text(
                vi.feedViews.timBaiVietNguoiViet,
                style: VnlfTypography.body(colors.muted),
              ),
            ),
            SizedBox(height: phone ? 12 : 24),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 580),
              child: Container(
                // 44px on the website; phones keep a 48dp touch target.
                height: phone ? 48 : 44,
                padding: const EdgeInsets.only(left: 10, right: 8),
                decoration: BoxDecoration(
                  color: colors.surface,
                  border: Border.all(color: colors.line),
                  borderRadius: BorderRadius.circular(VnlfDimensions.radiusMd),
                ),
                child: Row(
                  spacing: 8,
                  children: [
                    VnlfIcon(VnlfLucide.search, size: 18, color: colors.muted),
                    Expanded(
                      child: Semantics(
                        label: vi.feedViews.tuKhoaKhamPha,
                        child: TextField(
                          controller: _query,
                          textInputAction: TextInputAction.search,
                          onSubmitted: (_) => _submit(),
                          style: VnlfTypography.plain(colors.ink),
                          decoration: InputDecoration(
                            isCollapsed: true,
                            filled: false,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            hintText: vi.feedViews.timLinuxDevopsCaramos,
                            hintStyle: VnlfTypography.plain(colors.muted),
                          ),
                        ),
                      ),
                    ),
                    Tooltip(
                      message: vi.common.timKiem,
                      child: Semantics(
                        button: true,
                        label: vi.common.timKiem,
                        child: SizedBox.square(
                          dimension: phone ? 46 : 28,
                          child: Center(
                            child: Material(
                              color: colors.brand,
                              borderRadius: BorderRadius.circular(
                                VnlfDimensions.radiusSm,
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(
                                  VnlfDimensions.radiusSm,
                                ),
                                onTap: _submit,
                                child: SizedBox.square(
                                  dimension: 28,
                                  child: Center(
                                    child: VnlfIcon(
                                      VnlfLucide.arrowUpRight,
                                      size: 15,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A topic card: "#", the tag, "Chủ đề cộng đồng" and "Khám phá ↗", which
/// opens the topic's page.
class _TopicCard extends StatefulWidget {
  const _TopicCard({required this.tag});

  final DiscoverTag tag;

  @override
  State<_TopicCard> createState() => _TopicCardState();
}

class _TopicCardState extends State<_TopicCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final phone =
        VnlfViewportSize.fromWidth(MediaQuery.sizeOf(context).width) ==
        VnlfViewportSize.mobile;
    final radius = BorderRadius.circular(VnlfDimensions.radiusLg);
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: radius,
        onHover: (value) => setState(() => _hovered = value),
        onTap: () => context.push('/t/${Uri.encodeComponent(widget.tag.slug)}'),
        child: Ink(
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border.all(
              color: _hovered
                  ? Color.lerp(colors.line, colors.brand, 0.4)!
                  : colors.line,
            ),
            borderRadius: radius,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 132),
            child: Padding(
              padding: EdgeInsets.all(phone ? 12 : 18),
              // The link keeps to the bottom (`margin-top: auto`).
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      VnlfIcon(VnlfLucide.hash, size: 18, color: colors.brand),
                      const SizedBox(height: 12),
                      Text(
                        widget.tag.name,
                        style: VnlfTypography.h3(colors.ink),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        vi.feedViews.chuDeCongDong,
                        style: VnlfTypography.meta(colors.muted),
                      ),
                    ],
                  ),
                  Semantics(
                    link: true,
                    child: Text.rich(
                      TextSpan(
                        text: vi.feedViews.khamPha2,
                        children: [
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: VnlfIcon(
                                VnlfLucide.arrowUpRight,
                                size: 14,
                                color: colors.brand,
                              ),
                            ),
                          ),
                        ],
                      ),
                      style: VnlfTypography.meta(
                        colors.brand,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A small label over a heading, with a button at the right
/// (`.section-heading`).
class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.phone,
    required this.eyebrow,
    required this.title,
    required this.action,
  });

  final bool phone;
  final String eyebrow;
  final String title;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      spacing: phone ? 8 : 15,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 7,
            children: [
              Text(
                eyebrow,
                style: VnlfTypography.meta(
                  colors.textSubtle,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Semantics(
                header: true,
                child: Text(title, style: VnlfTypography.h2(colors.ink)),
              ),
            ],
          ),
        ),
        action,
      ],
    );
  }
}

/// The website's `button-outline` with its icon after the label.
class _HeadingButton extends StatelessWidget {
  const _HeadingButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final VnlfLucide icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final phone =
        VnlfViewportSize.fromWidth(MediaQuery.sizeOf(context).width) ==
        VnlfViewportSize.mobile;
    final radius = BorderRadius.circular(VnlfDimensions.radiusMd);
    final button = Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: colors.line),
      ),
      child: InkWell(
        borderRadius: radius,
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 6,
            children: [
              Text(label, style: VnlfTypography.control(colors.ink)),
              VnlfIcon(icon, size: 16, color: colors.ink),
            ],
          ),
        ),
      ),
    );
    return Semantics(
      button: true,
      child: phone
          ? ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Center(child: button),
            )
          : button,
    );
  }
}

/// "Dự án nổi bật" with "Xem tất cả", hidden until there is a project, as
/// on the website.
class _FeaturedProjects extends ConsumerWidget {
  const _FeaturedProjects({required this.phone});

  final bool phone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(featuredProjectsProvider).valueOrNull ?? const [];
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(bottom: phone ? 8 : 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          _SectionHeading(
            phone: phone,
            eyebrow: vi.projects.tieuDe,
            title: vi.projects.duAnNoiBat,
            action: _HeadingButton(
              label: vi.projects.xemTatCa,
              icon: VnlfLucide.arrowUpRight,
              onPressed: () => context.push('/projects'),
            ),
          ),
          ProjectGrid(items: items),
        ],
      ),
    );
  }
}

/// A person to follow: avatar, follow button, name, handle and bio.
class _CreatorCard extends ConsumerStatefulWidget {
  const _CreatorCard({required this.user});

  final DiscoverUser user;

  @override
  ConsumerState<_CreatorCard> createState() => _CreatorCardState();
}

class _CreatorCardState extends ConsumerState<_CreatorCard> {
  late bool _following = widget.user.followedByViewer;
  bool _pending = false;

  @override
  void didUpdateWidget(_CreatorCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.followedByViewer != widget.user.followedByViewer) {
      _following = widget.user.followedByViewer;
    }
  }

  Future<void> _toggle() async {
    if (ref.read(sessionStateProvider) == null) {
      await context.push('/login');
      return;
    }
    final repository = ref.read(profileRelationshipRepositoryProvider);
    if (repository == null || _pending) return;
    setState(() => _pending = true);
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      await repository.setFollowing(
        widget.user.author.id,
        following: !_following,
      );
      if (!mounted) return;
      setState(() => _following = !_following);
      ref.invalidate(profileProvider(widget.user.author.username));
    } on AppFailure {
      messenger
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(vi.accountViews.chuaTheCapNhatTheo)),
        );
    } finally {
      if (mounted) setState(() => _pending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final phone =
        VnlfViewportSize.fromWidth(MediaQuery.sizeOf(context).width) ==
        VnlfViewportSize.mobile;
    final author = widget.user.author;
    final viewer = ref.watch(sessionStateProvider)?.userId;
    final profilePath = '/profile/${Uri.encodeComponent(author.username)}';
    final data = presentAuthor(author);
    final follow = Semantics(
      button: true,
      toggled: _following,
      child: Material(
        type: MaterialType.transparency,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VnlfDimensions.radiusSm),
          side: BorderSide(color: colors.brand),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(VnlfDimensions.radiusSm),
          onTap: _pending ? null : _toggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            child: Text(
              _following ? vi.feedViews.dangTheoDoi : vi.common.theoDoi,
              style: VnlfTypography.meta(colors.brand),
            ),
          ),
        ),
      ),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(VnlfDimensions.radiusLg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 3,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Semantics(
                    link: true,
                    label: format(vi.feedViews.xemHoSo, {
                      'name': author.displayName,
                    }),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => context.push(profilePath),
                      child: VnlfAvatar(author: data, size: 40),
                    ),
                  ),
                  if (author.id != viewer &&
                      ref.watch(profileRelationshipRepositoryProvider) != null)
                    phone
                        ? ConstrainedBox(
                            constraints: const BoxConstraints(
                              minHeight: 48,
                              minWidth: 48,
                            ),
                            child: Align(
                              alignment: Alignment.topRight,
                              widthFactor: 1,
                              heightFactor: 1,
                              child: follow,
                            ),
                          )
                        : follow,
                ],
              ),
            ),
            GestureDetector(
              onTap: () => context.push(profilePath),
              child: VnlfAuthorNameRow(author: data, showHandleInline: false),
            ),
            Text(
              '@${author.username}',
              style: VnlfTypography.meta(colors.muted),
            ),
            if (widget.user.bio.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 2),
                child: Text(
                  widget.user.bio,
                  style: VnlfTypography.meta(colors.muted),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
