import '../features/projects/detail/presentation/project_detail_screen.dart';
import '../features/projects/submission/project_submission_screen.dart';
import '../features/feedback/feedback.dart';
import '../features/feedback/presentation/feedback_attachment_dialog.dart';
import '../features/notifications/presentation/notification_bell.dart';
import '../features/notifications/presentation/notification_center.dart';

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../design_system/design_system.dart';
import '../core/request_identity.dart';
import '../domain/models.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/activity/presentation/activity_page.dart';
import '../features/composer/presentation/composer_screen.dart';
import '../features/channels/presentation/channels_screen.dart';
import '../features/channels/presentation/live_channel_state.dart';
import '../features/direct_messages/presentation/direct_messages_screen.dart';
import '../features/direct_messages/presentation/direct_message_state.dart';
import '../features/discover/presentation/discover_screen.dart';
import '../features/feed/presentation/feed_screen.dart';
import '../features/leaderboard/presentation/leaderboard_screen.dart';
import '../features/notifications/presentation/notifications_controller.dart';
import '../features/projects/presentation/projects_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/shared/presentation/session_avatar.dart';
import '../features/search/presentation/search_screen.dart';
import '../features/voice/presentation/voice_screen.dart';
import '../features/thread/presentation/thread_screen.dart';
import '../gallery/gallery_page.dart';
import '../i18n/vi.dart';
import 'providers.dart';

const _paths = <VnlfNavDestination, String>{
  VnlfNavDestination.feed: '/',
  VnlfNavDestination.explore: '/explore',
  VnlfNavDestination.messages: '/messages',
  VnlfNavDestination.voice: '/voice',
  VnlfNavDestination.projects: '/projects',
};

const composeRouteName = 'compose';
const editComposeRouteName = 'edit-compose';

/// Feature screens are supplied by the application composition root.
GoRouter createAppRouter({
  required Map<VnlfNavDestination, WidgetBuilder> screens,
  required Widget Function(BuildContext, String) postScreen,
  required Widget Function(BuildContext, String) profileScreen,
}) {
  if (!screens.keys.toSet().containsAll(VnlfNavDestination.values)) {
    throw ArgumentError('A screen builder is required for each destination.');
  }
  return GoRouter(
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          final destination =
              _paths.entries
                  .where((entry) => entry.value == state.uri.path)
                  .map((entry) => entry.key)
                  .firstOrNull ??
              VnlfNavDestination.feed;
          return VnlfAdaptiveShell(
            activeDestination: destination,
            onDestinationSelected: (value) => context.go(_paths[value]!),
            centerChild: child,
          );
        },
        routes: [
          for (final destination in VnlfNavDestination.values)
            GoRoute(
              path: _paths[destination]!,
              builder: (context, state) => screens[destination]!(context),
            ),
          GoRoute(
            path: '/posts/:id',
            builder: (context, state) =>
                postScreen(context, state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/users/:username',
            builder: (context, state) =>
                profileScreen(context, state.pathParameters['username']!),
          ),
        ],
      ),
    ],
  );
}

