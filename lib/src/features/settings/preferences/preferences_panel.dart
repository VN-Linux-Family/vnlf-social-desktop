import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'preferences.dart';
import 'preferences_controller.dart';

/// The parent settings screen decides where this account-bound panel appears.
final class PreferencesPanel extends ConsumerWidget {
  const PreferencesPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final english = Localizations.localeOf(context).languageCode == 'en';
    final state = ref.watch(preferencesControllerProvider);
    final controller = ref.read(preferencesControllerProvider.notifier);
    final draft = state.draft;
    if (draft == null) {
      if (state.loadFailed) {
        return Column(
          children: [
            Text(
              english ? 'Could not load settings.' : 'Không thể tải cài đặt.',
            ),
            TextButton(
              onPressed: controller.refresh,
              child: Text(english ? 'Retry' : 'Thử lại'),
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
        Text(
          english ? 'Privacy' : 'Riêng tư',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        toggle(
          english
              ? 'Everyone can send private messages'
              : 'Mọi người có thể gửi tin nhắn riêng',
          draft.dmPolicy == DmPolicy.everyone,
          (value) => draft.copyWith(
            dmPolicy: value ? DmPolicy.everyone : DmPolicy.following,
          ),
        ),
        toggle(
          english ? 'Show on leaderboard' : 'Hiển thị trên bảng xếp hạng',
          draft.leaderboardVisible,
          (value) => draft.copyWith(leaderboardVisible: value),
        ),
        toggle(
          english ? 'Show online status' : 'Hiển thị trạng thái trực tuyến',
          draft.onlineVisible,
          (value) => draft.copyWith(onlineVisible: value),
        ),
        Text(
          english ? 'Notifications' : 'Thông báo',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        toggle(
          english ? 'Likes' : 'Lượt thích',
          draft.likeNotifications,
          (value) => draft.copyWith(likeNotifications: value),
        ),
        toggle(
          english ? 'New followers' : 'Theo dõi mới',
          draft.followNotifications,
          (value) => draft.copyWith(followNotifications: value),
        ),
        toggle(
          english
              ? 'Comments, replies and messages'
              : 'Bình luận, trả lời và tin nhắn',
          draft.messageNotifications,
          (value) => draft.copyWith(messageNotifications: value),
        ),
        toggle(
          english
              ? 'Message sound on the website'
              : 'Âm báo tin nhắn trên trang web',
          draft.messageSoundEnabled,
          (value) => draft.copyWith(messageSoundEnabled: value),
        ),
        Text(
          english ? 'Display' : 'Hiển thị',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        toggle(
          english ? 'Reduce motion' : 'Giảm chuyển động',
          draft.reduceMotion,
          (value) => draft.copyWith(reduceMotion: value),
        ),
        if (state.uncertain) ...[
          Text(
            english ? 'The save could not be confirmed. Refresh to check.' : 'Chưa xác định được cài đặt đã lưu hay chưa. Hãy tải lại để kiểm tra.',
          ),
          TextButton(
            onPressed: state.busy ? null : controller.refresh,
            child: Text(english ? 'Refresh' : 'Tải lại'),
          ),
        ],
        if (state.loadFailed && state.uncertain)
          Text(
            english
                ? 'Could not refresh settings.'
                : 'Không thể tải lại cài đặt.',
          ),
        if (state.savedNotice)
          Text(english ? 'Settings saved.' : 'Đã lưu cài đặt.'),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            onPressed: enabled && state.dirty ? controller.save : null,
            child: Text(
              state.busy
                  ? (english ? 'Working…' : 'Đang xử lý…')
                  : (english ? 'Save' : 'Lưu'),
            ),
          ),
        ),
      ],
    );
  }
}
