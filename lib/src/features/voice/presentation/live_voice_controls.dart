import 'package:flutter/material.dart';

import '../../../design_system/design_system.dart';
import '../../shared/presentation/feature_widgets.dart';
import '../domain/voice_models.dart';
import 'voice_session_controller.dart';

class LiveVoiceControls extends StatelessWidget {
  const LiveVoiceControls({
    super.key,
    required this.state,
    required this.room,
    required this.onJoin,
    required this.onLeave,
    required this.onMicrophone,
    required this.onDeafen,
  });
  final VoiceSessionState state;
  final VoiceRoom? room;
  final VoidCallback onJoin, onLeave, onMicrophone, onDeafen;

  @override
  Widget build(BuildContext context) {
    final english = Localizations.localeOf(context).languageCode == 'en';
    final colors = VnlfColors.of(context);
    final active = state.roomId != null;
    final selectedActive = state.roomId == room?.id && active;
    final status = switch (state.phase) {
      VoicePhase.connecting => english ? 'Connecting…' : 'Đang kết nối…',
      VoicePhase.reconnecting =>
        english ? 'Reconnecting…' : 'Đang kết nối lại…',
      VoicePhase.connected =>
        state.deafened
            ? (english
                  ? 'Sound off · Microphone muted'
                  : 'Đã tắt âm thanh và mic')
            : state.muted
            ? (english
                  ? 'Connected · Microphone muted'
                  : 'Đã kết nối · Mic đang tắt')
            : (english
                  ? 'Connected · Microphone live'
                  : 'Đã kết nối · Mic đang bật'),
      _ => '',
    };
    return FeatureSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (state.failure case final failure?) ...[
            Semantics(
              liveRegion: true,
              child: Text(
                voiceFailureMessage(failure, english),
                style: VnlfTypography.meta(colors.red),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (status.isNotEmpty) ...[
            Semantics(
              liveRegion: true,
              child: Text(
                status,
                style: VnlfTypography.meta(colors.muted),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
          ],
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: selectedActive ? colors.red : colors.brand,
                  foregroundColor: selectedActive
                      ? Theme.of(context).colorScheme.onError
                      : Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                ),
                onPressed: selectedActive
                    ? onLeave
                    : room != null && room!.canJoin && !state.busy
                    ? onJoin
                    : null,
                icon: Icon(selectedActive ? Icons.call_end : Icons.headphones),
                label: Text(
                  selectedActive
                      ? (state.phase == VoicePhase.connecting
                            ? (english ? 'Cancel connection' : 'Hủy kết nối')
                            : (english ? 'Leave room' : 'Rời phòng'))
                      : (english ? 'Join room' : 'Tham gia phòng'),
                ),
              ),
              if (active && !selectedActive)
                OutlinedButton.icon(
                  onPressed: onLeave,
                  icon: const Icon(Icons.call_end),
                  label: Text(
                    english ? 'Leave current room' : 'Rời phòng hiện tại',
                  ),
                ),
              IconButton.filledTonal(
                tooltip: state.muted
                    ? (english ? 'Unmute microphone' : 'Bật mic')
                    : (english ? 'Mute microphone' : 'Tắt mic'),
                isSelected: !state.muted,
                icon: Icon(state.muted ? Icons.mic_off : Icons.mic),
                onPressed: state.connected && !state.busy && !state.deafened
                    ? onMicrophone
                    : null,
              ),
              IconButton.filledTonal(
                tooltip: state.deafened
                    ? (english ? 'Enable sound' : 'Bật âm thanh')
                    : (english ? 'Deafen' : 'Tắt âm thanh'),
                isSelected: state.deafened,
                icon: Icon(
                  state.deafened ? Icons.headset_off : Icons.headphones,
                ),
                onPressed: state.connected && !state.busy ? onDeafen : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String voiceFailureMessage(VoiceFailure failure, bool english) =>
    switch (failure) {
      VoicePermissionFailure() =>
        english
            ? 'Microphone permission was denied. Allow microphone access in system settings.'
            : 'Chưa được cấp quyền mic. Hãy cho phép sử dụng mic trong cài đặt hệ thống.',
      VoiceAccessFailure() =>
        english
            ? 'Your session cannot join this room. Sign in again or choose another room.'
            : 'Phiên đăng nhập không có quyền vào phòng. Hãy đăng nhập lại hoặc chọn phòng khác.',
      VoiceAudioFailure() =>
        english
            ? 'Audio failed. Check your audio device and reconnect.'
            : 'Âm thanh gặp lỗi. Kiểm tra thiết bị âm thanh rồi kết nối lại.',
      VoiceUnavailableFailure() =>
        english ? 'This room is unavailable.' : 'Phòng hiện không khả dụng.',
      VoiceConnectionFailure() =>
        english
            ? 'Could not connect or complete room cleanup. Check your network and try again.'
            : 'Không thể kết nối hoặc hoàn tất rời phòng. Kiểm tra mạng rồi thử lại.',
    };
