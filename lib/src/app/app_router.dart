import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../design_system/design_system.dart';
import '../features/auth/presentation/login_screen.dart';
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
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
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
            builder: (context, ref, _) {
              final session =
                  ref.watch(sessionProvider).valueOrNull ??
                  ref.watch(sessionStateProvider);
              return VnlfAdaptiveShell(
                themeMode: ref.watch(themeModeProvider),
                onThemeModeChanged: (mode) =>
                    ref.read(themeModeProvider.notifier).state = mode,
                activeDestination: active,
                onDestinationSelected: (destination) =>
                    context.go(destinations[destination]!),
                onSearchTap: () => context.push('/search'),
                onNotificationsTap: () => _showNotificationsModal(context, ref),
                onSettingsTap: () => context.push('/settings'),
                onHelpTap: () => _showHelpDialog(context),
                onFeedbackTap: () => _showFeedbackDialog(context, ref),
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
                loginLabel: session != null
                    ? session.displayName
                    : (english ? 'Log in' : 'Đăng nhập'),
                loginSubtitleLabel: session != null
                    ? '@${session.username}'
                    : (english
                          ? 'Access all community features'
                          : 'Để dùng đầy đủ tính năng'),
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
              );
            },
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

Future<void> _launchWeb(String url) async {
  final uri = Uri.parse(url);
  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {}
}

void _showHelpDialog(BuildContext context) {
  final english = Localizations.localeOf(context).languageCode == 'en';
  final colors = VnlfColors.of(context);
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: colors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(VnlfDimensions.radiusLg),
        side: BorderSide(color: colors.line),
      ),
      title: Row(
        children: [
          BrandAssets.logo(size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              english
                  ? 'Help & Community Guidelines'
                  : 'Trợ giúp & Nguyên tắc VNLF',
              style: VnlfTypography.h3(colors.ink),
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                english
                    ? 'About Vietnam Linux Family'
                    : 'Về Vietnam Linux Family',
                style: VnlfTypography.control(
                  colors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                english
                    ? 'A non-profit community for Linux & open source enthusiasts in Vietnam: sharing knowledge, technical articles, projects and discussions.'
                    : 'Cộng đồng phi lợi nhuận dành cho người dùng, lập trình viên và những ai yêu thích Linux & Mã nguồn mở tại Việt Nam. Nơi chia sẻ bài viết kỹ thuật, dự án và giao lưu.',
                style: VnlfTypography.body(colors.muted),
              ),
              const SizedBox(height: 14),
              Text(
                english ? 'Community Guidelines' : 'Nguyên tắc cộng đồng',
                style: VnlfTypography.control(
                  colors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                english
                    ? '• Respect all members and maintain civilized discussions.\n• Share constructive open source content.\n• No spam, piracy, or malicious code.'
                    : '• Tôn trọng các thành viên, văn minh và cầu thị.\n• Chia sẻ kiến thức bổ ích về Linux & nguồn mở.\n• Không spam, không vi phạm bản quyền hay phần mềm độc hại.',
                style: VnlfTypography.body(colors.muted),
              ),
              const SizedBox(height: 14),
              Text(
                english
                    ? 'Markdown & Code Formatting'
                    : 'Định dạng bài viết & mã nguồn',
                style: VnlfTypography.control(
                  colors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                english
                    ? 'You can format code blocks with triple backticks (```bash, ```python, etc.) and use standard Markdown syntax in posts and comments.'
                    : 'Hỗ trợ cú pháp Markdown chuẩn: sử dụng ``` để định dạng khối code (```bash, ```python,...), định dạng trích dẫn và danh sách.',
                style: VnlfTypography.body(colors.muted),
              ),
            ],
          ),
        ),
      ),
      actions: [
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: colors.brand,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(english ? 'Understood' : 'Đã hiểu'),
        ),
      ],
    ),
  );
}

