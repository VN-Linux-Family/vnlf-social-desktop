import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../design_system/design_system.dart';
import '../../../i18n/vi.dart';
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
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(vi.app.updates.khongMoDuocTrang)));
  }
}

class AppUpdatePanel extends ConsumerWidget {
  const AppUpdatePanel({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = VnlfColors.of(context);
    final state = ref.watch(updateControllerProvider);
    final update = state.valueOrNull;
    final text = state.isLoading
        ? vi.app.updates.dangKiemTraCap
        : state.hasError
        ? vi.app.updates.khongKiemTraDuoc
        : switch (update) {
            UpdateAvailable(:final version) => format(
              vi.app.updates.daCoPhienBan,
              {'version': version},
            ),
            UpdateCurrent() => vi.app.updates.banDangDungPhien,
            UpdateUnavailable() => vi.app.updates.chuaCoBanPhat,
            _ => vi.app.updates.kiemTraPhienBan,
          };
    return FeatureSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            vi.app.updates.capNhatUngDung,
            style: VnlfTypography.h2(colors.ink),
          ),
          const SizedBox(height: 8),
          Text(
            '${vi.app.updates.phienBanDangDung}: $installedAppVersion',
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
              vi.app.updates.banPhatHanhChua,
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
                label: Text(vi.app.updates.kiemTraCapNhat),
              ),
              if (update is UpdateAvailable)
                FilledButton.icon(
                  onPressed: () => openUpdate(context, update),
                  icon: const Icon(Icons.download_outlined),
                  label: Text(
                    update.asset == null
                        ? vi.app.updates.xemBanPhatHanh
                        : vi.app.updates.taiBanCapNhat,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
