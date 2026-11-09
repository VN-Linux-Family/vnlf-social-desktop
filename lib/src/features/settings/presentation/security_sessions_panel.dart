import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/design_system.dart';
import '../../../i18n/vi.dart';
import '../../shared/presentation/feature_widgets.dart';
import '../domain/security_sessions.dart';
import 'security_sessions_controller.dart';

class SecuritySessionsPanel extends ConsumerWidget {
  const SecuritySessionsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = VnlfColors.of(context);
    final state = ref.watch(securitySessionsControllerProvider);
    final controller = ref.read(securitySessionsControllerProvider.notifier);
    return FeatureSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            vi.settingsViews.phienDangNhap,
            style: VnlfTypography.h2(colors.ink),
          ),
          const SizedBox(height: 8),
          Text(
            vi.app.settings.thietBiDangDang,
            style: VnlfTypography.meta(colors.muted),
          ),
          if (state.loading) const LinearProgressIndicator(),
          if (state.failed || (state.uncertain && !state.loading)) ...[
            const SizedBox(height: 8),
            Text(
              state.confirmed
                  ? vi.app.settings.daXacNhanDang
                  : state.uncertain
                  ? vi.app.settings.chuaTheXacNhan
                  : vi.settingsViews.chuaTaiDuocDanhSach,
              style: VnlfTypography.meta(colors.red),
            ),
          ],
          for (final session in state.items ?? <SecuritySession>[])
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                session.current ? Icons.computer : Icons.devices_other,
              ),
              title: Text(
                (session.deviceName?.isNotEmpty ?? false)
                    ? session.deviceName!
                    : ((session.userAgent?.isNotEmpty ?? false)
                          ? session.userAgent!
                          : vi.settingsViews.thietBiKhongXacDinh),
              ),
              subtitle: Text(
                session.lastSeenAt == null
                    ? vi.app.settings.khongRoLanHoat
                    : '${vi.app.common.hoatDong}: ${MaterialLocalizations.of(context).formatMediumDate(session.lastSeenAt!.toLocal())} ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(session.lastSeenAt!.toLocal()))}',
              ),
              trailing: session.current
                  ? Text(vi.app.settings.hienTai)
                  : TextButton(
                      onPressed: state.loading || state.uncertain
                          ? null
                          : () => _confirm(
                              context,
                              () => controller.revoke(session),
                              false,
                            ),
                      child: Text(vi.settingsViews.dangXuat),
                    ),
            ),
          if (state.items?.any((s) => !s.current) ?? false)
            OutlinedButton(
              onPressed: state.loading || state.uncertain
                  ? null
                  : () =>
                        _confirm(context, () => controller.revoke(null), true),
              child: Text(vi.app.settings.dangXuatCacPhienKhac),
            ),
          TextButton(
            onPressed: state.loading ? null : controller.refresh,
            child: Text(vi.app.common.lamMoi),
          ),
        ],
      ),
    );
  }

  Future<void> _confirm(
    BuildContext context,
    Future<void> Function() action,
    bool all,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          all
              ? vi.app.settings.dangXuatCacPhien
              : vi.app.settings.dangXuatThietBi,
        ),
        content: Text(vi.app.settings.banSeCanDang),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(vi.common.huy),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(vi.settingsViews.dangXuat),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) await action();
  }
}
