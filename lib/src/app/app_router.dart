import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../design_system/design_system.dart';
import '../gallery/gallery_page.dart';

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

/// App routes use design-system states until feature screens are connected.
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
          return VnlfAdaptiveShell(
            activeDestination: active,
            onDestinationSelected: (destination) =>
                context.go(destinations[destination]!),
            destinationLabels: labels,
            brandTitlePrefix: 'VNLF ',
            brandTitleAccent: 'Social',
            brandLogoSemanticLabel: 'VNLF Social',
            openDrawerTooltip: english
                ? 'Open navigation menu'
                : 'Mở menu điều hướng',
            searchSemanticLabel: english ? 'Search' : 'Tìm kiếm',
            notificationsSemanticLabel: english ? 'Notifications' : 'Thông báo',
            profileSemanticLabel: english ? 'Profile' : 'Tài khoản cá nhân',
            leftSidebarSemanticLabel: english ? 'Navigation' : 'Điều hướng',
            mobileBottomNavSemanticLabel: english ? 'Navigation' : 'Điều hướng',
            centerChild: child,
          );
        },
        routes: [
          for (final entry in <String, (String, String, IconData)>{
            '/': ('Bảng tin', 'Feed', Icons.article_outlined),
            '/thread/:id': ('Bài viết', 'Thread', Icons.forum_outlined),
            '/profile/:id': ('Trang cá nhân', 'Profile', Icons.person_outline),
            '/search': ('Tìm kiếm', 'Search', Icons.search),
            '/channels': ('Kênh', 'Channels', Icons.chat_bubble_outline),
            '/discover': ('Khám phá', 'Discover', Icons.explore_outlined),
            '/leaderboard': (
              'Bảng xếp hạng',
              'Leaderboard',
              Icons.emoji_events_outlined,
            ),
            '/settings': ('Cài đặt', 'Settings', Icons.settings_outlined),
            '/voice': ('Voice', 'Voice', Icons.mic_none),
            '/projects': ('Dự án', 'Projects', Icons.workspaces_outline),
          }.entries)
            GoRoute(
              path: entry.key,
              builder: (context, state) {
                final english =
                    Localizations.localeOf(context).languageCode == 'en';
                return VnlfStateCard(
                  icon: entry.value.$3,
                  title: english ? entry.value.$2 : entry.value.$1,
                  message: english
                      ? 'This screen is not available yet.'
                      : 'Màn hình này chưa có nội dung.',
                );
              },
            ),
        ],
      ),
    ],
  );
}
