import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../i18n/vi.dart';
import 'preferences.dart';
import 'preferences_controller.dart';

/// The parent settings screen decides where this account-bound panel appears.
final class PreferencesPanel extends ConsumerWidget {
  const PreferencesPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(preferencesControllerProvider);
    final controller = ref.read(preferencesControllerProvider.notifier);
    final draft = state.draft;
    if (draft == null) {
      if (state.loadFailed) {
        return Column(
          children: [
            Text(vi.app.settings.khongTheTaiCai),
            TextButton(
              onPressed: controller.refresh,
              child: Text(vi.common.thuLai),
            ),
          ],
        );
      }
      return const Center(child: CircularProgressIndicator());
    }
    final enabled = !state.busy && !state.uncertain;
    Widget toggle(
      String title,
      bool value,
      WebsitePreferences Function(bool) update,
    ) => SwitchListTile(
      title: Text(title),
      value: value,
      onChanged: enabled ? (value) => controller.edit(update(value)) : null,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(vi.common.riengTu, style: Theme.of(context).textTheme.titleMedium),
        toggle(
          vi.app.settings.moiNguoiCoThe,
          draft.dmPolicy == DmPolicy.everyone,
          (value) => draft.copyWith(
            dmPolicy: value ? DmPolicy.everyone : DmPolicy.following,
          ),
        ),
        toggle(
          vi.app.settings.hienThiTrenBang,
          draft.leaderboardVisible,
          (value) => draft.copyWith(leaderboardVisible: value),
        ),
        toggle(
          vi.app.settings.hienThiTrangThai,
          draft.onlineVisible,
          (value) => draft.copyWith(onlineVisible: value),
        ),
        Text(
          vi.common.thongBao,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        toggle(
          vi.settingsViews.luotThich,
          draft.likeNotifications,
          (value) => draft.copyWith(likeNotifications: value),
        ),
        toggle(
          vi.settingsViews.theoDoiMoi,
          draft.followNotifications,
          (value) => draft.copyWith(followNotifications: value),
        ),
        toggle(
          vi.app.settings.binhLuanTraLoi,
          draft.messageNotifications,
          (value) => draft.copyWith(messageNotifications: value),
        ),
        toggle(
          vi.app.settings.amBaoTinNhan,
          draft.messageSoundEnabled,
          (value) => draft.copyWith(messageSoundEnabled: value),
        ),
        Text(vi.common.hienThi, style: Theme.of(context).textTheme.titleMedium),
        toggle(
          vi.settingsViews.giamChuyenDong,
          draft.reduceMotion,
          (value) => draft.copyWith(reduceMotion: value),
        ),
        if (state.uncertain) ...[
          Text(vi.app.settings.chuaXacDinhDuoc),
          TextButton(
            onPressed: state.busy ? null : controller.refresh,
            child: Text(vi.app.settings.taiLai),
          ),
        ],
        if (state.loadFailed && state.uncertain)
          Text(vi.app.settings.khongTheTaiLai),
        if (state.savedNotice) Text(vi.app.settings.daLuuCaiDat),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            onPressed: enabled && state.dirty ? controller.save : null,
            child: Text(state.busy ? vi.common.dangXuLy : vi.common.luu),
          ),
        ),
      ],
    );
  }
}
