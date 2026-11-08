import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/android_background_service.dart';
import '../../../core/desktop_tray_service.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/models.dart';
import '../../notifications/presentation/push_notifications_providers.dart';
import '../../shared/presentation/author_mapper.dart';
import '../../shared/presentation/feature_samples.dart';
import '../../shared/presentation/feature_widgets.dart';
import '../../updates/presentation/update_panel.dart';
import 'account_profile_screen.dart';
import '../blocked/presentation/blocked_people_panel.dart';
import '../preferences/preferences_panel.dart';
import '../text_size/text_size.dart';
import 'security_sessions_panel.dart';

const appVersion = String.fromEnvironment('APP_VERSION', defaultValue: '0.1.0');
const isProduction = bool.fromEnvironment('PRODUCTION', defaultValue: false);
bool get isDevBuild => !kReleaseMode && !isProduction;

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final english = Localizations.localeOf(context).languageCode == 'en';
    final mobile =
        VnlfViewportSize.fromWidth(MediaQuery.sizeOf(context).width) ==
        VnlfViewportSize.mobile;
    final colors = VnlfColors.of(context);
    final theme = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final themeStorageFailure = ref.watch(themeStorageFailureProvider);
    final localeStorageFailure = ref.watch(localeStorageFailureProvider);
    final sessionStorageFailure = ref.watch(sessionStorageFailureProvider);
    final signingOut = ref.watch(authControllerProvider).isLoading;
    final language =
        locale?.languageCode ?? Localizations.localeOf(context).languageCode;
    final session =
        ref.watch(sessionProvider).valueOrNull ??
        ref.watch(sessionStateProvider);
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        if (!mobile) ...[
          FeatureHeader(
            title: english ? 'Settings' : 'Cài đặt',
            showSettings: false,
          ),
          const SizedBox(height: 12),
        ],
        const AppUpdatePanel(),
        const SizedBox(height: 12),
        FeatureSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                english ? 'Account' : 'Tài khoản',
                style: VnlfTypography.h2(colors.ink),
              ),
              const SizedBox(height: 12),
              if (session != null) ...[
                Row(
                  children: [
                    VnlfAvatar(
                      author: presentAuthor(
                        Author(
                          id: session.userId,
                          username: session.username,
                          displayName: session.displayName,
                          avatarUrl: session.avatarUrl,
                          style: session.style,
                        ),
                      ),
                      size: 48,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            session.displayName,
                            style: VnlfTypography.control(
                              colors.ink,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '@${session.username}',
                            style: VnlfTypography.meta(colors.muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (!offlineFeatures) ...[
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const AccountProfileScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: Text(english ? 'Edit profile' : 'Chỉnh sửa hồ sơ'),
                  ),
                ],
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.red,
                    side: BorderSide(color: colors.red),
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: signingOut
                      ? null
                      : () => logoutWithFeedback(context, ref),
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: Text(english ? 'Log out' : 'Đăng xuất'),
                ),
              ] else ...[
                Row(
                  children: [
                    const VnlfGuestAvatarBox(size: 44),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            english ? 'Guest' : 'Khách',
                            style: VnlfTypography.control(
                              colors.ink,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            english
                                ? 'Not logged in'
                                : 'Chưa đăng nhập tài khoản',
                            style: VnlfTypography.meta(colors.muted),
                          ),
                        ],
                      ),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: colors.brand,
                      ),
                      onPressed: () => context.push('/login'),
                      child: Text(english ? 'Log in' : 'Đăng nhập'),
                    ),
                  ],
                ),
              ],
              if (sessionStorageFailure != null) ...[
                const SizedBox(height: 12),
                Text(
                  english
                      ? 'Secure session storage is unavailable on this device.'
                      : 'Không thể truy cập bộ nhớ phiên đăng nhập an toàn trên thiết bị này.',
                  style: VnlfTypography.meta(colors.red),
                ),
              ],
            ],
          ),
        ),
        if (session != null && !offlineFeatures) ...[
          const SizedBox(height: 16),
          const SecuritySessionsPanel(),
        ],
        if (ref.watch(sessionStateProvider) != null && !offlineFeatures) ...[
          const SizedBox(height: 16),
          const BlockedPeoplePanel(),
          const SizedBox(height: 16),
          const FeatureSurface(child: PreferencesPanel()),
        ],
        const SizedBox(height: 16),
        FeatureSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                english ? 'Appearance' : 'Giao diện',
                style: VnlfTypography.h2(colors.ink),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final mode in ThemeMode.values)
                    ChoiceChip(
                      selectedColor: colors.brandSoft,
                      checkmarkColor: colors.brand,
                      side: BorderSide(color: colors.line),
                      labelStyle: VnlfTypography.control(colors.ink),
                      label: Text(switch (mode) {
                        ThemeMode.light => english ? 'Light' : 'Sáng',
                        ThemeMode.dark => english ? 'Dark' : 'Tối',
                        ThemeMode.system => english ? 'System' : 'Tự động',
                      }),
                      selected: theme == mode,
                      onSelected: (_) => ref
                          .read(themeModeProvider.notifier)
                          .setThemeMode(mode),
                    ),
                ],
              ),
              if (themeStorageFailure != null) ...[
                const SizedBox(height: 8),
                Text(
                  english
                      ? 'Could not save appearance. Please select it again to retry.'
                      : 'Không thể lưu giao diện. Vui lòng chọn lại để thử lại.',
                  style: VnlfTypography.meta(colors.red),
                ),
              ],
              const SizedBox(height: 24),
              Text(
                english ? 'Language' : 'Ngôn ngữ',
                style: VnlfTypography.h2(colors.ink),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final item in const {
                    'vi': 'Tiếng Việt',
                    'en': 'English',
                  }.entries)
                    ChoiceChip(
                      selectedColor: colors.brandSoft,
                      checkmarkColor: colors.brand,
                      side: BorderSide(color: colors.line),
                      labelStyle: VnlfTypography.control(colors.ink),
                      label: Text(item.value),
                      selected: language == item.key,
                      onSelected: (_) => ref
                          .read(localeProvider.notifier)
                          .setLocale(Locale(item.key)),
                    ),
                ],
              ),
              if (localeStorageFailure != null) ...[
                const SizedBox(height: 8),
                Text(
                  english
                      ? 'Could not save language. Please select it again to retry.'
                      : 'Không thể lưu ngôn ngữ. Vui lòng chọn lại để thử lại.',
                  style: VnlfTypography.meta(colors.red),
                ),
              ],
              const SizedBox(height: 24),
              const TextSizeSettings(),
              const SizedBox(height: 24),
              if (isDevBuild) ...[
                const SizedBox(height: 24),
                Text(
                  english ? 'Server mode (Dev)' : 'Chế độ máy chủ (Thử nghiệm)',
                  style: VnlfTypography.h2(colors.ink),
                ),
                const SizedBox(height: 8),
                Text(
                  offlineFeatures
                      ? 'Offline fixture'
                      : (english
                            ? 'Server: ${ref.watch(apiBaseUrlProvider)}'
                            : 'Máy chủ: ${ref.watch(apiBaseUrlProvider)}'),
                  style: VnlfTypography.meta(colors.muted),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      selectedColor: colors.brandSoft,
                      checkmarkColor: colors.brand,
                      side: BorderSide(color: colors.line),
                      labelStyle: VnlfTypography.control(colors.ink),
                      label: const Text('Production'),
                      selected:
                          ref.watch(apiBaseUrlProvider) ==
                          'https://vietnamlinuxfamily.net',
                      onSelected: (_) {
                        ref.read(apiClientProvider).clearCache();
                        ref
                            .read(apiBaseUrlProvider.notifier)
                            .setBaseUrl('https://vietnamlinuxfamily.net');
                      },
                    ),
                    ChoiceChip(
                      selectedColor: colors.brandSoft,
                      checkmarkColor: colors.brand,
                      side: BorderSide(color: colors.line),
                      labelStyle: VnlfTypography.control(colors.ink),
                      label: const Text('Dev (127.0.0.1:3001)'),
                      selected:
                          ref.watch(apiBaseUrlProvider) ==
                          'http://127.0.0.1:3001',
                      onSelected: (_) {
                        ref.read(apiClientProvider).clearCache();
                        ref
                            .read(apiBaseUrlProvider.notifier)
                            .setBaseUrl('http://127.0.0.1:3001');
                      },
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Text(
                english
                    ? 'Appearance is saved on this device. Language applies for this app session.'
                    : 'Giao diện được lưu trên thiết bị. Ngôn ngữ áp dụng trong phiên ứng dụng này.',
                style: VnlfTypography.meta(colors.muted),
              ),
              if (DesktopTrayService.isDesktop) ...[
                const SizedBox(height: 16),
                Text(
                  english
                      ? 'Desktop & System Tray'
                      : 'Máy tính & Khay hệ thống',
                  style: VnlfTypography.h2(colors.ink),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: colors.brand,
                  title: Text(
                    english
                        ? 'Minimize to system tray on close'
                        : 'Thu nhỏ vào khay hệ thống khi đóng',
                    style: VnlfTypography.body(colors.ink),
                  ),
                  subtitle: Text(
                    english
                        ? 'Keep running in the background to receive instant notifications'
                        : 'Tiếp tục chạy ngầm để nhận thông báo tức thì',
                    style: VnlfTypography.meta(colors.muted),
                  ),
                  value: ref.watch(desktopMinimizeToTrayProvider),
                  onChanged: (val) => ref
                      .read(desktopMinimizeToTrayProvider.notifier)
                      .toggle(val),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: colors.brand,
                  title: Text(
                    english ? 'Start with system' : 'Khởi động cùng hệ thống',
                    style: VnlfTypography.body(colors.ink),
                  ),
                  subtitle: Text(
                    english
                        ? 'Automatically launch minimized when starting your computer'
                        : 'Tự động mở thu nhỏ khi khởi động máy tính',
                    style: VnlfTypography.meta(colors.muted),
                  ),
                  value: ref.watch(desktopAutostartProvider),
                  onChanged: (val) => ref
                      .read(desktopAutostartProvider.notifier)
                      .setAutostart(val),
                ),
              ],
              if (AndroidBackgroundService.isAndroid ||
                  (!offlineFeatures && session != null)) ...[
                const SizedBox(height: 16),
                Text(
                  english ? 'Notifications' : 'Thông báo',
                  style: VnlfTypography.h2(colors.ink),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: colors.brand,
                  title: Text(
                    english ? 'Push notifications' : 'Thông báo đẩy',
                    style: VnlfTypography.body(colors.ink),
                  ),
                  subtitle: Text(
                    english
                        ? 'Receive instant direct messages, mentions, and updates'
                        : 'Nhận tin nhắn, phản hồi và cập nhật quan trọng tức thì',
                    style: VnlfTypography.meta(colors.muted),
                  ),
                  value: ref.watch(androidBackgroundSyncProvider),
                  onChanged: (val) {
                    ref
                        .read(androidBackgroundSyncProvider.notifier)
                        .toggle(val);
                    if (val) {
                      ref
                          .read(pushRegistrationControllerProvider.notifier)
                          .registerDevice(force: true);
                    } else {
                      ref
                          .read(pushRegistrationControllerProvider.notifier)
                          .unregisterDevice();
                    }
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

Future<void> logoutWithFeedback(BuildContext context, WidgetRef ref) async {
  if (!context.mounted) return;
  final english = Localizations.localeOf(context).languageCode == 'en';
  try {
    await ref.read(authControllerProvider.notifier).logout();
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error is StorageFailure
              ? (english
                    ? 'Signed out here, but stored session cleanup failed. Please try again before closing the app.'
                    : 'Đã đăng xuất tại đây nhưng không thể xóa phiên đã lưu. Vui lòng thử lại trước khi đóng ứng dụng.')
              : (english
                    ? 'Signed out on this device. Could not confirm logout with the server.'
                    : 'Đã đăng xuất trên thiết bị. Không thể xác nhận đăng xuất với máy chủ.'),
        ),
        action: error is StorageFailure
            ? SnackBarAction(
                label: english ? 'Retry' : 'Thử lại',
                onPressed: () => logoutWithFeedback(context, ref),
              )
            : null,
      ),
    );
  }
}