void _showFeedbackDialog(BuildContext context, WidgetRef ref) {
  final english = Localizations.localeOf(context).languageCode == 'en';
  final colors = VnlfColors.of(context);
  final contentController = TextEditingController();
  final contactController = TextEditingController();
  var tabIndex = 0; // 0 = feedback, 1 = bug
  var submitted = false;

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
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Icon(Icons.check_circle_rounded, size: 52, color: colors.brand),
                const SizedBox(height: 14),
                Text(
                  english ? 'Feedback Received!' : 'Đã ghi nhận phản hồi!',
                  style: VnlfTypography.h2(colors.ink),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  english
                      ? 'Thank you for helping make Vietnam Linux Family better.'
                      : 'Cảm ơn bạn đã đóng góp giúp VNLF ngày càng hoàn thiện hơn.',
                  style: VnlfTypography.body(colors.muted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.brand,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(english ? 'Close' : 'Đóng'),
                ),
              ],
            ),
          );
        }

        return AlertDialog(
          backgroundColor: colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(VnlfDimensions.radiusLg),
            side: BorderSide(color: colors.line),
          ),
          title: Text(
            english ? 'Help Make VNLF Better' : 'Giúp VNLF tốt hơn',
            style: VnlfTypography.h3(colors.ink),
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: Text(english ? 'Feedback' : 'Góp ý'),
                          selected: tabIndex == 0,
                          selectedColor: colors.brandSoft,
                          checkmarkColor: colors.brand,
                          onSelected: (_) => setDialogState(() => tabIndex = 0),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: Text(english ? 'Bug Report' : 'Báo lỗi'),
                          selected: tabIndex == 1,
                          selectedColor: colors.brandSoft,
                          checkmarkColor: colors.brand,
                          onSelected: (_) => setDialogState(() => tabIndex = 1),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: contentController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: tabIndex == 0
                          ? (english
                                ? 'Your feedback or suggestion'
                                : 'Ý kiến đóng góp hoặc đề xuất của bạn')
                          : (english
                                ? 'Describe the issue or bug'
                                : 'Mô tả chi tiết lỗi gặp phải'),
                      hintText: tabIndex == 0
                          ? (english
                                ? 'Tell us what could be improved...'
                                : 'Hãy cho chúng mình biết điều gì cần cải thiện...')
                          : (english
                                ? 'Steps to reproduce the bug...'
                                : 'Các bước để tái hiện lỗi...'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: contactController,
                    decoration: InputDecoration(
                      labelText: english
                          ? 'Email or contact (optional)'
                          : 'Email hoặc liên hệ (không bắt buộc)',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(english ? 'Cancel' : 'Hủy'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: colors.brand,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (contentController.text.trim().isEmpty) return;
                setDialogState(() => submitted = true);
              },
              child: Text(english ? 'Submit' : 'Gửi phản hồi'),
            ),
          ],
        );
      },
    ),
  );
}

void _showNotificationsModal(BuildContext context, WidgetRef ref) {
  final english = Localizations.localeOf(context).languageCode == 'en';
  final colors = VnlfColors.of(context);
  final session =
      ref.read(sessionStateProvider) ?? ref.read(sessionProvider).valueOrNull;

  showModalBottomSheet<void>(
    context: context,
    backgroundColor: colors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(VnlfDimensions.radiusLg),
      ),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.notifications_active_rounded,
                      color: colors.brand,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      english ? 'Notifications' : 'Thông báo',
                      style: VnlfTypography.h2(colors.ink)
                          .copyWith(fontSize: 18),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
            const Divider(height: 20),
            if (session != null) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: colors.brandSoft,
                  child: Icon(
                    Icons.forum_rounded,
                    color: colors.brand,
                    size: 20,
                  ),
                ),
                title: Text(
                  english
                      ? 'Welcome to VNLF Social!'
                      : 'Chào mừng bạn đến với VNLF Social!',
                  style: VnlfTypography.control(
                    colors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  english
                      ? 'You are signed in as @${session.username}. Community alerts and replies will be listed here.'
                      : 'Bạn đã đăng nhập với tài khoản @${session.username}. Bạn sẽ nhận thông báo khi có người tương tác với bài viết của bạn.',
                  style: VnlfTypography.meta(colors.muted),
                ),
                trailing: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: colors.brand,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  english
                      ? 'You have caught up with all notifications.'
                      : 'Bạn đã xem hết các thông báo mới.',
                  style: VnlfTypography.caption(colors.muted),
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.bg,
                  borderRadius: BorderRadius.circular(VnlfDimensions.radiusMd),
                  border: Border.all(color: colors.line),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.mark_email_unread_outlined,
                      size: 40,
                      color: colors.brand,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      english
                          ? 'Sign in to see notifications'
                          : 'Đăng nhập để xem thông báo',
                      style: VnlfTypography.control(
                        colors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      english
                          ? 'Get real-time updates when someone replies, likes your posts, or mentions you.'
                          : 'Nhận thông báo tức thì khi có người bình luận, thích bài viết hoặc nhắc tên bạn.',
                      textAlign: TextAlign.center,
                      style: VnlfTypography.body(colors.muted),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: colors.brand,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        context.push('/login');
                      },
                      child: Text(english ? 'Sign In Now' : 'Đăng nhập ngay'),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
          ],
        ),
      ),
    ),
  );
}
