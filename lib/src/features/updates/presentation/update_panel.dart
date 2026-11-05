import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../design_system/design_system.dart';
import '../../shared/presentation/feature_widgets.dart';
import '../domain/app_update.dart';
import 'update_providers.dart';

Future<void> openUpdate(BuildContext context, UpdateAvailable update) async {
  var opened = false;
  try {
    opened = await launchUrl(
      update.asset?.url ?? update.releasePage,
      mode: LaunchMode.externalApplication,
    );
  } catch (_) {
    opened = false;
  }
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          Localizations.localeOf(context).languageCode == 'en'
              ? 'Could not open the release download.'
              : 'Không mở được trang tải bản cập nhật.',
        ),
      ),
    );
  }
}

class AppUpdatePanel extends ConsumerWidget {
  const AppUpdatePanel({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final english = Localizations.localeOf(context).languageCode == 'en';
    final colors = VnlfColors.of(context);
    final state = ref.watch(updateControllerProvider);
    final update = state.valueOrNull;
    final text = state.isLoading
        ? (english ? 'Checking for updates…' : 'Đang kiểm tra cập nhật…')
        : state.hasError
        ? (english
              ? 'Update check failed. Check your connection and try again.'
              : 'Không kiểm tra được bản cập nhật. Kiểm tra kết nối rồi thử lại.')
        : switch (update) {
            UpdateAvailable(:final version) =>
              (english
                  ? 'Version $version is available.'
                  : 'Đã có phiên bản $version.'),
            UpdateCurrent() =>
              (english
                  ? 'You are using the latest stable version.'
                  : 'Bạn đang dùng phiên bản ổn định mới nhất.'),
            UpdateUnavailable() =>
              (english
                  ? 'No public release is available yet.'
                  : 'Chưa có bản phát hành công khai để kiểm tra.'),
            _ =>
              (english
                  ? 'Check for a new stable version.'
                  : 'Kiểm tra phiên bản ổn định mới.'),
          };
    return FeatureSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            english ? 'App updates' : 'Cập nhật ứng dụng',
            style: VnlfTypography.h2(colors.ink),
          ),
          const SizedBox(height: 8),
          Text(
            '${english ? 'Installed version' : 'Phiên bản đang dùng'}: $installedAppVersion',
            style: VnlfTypography.meta(colors.muted),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: VnlfTypography.body(
              state.hasError ? colors.red : colors.ink,
            ),
          ),
          if (update is UpdateAvailable && update.asset == null)
            Text(
              english
                  ? 'There is no download for this platform in this release.'
                  : 'Bản phát hành chưa có tệp cho nền tảng này.',
              style: VnlfTypography.meta(colors.muted),
            ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: state.isLoading
                    ? null
                    : () => ref.read(updateControllerProvider.notifier).check(),
                icon: const Icon(Icons.refresh),
                label: Text(
                  english ? 'Check for updates' : 'Kiểm tra cập nhật',
                ),
              ),
              if (update is UpdateAvailable)
                FilledButton.icon(
                  onPressed: () => openUpdate(context, update),
                  icon: const Icon(Icons.download_outlined),
                  label: Text(
                    update.asset == null
                        ? (english ? 'View release' : 'Xem bản phát hành')
                        : (english ? 'Download update' : 'Tải bản cập nhật'),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