/// Public feature routes use repository-backed native screens.
GoRouter createMainRouter({
  GlobalKey<NavigatorState>? navigatorKey,
  List<NavigatorObserver>? rootObservers,
  List<NavigatorObserver>? shellObservers,
}) {
  const destinations = <VnlfNavDestination, String>{
    VnlfNavDestination.feed: '/',
    VnlfNavDestination.explore: '/discover',
    VnlfNavDestination.messages: '/channels',
    VnlfNavDestination.voice: '/voice',
    VnlfNavDestination.projects: '/projects',
  };
  return GoRouter(
    navigatorKey: navigatorKey,
    observers: rootObservers,
    routes: [
      GoRoute(
        path: '/gallery',
        builder: (context, state) => const GalleryPage(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) =>
            const LoginScreen(initialMode: AuthMode.register),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) =>
            const LoginScreen(initialMode: AuthMode.forgot),
      ),
      GoRoute(
        path: '/compose',
        name: composeRouteName,
        builder: (context, state) => const ComposerScreen(),
      ),
      GoRoute(
        path: '/compose/:id',
        name: editComposeRouteName,
        builder: (context, state) =>
            ComposerScreen(draftId: state.pathParameters['id']!),
      ),
      ShellRoute(
        observers: shellObservers,
        builder: (context, state, child) {
          final labels = <VnlfNavDestination, String>{
            VnlfNavDestination.feed: vi.socialChrome.bangTin,
            VnlfNavDestination.explore: vi.feedViews.khamPha2,
            VnlfNavDestination.messages: vi.common.tinNhan,
            VnlfNavDestination.voice: 'Voice',
            VnlfNavDestination.projects: vi.projects.tabDuAn,
          };
          final communication =
              state.uri.path == '/channels' ||
              state.uri.path.startsWith('/channels/') ||
              state.uri.path == '/messages' ||
              state.uri.path.startsWith('/messages/');
          final communicationDetail =
              communication && state.uri.path.split('/').length > 2;
          final matched = communication
              ? VnlfNavDestination.messages
              : state.uri.path.startsWith('/projects/')
              ? VnlfNavDestination.projects
              : destinations.entries
                    .where((entry) => entry.value == state.uri.path)
                    .map((entry) => entry.key)
                    .firstOrNull;
          final active = matched ?? VnlfNavDestination.feed;
          return Consumer(
            builder: (context, ref, _) {
              final session =
                  ref.watch(sessionProvider).valueOrNull ??
                  ref.watch(sessionStateProvider);
              final isArticleOrThread =
                  state.uri.path.startsWith('/thread/') ||
                  state.uri.path.startsWith('/a/') ||
                  state.uri.path.startsWith('/article/') ||
                  state.uri.path.startsWith('/articles/') ||
                  state.uri.path.startsWith('/posts/') ||
                  state.uri.path.startsWith('/post/');
              final threadId = isArticleOrThread
                  ? state.pathParameters['id']
                  : null;
              final profileRoute =
                  state.uri.path.startsWith('/profile/') ||
                  state.uri.path.startsWith('/user/') ||
                  state.uri.path.startsWith('/users/') ||
                  state.uri.path.startsWith('/u/');
              final isDetailRoute =
                  threadId != null ||
                  state.uri.path.startsWith('/projects/') ||
                  state.uri.path.startsWith('/project/') ||
                  state.uri.path == '/settings' ||
                  state.uri.path.startsWith('/profile/') ||
                  state.uri.path.startsWith('/user/') ||
                  state.uri.path.startsWith('/users/') ||
                  state.uri.path.startsWith('/u/') ||
                  state.uri.path == '/feedback' ||
                  state.uri.path.startsWith('/feedback/') ||
                  state.uri.path == '/search';
              final titleText = threadId != null
                  ? vi.common.baiViet
                  : state.uri.path == '/settings'
                  ? vi.common.caiDat
                  : state.uri.path == '/feedback' ||
                        state.uri.path.startsWith('/feedback/')
                  ? vi.app.common.gopYCuaToi
                  : state.uri.path.startsWith('/profile/') ||
                        state.uri.path.startsWith('/user/') ||
                        state.uri.path.startsWith('/users/') ||
                        state.uri.path.startsWith('/u/')
                  ? vi.common.hoSo
                  : state.uri.path == '/search'
                  ? vi.common.timKiem
                  : state.uri.path == '/leaderboard'
                  ? vi.socialChrome.bangDiemTuan
                  : state.uri.path == '/activity'
                  ? vi.app.common.hoatDong
                  : state.uri.path == '/notifications'
                  ? vi.common.thongBao
                  : null;
              final dmInbox = ref.watch(dmInboxProvider);
              final channels =
                  ref.watch(liveChannelsProvider).valueOrNull ?? const [];
              final hasUnreadChannels = channels.any((c) => c.unreadCount > 0);
              final hasUnreadMessages =
                  dmInbox.totalUnreadCount > 0 || hasUnreadChannels;
              final unreadDestinations = <VnlfNavDestination>{
                if (hasUnreadMessages) VnlfNavDestination.messages,
              };
              final notificationBadgeCount =
                  ref.watch(notificationBadgeCountProvider).valueOrNull ?? 0;
              return VnlfAdaptiveShell(
                unreadDestinations: unreadDestinations,
                notificationBadgeCount: notificationBadgeCount,
                centerMaxWidth: communication ? double.infinity : 1053,
                // A profile paints its theme's canvas across the column and
                // lays out its own margins, as the website does.
                centerFillsColumn: profileRoute,
                showMobileBottomNav: !communicationDetail,
                titleText: titleText,
                // Phones show chats, threads and the home feed full-bleed,
                // as the website does below 841px.
                centerPadding:
                    communication ||
                        profileRoute ||
                        (threadId != null || state.uri.path == '/') &&
                            VnlfViewportSize.fromWidth(
                                  MediaQuery.sizeOf(context).width,
                                ) ==
                                VnlfViewportSize.mobile
                    ? EdgeInsets.zero
                    : null,
                themeMode: ref.watch(themeModeProvider),
                onThemeModeChanged: (mode) =>
                    ref.read(themeModeProvider.notifier).setThemeMode(mode),
                activeDestination: active,
                highlightActiveDestination: matched != null,
                onDestinationSelected: (destination) =>
                    context.go(destinations[destination]!),
                // Posts carry their own "Quay lại bảng tin" bar, as on the website.
                onBack: !isDetailRoute || threadId != null
                    ? null
                    : () {
                        final router = GoRouter.maybeOf(context);
                        if (router?.canPop() == true) {
                          router!.pop();
                        } else if (state.uri.path.startsWith('/feedback/')) {
                          router?.go('/feedback');
                        } else if (state.uri.path.startsWith('/projects/') ||
                            state.uri.path.startsWith('/project/')) {
                          router?.go('/projects');
                        } else {
                          router?.go('/');
                        }
                      },
                backTooltip: vi.projects.quayLaiBuoc,
                onSearchTap: () => context.push('/search'),
                onNotificationsTap: (bell) =>
                    showNotificationsPopover(context, ref, bell),
                onComposeTap: () =>
                    context.push(session == null ? '/login' : '/compose'),
                composeSemanticLabel: vi.articleEditor.taoBaiDang,
                accountAvatar: session == null
                    ? null
                    : sessionAvatar(session, size: 28),
                sidebarAvatar: session == null
                    ? null
                    : sessionAvatar(
                        session,
                        size: 38,
                        cornerRadius: VnlfDimensions.radiusMd,
                      ),
                onSettingsTap: () => context.push('/settings'),
                onLogoutTap: session == null
                    ? null
                    : () => logoutWithFeedback(context, ref),
                logoutLabel: vi.settingsViews.dangXuat,
                onHelpTap: () =>
                    _launchWeb('https://vietnamlinuxfamily.net/help'),
                onFeedbackTap: () => showFeedbackDialog(context, ref),
                onSupportTap: () =>
                    _launchWeb('https://vietnamlinuxfamily.net/caramos'),
                onFacebookTap: () => _launchWeb(
                  'https://www.facebook.com/groups/vietnamlinuxcommunity',
                ),
                onTelegramTap: () =>
                    _launchWeb('https://t.me/vietnamlinuxfamily'),
                onDiscordTap: () => _launchWeb('https://discord.gg/gVAJDUMC2n'),
                onProfileTap: () {
                  final s =
                      ref.read(sessionStateProvider) ??
                      ref.read(sessionProvider).valueOrNull;
                  if (s != null && s.username.isNotEmpty) {
                    context.push('/profile/${Uri.encodeComponent(s.username)}');
                  } else {
                    context.push('/login');
                  }
                },
                showMobileHeader: !communicationDetail,
                centerChildHandlesScroll:
                    communication ||
                    const [
                      '/',
                      '/leaderboard',
                      '/activity',
                      '/notifications',
                      '/projects',
                      '/settings',
                      '/discover',
                      '/explore',
                      '/channels',
                      '/voice',
                      '/search',
                    ].contains(state.uri.path) ||
                    threadId != null ||
                    state.uri.path.startsWith('/profile/') ||
                    state.uri.path.startsWith('/user/') ||
                    state.uri.path.startsWith('/users/') ||
                    state.uri.path.startsWith('/u/') ||
                    state.uri.path == '/feedback' ||
                    state.uri.path.startsWith('/feedback/') ||
                    state.uri.path.startsWith('/projects/'),
                rightSidebarFooter: VnlfRailFooter(
                  copyright: vi.socialChrome.vnlfSocial2026,
                  links: [
                    (
                      vi.common.quyChuanCongDong,
                      () => _launchWeb(
                        'https://vietnamlinuxfamily.net/community-guidelines',
                      ),
                    ),
                    (
                      vi.common.riengTu,
                      () =>
                          _launchWeb('https://vietnamlinuxfamily.net/privacy'),
                    ),
                  ],
                ),
                // The website keeps its right rail on the feed and Khám phá;
                // other pages are wide there.
                rightSidebarChild:
                    const [
                      '/',
                      '/discover',
                      '/explore',
                    ].contains(state.uri.path)
                    ? const LeaderboardPanel(sidebar: true)
                    : null,
                destinationLabels: labels,
                brandTitlePrefix: 'VNLF ',
                brandTitleAccent: 'Social',
                brandLogoSemanticLabel: 'VNLF Social',
                loginLabel: session != null
                    ? session.displayName
                    : vi.common.dangNhap,
                loginSubtitleLabel: session != null
                    ? '@${session.username}'
                    : vi.socialChrome.dungDayDuTinhNang,
                supportLabel: vi.caramosSupport.tieuDe,
                feedbackLabel: vi.common.gopYBaoLoi,
                socialSectionLabel: vi.socialChrome.cacMangXaHoiKhac,
                settingsLabel: vi.common.caiDat,
                helpLabel: vi.socialChrome.troGiup,
                lightThemeTooltip: vi.app.common.sang,
                darkThemeTooltip: vi.app.common.toi,
                systemThemeTooltip: vi.settingsViews.tuDong,
                openDrawerTooltip: vi.socialChrome.moMenu,
                searchSemanticLabel: vi.socialChrome.moTimKiem,
                notificationsSemanticLabel: vi.common.thongBao,
                profileSemanticLabel: vi.app.shell.taiKhoanCaNhan,
                leftSidebarSemanticLabel: vi.app.shell.dieuHuong,
                mobileBottomNavSemanticLabel: vi.socialChrome.dieuHuongMobile,
                centerChild: child,
              );
            },
          );
        },
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: FeedScreen()),
          ),
          GoRoute(
            path: '/leaderboard',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: LeaderboardScreen()),
          ),
          GoRoute(
            path: '/activity',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ActivityPage()),
          ),
          GoRoute(
            path: '/notifications',
            // The website sends guests to sign in first.
            redirect: (context, state) =>
                ProviderScope.containerOf(context).read(sessionStateProvider) ==
                    null
                ? '/login'
                : null,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: NotificationCenter()),
          ),
          GoRoute(
            path: '/projects',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ProjectsScreen()),
          ),
          GoRoute(
            path: '/projects/submit',
            pageBuilder: (context, state) => NoTransitionPage(
              child: ProjectSubmissionScreen(
                onSubmitted: (slug) => context.go('/projects/$slug'),
              ),
            ),
          ),
          GoRoute(
            path: '/projects/:slug',
            pageBuilder: (context, state) => NoTransitionPage(
              child: ProjectDetailScreen(slug: state.pathParameters['slug']!),
            ),
          ),
          GoRoute(
            path: '/feedback',
            pageBuilder: (context, state) => NoTransitionPage(
              child: FeedbackHistoryScreen(
                onOpenThread: (id) =>
                    context.push('/feedback/${Uri.encodeComponent(id)}'),
              ),
            ),
          ),
          GoRoute(
            path: '/feedback/:id',
            pageBuilder: (context, state) => NoTransitionPage(
              child: FeedbackThreadScreen(
                ticketId: state.pathParameters['id']!,
                onBack: () => context.go('/feedback'),
              ),
            ),
          ),
          GoRoute(
            path: '/thread/:id',
            pageBuilder: (context, state) => NoTransitionPage(
              child: ThreadScreen(postId: state.pathParameters['id']!),
            ),
          ),
          for (final prefix in const [
            '/a',
            '/article',
            '/articles',
            '/posts',
            '/post',
          ])
            GoRoute(
              path: '$prefix/:id',
              pageBuilder: (context, state) => NoTransitionPage(
                child: ThreadScreen(postId: state.pathParameters['id']!),
              ),
            ),
          GoRoute(
            path: '/profile/:id',
            pageBuilder: (context, state) => NoTransitionPage(
              child: ProfileScreen(
                username: state.pathParameters['id']!,
                initialGuestbook:
                    state.uri.queryParameters['tab'] == 'guestbook',
              ),
            ),
          ),
          for (final prefix in const ['/user', '/users', '/u'])
            GoRoute(
              path: '$prefix/:id',
              pageBuilder: (context, state) => NoTransitionPage(
                child: ProfileScreen(
                  username: state.pathParameters['id']!,
                  initialGuestbook:
                      state.uri.queryParameters['tab'] == 'guestbook',
                ),
              ),
            ),
          GoRoute(
            path: '/project/:slug',
            pageBuilder: (context, state) => NoTransitionPage(
              child: ProjectDetailScreen(slug: state.pathParameters['slug']!),
            ),
          ),
          GoRoute(
            path: '/explore',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: DiscoverScreen()),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SettingsScreen()),
          ),
          GoRoute(
            path: '/discover',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: DiscoverScreen()),
          ),
          GoRoute(
            path: '/search',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SearchScreen()),
          ),
          GoRoute(
            path: '/channels',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ChannelsScreen()),
          ),
          GoRoute(
            path: '/channels/:slug',
            pageBuilder: (context, state) => NoTransitionPage(
              child: ChannelsScreen(channelSlug: state.pathParameters['slug']),
            ),
          ),
          GoRoute(
            path: '/messages',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: DirectMessagesScreen()),
          ),
          GoRoute(
            path: '/messages/:id',
            pageBuilder: (context, state) => NoTransitionPage(
              child: DirectMessagesScreen(
                conversationId: state.pathParameters['id'],
              ),
            ),
          ),
          GoRoute(
            path: '/voice',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: VoiceScreen()),
          ),
        ],
      ),
    ],
  );
}

