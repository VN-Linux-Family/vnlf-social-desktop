import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
        return Column(children: [
          const Text('Không thể tải cài đặt.'),
          TextButton(onPressed: controller.refresh, child: const Text('Thử lại')),
        ]);
      }
      return const Center(child: CircularProgressIndicator());
    }
    final enabled = !state.busy && !state.uncertain;
    Widget toggle(String title, bool value, WebsitePreferences Function(bool) update) => SwitchListTile(
      title: Text(title),
      value: value,
      onChanged: enabled ? (value) => controller.edit(update(value)) : null,
    );
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('Riêng tư', style: Theme.of(context).textTheme.titleMedium),
      toggle('Mọi người có thể gửi tin nhắn riêng', draft.dmPolicy == DmPolicy.everyone, (value) => draft.copyWith(dmPolicy: value ? DmPolicy.everyone : DmPolicy.following)),
      toggle('Hiển thị trên bảng xếp hạng', draft.leaderboardVisible, (value) => draft.copyWith(leaderboardVisible: value)),
      toggle('Hiển thị trạng thái trực tuyến', draft.onlineVisible, (value) => draft.copyWith(onlineVisible: value)),
      Text('Thông báo', style: Theme.of(context).textTheme.titleMedium),
      toggle('Lượt thích', draft.likeNotifications, (value) => draft.copyWith(likeNotifications: value)),
      toggle('Theo dõi mới', draft.followNotifications, (value) => draft.copyWith(followNotifications: value)),
      toggle('Bình luận, trả lời và tin nhắn', draft.messageNotifications, (value) => draft.copyWith(messageNotifications: value)),
      toggle('Âm báo tin nhắn', draft.messageSoundEnabled, (value) => draft.copyWith(messageSoundEnabled: value)),
      Text('Hiển thị', style: Theme.of(context).textTheme.titleMedium),
      toggle('Giảm chuyển động', draft.reduceMotion, (value) => draft.copyWith(reduceMotion: value)),
      if (state.uncertain) ...[
        const Text('Chưa xác định được cài đặt đã lưu hay chưa. Hãy tải lại để kiểm tra.'),
        TextButton(onPressed: state.busy ? null : controller.refresh, child: const Text('Tải lại')),
      ],
      if (state.loadFailed && state.uncertain) const Text('Không thể tải lại cài đặt.'),
      if (state.savedNotice) const Text('Đã lưu cài đặt.'),
      Align(alignment: Alignment.centerRight, child: FilledButton(onPressed: enabled && state.dirty ? controller.save : null, child: Text(state.busy ? 'Đang xử lý' : 'Lưu'))),
    ]);
  }
}
