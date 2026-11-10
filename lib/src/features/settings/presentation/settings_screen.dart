import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vnlfsocialapp/src/i18n/vi.dart';

import '../../../app/providers.dart';
import '../../../core/android_background_service.dart';
import '../../../core/desktop_tray_service.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/models.dart';
import '../../notifications/data/local_notification_service.dart';
import '../../notifications/presentation/push_settings_card.dart';
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
    final mobile =
        VnlfViewportSize.fromWidth(MediaQuery.sizeOf(context).width) ==
        VnlfViewportSize.mobile;
    final colors = VnlfColors.of(context);
    final theme = ref.watch(themeModeProvider);
    final themeStorageFailure = ref.watch(themeStorageFailureProvider);
    final sessionStorageFailure = ref.watch(sessionStorageFailureProvider);
    final signingOut = ref.watch(authControllerProvider).isLoading;
    final session =
        ref.watch(sessionProvider).valueOrNull ??
        ref.watch(sessionStateProvider);
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        if (!mobile) ...[
          FeatureHeader(title: vi.common.caiDat, showSettings: false),
          const SizedBox(height: 12),
        ],
        const AppUpdatePanel(),
        const SizedBox(height: 12),
        FeatureSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                vi.settingsViews.taiKhoan,
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
                    label: Text(vi.common.chinhSuaHoSo),
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
                  label: Text(vi.settingsViews.dangXuat),
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
                            vi.app.settings.khach,
                            style: VnlfTypography.control(
                              colors.ink,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            vi.app.settings.chuaDangNhapTai,
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
                      child: Text(vi.common.dangNhap),
                    ),
                  ],
                ),
              ],
              if (sessionStorageFailure != null) ...[
                const SizedBox(height: 12),
                Text(
                  vi.app.settings.khongTheTruyCapBo,
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
          const SizedBox(height: 12),
          const PushSettingsCard(),
        ],
        const SizedBox(height: 16),
        FeatureSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                vi.settingsViews.giaoDien,
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
                        ThemeMode.light => vi.app.common.sang,
                        ThemeMode.dark => vi.app.common.toi,
                        ThemeMode.system => vi.settingsViews.tuDong,
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
                  vi.app.settings.khongTheLuuGiao,
                  style: VnlfTypography.meta(colors.red),
                ),
              ],
              const SizedBox(height: 24),
              const TextSizeSettings(),
              const SizedBox(height: 24),
              if (isDevBuild) ...[
                const SizedBox(height: 24),
                Text(
                  vi.app.settings.cheDoMayChu,
                  style: VnlfTypography.h2(colors.ink),
                ),
                const SizedBox(height: 8),
                Text(
                  offlineFeatures
                      ? 'Offline fixture'
                      : format(vi.app.settings.mayChu, {
                          'apiBaseUrlProvider': ref.watch(apiBaseUrlProvider),
                        }),
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
                vi.app.settings.giaoDienDuocLuu,
                style: VnlfTypography.meta(colors.muted),
              ),
              if (DesktopTrayService.isDesktop) ...[
                const SizedBox(height: 16),
                Text(
                  vi.app.settings.mayTinhKhayHe,
                  style: VnlfTypography.h2(colors.ink),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: colors.brand,
                  title: Text(
                    vi.app.settings.thuNhoVaoKhay,
                    style: VnlfTypography.body(colors.ink),
                  ),
                  subtitle: Text(
                    vi.app.settings.tiepTucChayNgam,
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
                    vi.app.settings.khoiDongCungHe,
                    style: VnlfTypography.body(colors.ink),
                  ),
                  subtitle: Text(
                    vi.app.settings.tuDongMoThu,
                    style: VnlfTypography.meta(colors.muted),
                  ),
                  value: ref.watch(desktopAutostartProvider),
                  onChanged: (val) => ref
                      .read(desktopAutostartProvider.notifier)
                      .setAutostart(val),
                ),
              ],
              if (ref.watch(androidPlatformProvider)) ...[
                const SizedBox(height: 16),
                Text(vi.common.thongBao, style: VnlfTypography.h2(colors.ink)),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: colors.brand,
                  title: Text(
                    vi.app.thongBaoKhiChayNen,
                    style: VnlfTypography.body(colors.ink),
                  ),
                  subtitle: Text(
                    vi.app.giuKetNoiKhiChayNen,
                    style: VnlfTypography.meta(colors.muted),
                  ),
                  value: ref.watch(androidBackgroundSyncProvider),
                  onChanged: (enabled) =>
                      _setBackgroundNotifications(context, ref, enabled),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Turning background notifications on first asks Android 13+ for the
/// notification permission; without it nothing would ever be shown.
Future<void> _setBackgroundNotifications(
  BuildContext context,
  WidgetRef ref,
  bool enabled,
) async {
  final preference = ref.read(androidBackgroundSyncProvider.notifier);
  final notifications = ref.read(localNotificationServiceProvider);
  if (enabled && !await notifications.requestPermission()) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(vi.app.chuaDuocPhepGuiThongBao)));
    return;
  }
  await preference.toggle(enabled);
}

Future<void> logoutWithFeedback(BuildContext context, WidgetRef ref) async {
  if (!context.mounted) return;
  try {
    await ref.read(authControllerProvider.notifier).logout();
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error is StorageFailure
              ? vi.app.settings.daDangXuatTai
              : vi.app.settings.daDangXuatTren,
        ),
        action: error is StorageFailure
            ? SnackBarAction(
                label: vi.common.thuLai,
                onPressed: () => logoutWithFeedback(context, ref),
              )
            : null,
      ),
    );
  }
}