Future<void> _launchWeb(String url) async {
  final uri = Uri.parse(url);
  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {}
}

bool _feedbackDialogOpen = false;

void showFeedbackDialog(BuildContext context, WidgetRef ref) {
  if (_feedbackDialogOpen) return;
  _feedbackDialogOpen = true;
  final account = ref.read(sessionStateProvider);
  if (account != null) {
    final pagePath =
        GoRouter.maybeOf(context)?.routeInformationProvider.value.uri.path ??
        '/';
    showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (_) => FeedbackAttachmentDialog(
            ownerId: account.userId,
            pagePath: pagePath,
          ),
        )
        .then((openHistory) {
          if (openHistory == true && context.mounted) context.push('/feedback');
        })
        .whenComplete(() => _feedbackDialogOpen = false);
    return;
  }
  final colors = VnlfColors.of(context);
  final session =
      ref.read(sessionStateProvider) ?? ref.read(sessionProvider).valueOrNull;
  final contentController = TextEditingController();
  final contactController = TextEditingController();
  final client = ref.read(apiClientProvider);
  final sessionScope = client.captureSession();
  final pagePath =
      GoRouter.maybeOf(context)?.routeInformationProvider.value.uri.path ?? '/';
  var tabIndex = 0; // 0 = feedback, 1 = bug
  var submitted = false;
  var submitting = false;
  var uncertain = false;
  String? error;
  String? draftSignature;
  String? submissionId;

  showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) {
        if (submitted) {
          return AlertDialog(
            backgroundColor: colors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(VnlfDimensions.radiusLg),
              side: BorderSide(color: colors.line),
            ),
            content: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: colors.brandSoft,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle_rounded,
                      size: 40,
                      color: colors.brand,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    vi.app.common.daGhiNhanPhan,
                    style: VnlfTypography.h2(colors.ink),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    vi.app.shell.camOnBanDa,
                    style: VnlfTypography.body(colors.muted),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.brand,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          VnlfDimensions.radiusMd,
                        ),
                      ),
                    ),
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text(vi.feedbackWidget.hoanTat),
                  ),
                ],
              ),
            ),
          );
        }

        return Dialog(
          backgroundColor: colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(VnlfDimensions.radiusLg),
            side: BorderSide(color: colors.line),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colors.brandSoft,
                            borderRadius: BorderRadius.circular(
                              VnlfDimensions.radiusMd,
                            ),
                          ),
                          child: Icon(
                            tabIndex == 0
                                ? Icons.favorite_border_rounded
                                : Icons.bug_report_outlined,
                            size: 22,
                            color: colors.brand,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                vi.feedbackWidget.giupVnlfTotHon,
                                style: VnlfTypography.h3(colors.ink),
                              ),
                              Text(
                                tabIndex == 0
                                    ? vi.app.shell.dongGopYKien
                                    : vi.app.shell.baoCaoLoiSu,
                                style: VnlfTypography.caption(colors.muted),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          tooltip: vi.common.dong,
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                    if (session != null)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            context.push('/feedback');
                          },
                          icon: const Icon(Icons.history),
                          label: Text(vi.app.common.gopYCuaToi),
                        ),
                      ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: colors.surfaceSoft,
                        borderRadius: BorderRadius.circular(
                          VnlfDimensions.radiusMd,
                        ),
                        border: Border.all(color: colors.line),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(
                                VnlfDimensions.radiusSm,
                              ),
                              onTap: submitting || uncertain
                                  ? null
                                  : () => setDialogState(() => tabIndex = 0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: tabIndex == 0
                                      ? colors.brand
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(
                                    VnlfDimensions.radiusSm,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  vi.feedbackWidget.gopY,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: tabIndex == 0
                                        ? Colors.white
                                        : colors.muted,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(
                                VnlfDimensions.radiusSm,
                              ),
                              onTap: submitting || uncertain
                                  ? null
                                  : () => setDialogState(() => tabIndex = 1),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: tabIndex == 1
                                      ? colors.brand
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(
                                    VnlfDimensions.radiusSm,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  vi.feedbackWidget.baoLoi,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: tabIndex == 1
                                        ? Colors.white
                                        : colors.muted,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (session != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colors.brandSoft,
                          borderRadius: BorderRadius.circular(
                            VnlfDimensions.radiusSm,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.verified_user_outlined,
                              size: 14,
                              color: colors.brand,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                format(vi.app.shell.guiVoiTaiKhoan, {
                                  'username': session.username,
                                }),
                                style: VnlfTypography.caption(colors.brand),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Text(
                      tabIndex == 0
                          ? vi.app.shell.moTaYKien
                          : vi.app.shell.moTaChiTiet,
                      style: VnlfTypography.meta(colors.ink),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: contentController,
                      enabled: !submitting && !uncertain,
                      maxLines: 4,
                      maxLength: 4000,
                      style: VnlfTypography.body(colors.ink),
                      decoration: InputDecoration(
                        hintText: tabIndex == 0
                            ? vi.app.shell.hayChoChungMinh
                            : vi.app.shell.cacBuocDeTai,
                        hintStyle: TextStyle(color: colors.muted, fontSize: 13),
                        filled: true,
                        fillColor: colors.surfaceSoft,
                        contentPadding: const EdgeInsets.all(12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            VnlfDimensions.radiusMd,
                          ),
                          borderSide: BorderSide(color: colors.line),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            VnlfDimensions.radiusMd,
                          ),
                          borderSide: BorderSide(color: colors.line),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            VnlfDimensions.radiusMd,
                          ),
                          borderSide: BorderSide(
                            color: colors.brand,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      vi.app.shell.emailHoacLienHe,
                      style: VnlfTypography.meta(colors.ink),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: contactController,
                      enabled: !submitting && !uncertain,
                      style: VnlfTypography.body(colors.ink),
                      decoration: InputDecoration(
                        hintText: 'example@domain.com',
                        hintStyle: TextStyle(color: colors.muted, fontSize: 13),
                        filled: true,
                        fillColor: colors.surfaceSoft,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            VnlfDimensions.radiusMd,
                          ),
                          borderSide: BorderSide(color: colors.line),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            VnlfDimensions.radiusMd,
                          ),
                          borderSide: BorderSide(color: colors.line),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            VnlfDimensions.radiusMd,
                          ),
                          borderSide: BorderSide(
                            color: colors.brand,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    if (error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          error!,
                          style: VnlfTypography.meta(colors.red),
                        ),
                      ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          style: TextButton.styleFrom(
                            foregroundColor: colors.muted,
                          ),
                          child: Text(vi.common.huy),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: colors.brand,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                VnlfDimensions.radiusMd,
                              ),
                            ),
                          ),
                          onPressed: submitting
                              ? null
                              : () async {
                                  final detail = contentController.text.trim();
                                  final contact = contactController.text.trim();
                                  if (detail.length < 20 ||
                                      detail.length > 4000) {
                                    setDialogState(
                                      () => error = vi.app.common.vuiLongNhap20,
                                    );
                                    return;
                                  }
                                  final signature =
                                      '$tabIndex\u0000$detail\u0000$contact';
                                  if (draftSignature != signature) {
                                    draftSignature = signature;
                                    submissionId = newRequestIdentity();
                                  }
                                  setDialogState(() {
                                    submitting = true;
                                    error = null;
                                  });
                                  try {
                                    sessionScope.ensureCurrent();
                                    final acknowledgment = await client
                                        .request<Map<String, dynamic>>(
                                          'POST',
                                          '/api/v1/feedback',
                                          body: jsonEncode({
                                            'clientSubmissionId': submissionId,
                                            'kind': tabIndex == 0
                                                ? 'FEEDBACK'
                                                : 'BUG',
                                            'detail': detail,
                                            'pagePath': pagePath,
                                            if (session == null &&
                                                contact.isNotEmpty)
                                              'contactEmail': contact,
                                            'assetIds': const <String>[],
                                          }),
                                        );
                                    sessionScope.ensureCurrent();
                                    if (acknowledgment['submissionId']
                                            is! String ||
                                        (acknowledgment['submissionId']
                                                as String)
                                            .isEmpty ||
                                        acknowledgment['reference']
                                            is! String ||
                                        (acknowledgment['reference'] as String)
                                            .isEmpty ||
                                        acknowledgment['rewardQueued']
                                            is! bool ||
                                        acknowledgment['duplicate'] is! bool) {
                                      throw const ParseFailure(
                                        'feedback.acknowledgment',
                                      );
                                    }
                                    if (ctx.mounted) {
                                      setDialogState(() => submitted = true);
                                    }
                                  } catch (failure) {
                                    if (ctx.mounted) {
                                      final ambiguous =
                                          failure is! HttpFailure ||
                                          failure.statusCode == 408 ||
                                          failure.statusCode >= 500;
                                      setDialogState(() {
                                        uncertain = uncertain || ambiguous;
                                        error = uncertain
                                            ? vi.app.shell.chuaXacNhanDuoc
                                            : vi.app.shell.khongGuiDuocGop;
                                      });
                                    }
                                  } finally {
                                    if (ctx.mounted) {
                                      setDialogState(() => submitting = false);
                                    }
                                  }
                                },
                          icon: const Icon(Icons.send_rounded, size: 16),
                          label: Text(
                            vi.feedbackWidget.guiChoVnlf,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
  ).then((_) {
    _feedbackDialogOpen = false;
    contentController.dispose();
    contactController.dispose();
  });
}
