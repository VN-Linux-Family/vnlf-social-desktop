import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/design_system.dart';
import '../../../app/providers.dart';
import '../../../i18n/vi.dart';
import '../../shared/presentation/feature_widgets.dart';
import '../../shared/presentation/page_header_actions.dart';
import '../domain/public_profile.dart';
import 'people_dialog.dart';
import 'profile_actions.dart';
import 'profile_card.dart';
import 'profile_content.dart';
import 'profile_data.dart';
import 'profile_guestbook.dart';
import 'profile_header.dart';
import 'profile_palette.dart';
import 'profile_tabs.dart';

/// The website's profile page: one 720px column on the profile theme's
/// canvas, which fills the space right of the sidebar.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({
    super.key,
    required this.username,
    this.initialGuestbook = false,
  });
  final String username;
  final bool initialGuestbook;
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  int _tab = 0;
  final _scroll = ScrollController();

  /// The desktop page header's height and the gap under it.
  static const _headerSpace = 64.0 + 18;

  @override
  void initState() {
    super.initState();
    if (widget.initialGuestbook) _tab = 3;
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.username != widget.username ||
        oldWidget.initialGuestbook != widget.initialGuestbook) {
      _tab = widget.initialGuestbook ? 3 : 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final phone = width < 841;
    final profile = ref.watch(profileProvider(widget.username));
    final palette = ProfilePalette.of(
      context,
      profile.valueOrNull?.decor ?? const ProfileDecor(),
    );
    final gutter = VnlfDimensions.mobileGutter(width);
    final list = ListView(
      controller: _scroll,
      padding: phone
          ? EdgeInsets.fromLTRB(gutter, 10, gutter, 20)
          : const EdgeInsets.fromLTRB(38, 34 + _headerSpace, 38, 80),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ...profile.when(
                  loading: () => const [
                    Center(child: CircularProgressIndicator()),
                  ],
                  error: (error, stack) => [
                    FeatureLoadError(
                      onRetry: () =>
                          ref.invalidate(profileProvider(widget.username)),
                    ),
                  ],
                  data: (value) => value == null
                      ? [
                          VnlfStateCard(
                            icon: Icons.person_outline,
                            title: vi.app.profile.khongTimThayHo,
                            message: vi.app.profile.hoSoNayHien,
                          ),
                        ]
                      : _page(value, palette, phone),
                ),
              ],
            ),
          ),
        ),
      ],
    );
    return ProfilePageScope(
      username: profile.valueOrNull?.author.username ?? widget.username,
      child: ColoredBox(
        color: palette.canvas,
        child: phone
            ? list
            : Stack(
                children: [
                  Positioned.fill(child: list),
                  // The website's title bar floats over the profile and
                  // stays 12px from the top once the page scrolls.
                  ListenableBuilder(
                    listenable: _scroll,
                    builder: (context, _) => Positioned(
                      top: math.max(
                        12,
                        34 - (_scroll.hasClients ? _scroll.offset : 0),
                      ),
                      left: 38,
                      right: 38,
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 720),
                          child: const _FloatingHeader(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  List<Widget> _page(PublicProfile value, ProfilePalette palette, bool phone) {
    final owner = ref.watch(sessionStateProvider)?.userId == value.author.id;
    final guestbook = value.guestbookEnabled || owner;
    final tabs = _tabs(value.author.username, guestbook);
    final selected = _tab.clamp(0, tabs.length - 1);
    return [
      ProfileHeader(
        profile: value,
        palette: palette,
        actions: ProfileActions(profile: value, profileKey: widget.username),
        onOpenPeople: ref.watch(peopleRepositoryProvider) == null
            ? null
            : (tab) => showPeopleDialog(
                context,
                username: value.author.username,
                name: value.author.displayName,
                initial: tab,
              ),
        tabs: ProfileTabs(
          tabs: tabs,
          selected: selected,
          accent: palette.accent,
          onSelected: (index) => setState(() => _tab = index),
        ),
      ),
      SizedBox(height: phone ? 8 : 16),
      if (selected == 3)
        ProfileGuestbook(
          key: ValueKey(
            '${value.author.username}:${ref.watch(sessionStateProvider)?.userId}',
          ),
          username: value.author.username,
          ownerId: value.author.id,
        )
      else
        ProfileContent(username: value.author.username, tab: selected),
    ];
  }

  /// The website's tabs and counts: the loaded posts and comments, the
  /// projects once loaded, and the guestbook's total from the server.
  List<ProfileTab> _tabs(String username, bool guestbook) {
    final posts = ref.watch(profilePostsProvider(username)).valueOrNull;
    final comments = ref.watch(profileCommentsProvider(username)).valueOrNull;
    final projects = ref.watch(profileProjectsProvider(username)).valueOrNull;
    final entries = guestbook
        ? ref.watch(profileGuestbookProvider(username)).valueOrNull
        : null;
    return [
      (label: vi.common.baiViet, icon: null, count: posts?.items.length),
      (label: vi.common.binhLuan, icon: null, count: comments?.items.length),
      (
        label: vi.projects.tabDuAn,
        icon: VnlfLucide.folderGit2,
        count: projects?.items.length,
      ),
      if (guestbook)
        (
          label: vi.guestbook.soLuuBut,
          icon: VnlfLucide.bookOpen,
          count: entries?.total,
        ),
    ];
  }
}

/// The website's frosted title bar on a profile: "Hồ sơ", then search,
/// the bell and the viewer's avatar, with a way back when there is one.
class _FloatingHeader extends StatelessWidget {
  const _FloatingHeader();

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final radius = BorderRadius.circular(VnlfDimensions.radiusLg);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: const [
          BoxShadow(
            color: Color(0x8C000000),
            offset: Offset(0, 12),
            blurRadius: 30,
            spreadRadius: -20,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.fromLTRB(18, 10, 12, 10),
            decoration: BoxDecoration(
              color: colors.surface.withValues(alpha: .76),
              border: Border.all(color: colors.surface.withValues(alpha: .55)),
              borderRadius: radius,
            ),
            child: Row(
              spacing: 10,
              children: [
                if (context.canPop())
                  IconButton(
                    tooltip: vi.app.common.quayLai,
                    icon: const VnlfIcon(VnlfLucide.arrowLeft, size: 20),
                    onPressed: () => context.pop(),
                  ),
                Expanded(
                  child: Text(
                    vi.common.hoSo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: VnlfTypography.pageTitle(colors.ink),
                  ),
                ),
                const PageHeaderActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
