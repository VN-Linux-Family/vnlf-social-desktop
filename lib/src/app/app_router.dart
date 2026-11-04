import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../design_system/design_system.dart';
import '../features/channels/presentation/channels_screen.dart';
import '../features/channels/presentation/channel_directory.dart';
import '../features/discover/presentation/discover_screen.dart';
import '../features/feed/presentation/feed_screen.dart';
import '../features/leaderboard/presentation/leaderboard_screen.dart';
import '../features/projects/presentation/projects_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/search/presentation/search_screen.dart';
import '../features/voice/presentation/voice_screen.dart';
import '../features/thread/presentation/thread_screen.dart';
import '../features/thread/presentation/thread_sidebar.dart';
import '../gallery/gallery_page.dart';
import 'providers.dart';

const _paths = <VnlfNavDestination, String>{
  VnlfNavDestination.feed: '/',
  VnlfNavDestination.explore: '/explore',
  VnlfNavDestination.messages: '/messages',
  VnlfNavDestination.voice: '/voice',
  VnlfNavDestination.projects: '/projects',
};

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
GoRouter createMainRouter() {
  const destinations = <VnlfNavDestination, String>{
    VnlfNavDestination.feed: '/',
    VnlfNavDestination.explore: '/discover',
    VnlfNavDestination.messages: '/channels',
    VnlfNavDestination.voice: '/voice',
    VnlfNavDestination.projects: '/projects',
  };
  return GoRouter(
    routes: [
      GoRoute(
        path: '/gallery',
        builder: (context, state) => const GalleryPage(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          final english = Localizations.localeOf(context).languageCode == 'en';
          final labels = english
              ? const <VnlfNavDestination, String>{
                  VnlfNavDestination.feed: 'Feed',
                  VnlfNavDestination.explore: 'Discover',
                  VnlfNavDestination.messages: 'Messages',
                  VnlfNavDestination.voice: 'Voice',
                  VnlfNavDestination.projects: 'Projects',
                }
              : const <VnlfNavDestination, String>{
                  VnlfNavDestination.feed: 'Bảng tin',
                  VnlfNavDestination.explore: 'Khám phá',
                  VnlfNavDestination.messages: 'Tin nhắn',
                  VnlfNavDestination.voice: 'Voice',
                  VnlfNavDestination.projects: 'Dự án',
                };
          final active =
              destinations.entries
                  .where((entry) => entry.value == state.uri.path)
                  .map((entry) => entry.key)
                  .firstOrNull ??
              VnlfNavDestination.feed;
          return Consumer(
            builder: (context, ref, _) => VnlfAdaptiveShell(
              themeMode: ref.watch(themeModeProvider),
              onThemeModeChanged: (mode) =>
                  ref.read(themeModeProvider.notifier).state = mode,
              activeDestination: active,
              onDestinationSelected: (destination) =>
                  context.go(destinations[destination]!),
              onSearchTap: () => context.push('/search'),
              centerChildHandlesScroll:
                  const [
                    '/',
                    '/leaderboard',
                    '/projects',
                    '/settings',
                    '/discover',
                    '/channels',
                    '/voice',
                    '/search',
                  ].contains(state.uri.path) ||
                  state.uri.path.startsWith('/thread/') ||
                  state.uri.path.startsWith('/profile/'),
              rightSidebarChild: state.uri.path.startsWith('/thread/')
                  ? ThreadSidebar(postId: state.pathParameters['id']!)
                  : state.uri.path == '/'
                  ? const LeaderboardPanel(sidebar: true)
                  : state.uri.path == '/channels'
                  ? const ActiveCommunityMembers()
                  : null,
              destinationLabels: labels,
              brandTitlePrefix: 'VNLF ',
              brandTitleAccent: 'Social',
              brandLogoSemanticLabel: 'VNLF Social',
              loginLabel: english ? 'Log in' : 'Đăng nhập',
              loginSubtitleLabel: english
                  ? 'Access all community features'
                  : 'Để dùng đầy đủ tính năng',
              supportLabel: english ? 'Support CaramOS' : 'Hỗ trợ CaramOS',
              feedbackLabel: english ? 'Feedback' : 'Góp ý & báo lỗi',
              socialSectionLabel: english
                  ? 'VNLF on social networks'
                  : 'VNLF trên các mạng xã hội khác',
              settingsLabel: english ? 'Settings' : 'Cài đặt',
              helpLabel: english ? 'Help' : 'Trợ giúp',
              lightThemeTooltip: english ? 'Light' : 'Sáng',
              darkThemeTooltip: english ? 'Dark' : 'Tối',
              systemThemeTooltip: english ? 'System' : 'Tự động',
              openDrawerTooltip: english
                  ? 'Open navigation menu'
                  : 'Mở menu điều hướng',
              searchSemanticLabel: english ? 'Search' : 'Tìm kiếm',
              notificationsSemanticLabel: english
                  ? 'Notifications'
                  : 'Thông báo',
              profileSemanticLabel: english ? 'Profile' : 'Tài khoản cá nhân',
              leftSidebarSemanticLabel: english ? 'Navigation' : 'Điều hướng',
              mobileBottomNavSemanticLabel: english
                  ? 'Navigation'
                  : 'Điều hướng',
              centerChild: child,
            ),
          );
        },
        routes: [
          GoRoute(path: '/', builder: (context, state) => const FeedScreen()),
          GoRoute(
            path: '/leaderboard',
            builder: (context, state) => const LeaderboardScreen(),
          ),
          GoRoute(
            path: '/projects',
            builder: (context, state) => const ProjectsScreen(),
          ),
          GoRoute(
            path: '/thread/:id',
            builder: (context, state) =>
                ThreadScreen(postId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/profile/:id',
            builder: (context, state) =>
                ProfileScreen(username: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/discover',
            builder: (context, state) => const DiscoverScreen(),
          ),
          GoRoute(
            path: '/search',
            builder: (context, state) => const SearchScreen(),
          ),
          GoRoute(
            path: '/channels',
            builder: (context, state) => const ChannelsScreen(),
          ),
          GoRoute(
            path: '/voice',
            builder: (context, state) => const VoiceScreen(),
          ),
        ],
      ),
    ],
  );
}
