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
    final mobile =
        VnlfViewportSize.fromWidth(MediaQuery.sizeOf(context).width) ==
        VnlfViewportSize.mobile;
    final profile = ref.watch(profileProvider(widget.username));
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        if (!mobile && context.canPop()) ...[
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
          loading: () => const [Center(child: CircularProgressIndicator())],
          error: (error, stack) => [
            FeatureLoadError(
              onRetry: () => ref.invalidate(profileProvider(widget.username)),
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
              : [
                  ProfileHeader(
                    profile: value,
                    actions: ProfileActions(
                      profile: value,
                      profileKey: widget.username,
                    ),
                  ),
                  const SizedBox(height: 12),
                  VnlfFeedTabBar(
                    tabs: _tabs(value),
                    selectedIndex: value.guestbookEnabled
                        ? _tab
                        : _tab.clamp(0, 2),
                    onTabSelected: (index) => setState(() => _tab = index),
                    semanticLabel: vi.accountViews.noiDungHoSo,
                  ),
                  const SizedBox(height: 12),
                  if (_tab == 3 &&
                      (value.guestbookEnabled ||
                          ref.watch(sessionStateProvider)?.userId ==
                              value.author.id))
                    ProfileGuestbook(
                      key: ValueKey(
                        '${value.author.username}:${ref.watch(sessionStateProvider)?.userId}',
                      ),
                      username: value.author.username,
                      ownerId: value.author.id,
                    )
                  else
                    ProfileContent(
                      username: value.author.username,
                      tab: _tab < 3 ? _tab : 0,
                    ),
                ],
        ),
      ],
    );
  }

  List<String> _tabs(PublicProfile profile) {
    return [
      vi.common.baiViet,
      vi.common.binhLuan,
      vi.socialChrome.duAn,
      if (profile.guestbookEnabled ||
          ref.watch(sessionStateProvider)?.userId == profile.author.id)
        vi.guestbook.soLuuBut,
    ];
  }
}
