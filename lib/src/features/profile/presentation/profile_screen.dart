import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/design_system.dart';
import '../../../app/providers.dart';
import '../../../i18n/vi.dart';
import '../../shared/presentation/feature_widgets.dart';
import '../domain/public_profile.dart';
import 'profile_actions.dart';
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
  @override
  void initState() {
    super.initState();
    if (widget.initialGuestbook) _tab = 3;
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
    return ColoredBox(
      color: palette.canvas,
      child: ListView(
        padding: phone
            ? EdgeInsets.fromLTRB(gutter, 10, gutter, 20)
            : const EdgeInsets.fromLTRB(38, 34, 38, 80),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!phone && context.canPop()) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        tooltip: vi.app.common.quayLai,
                        icon: const Icon(Icons.arrow_back_rounded),
                        onPressed: () => context.pop(),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
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
