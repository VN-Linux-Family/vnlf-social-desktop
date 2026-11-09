import 'package:flutter/material.dart';

import '../../../design_system/design_system.dart';
import '../../../i18n/vi.dart';
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
    final colors = VnlfColors.of(context);
    final active = state.roomId != null;
    final selectedActive = state.roomId == room?.id && active;
    final status = switch (state.phase) {
      VoicePhase.connecting => vi.voiceView.dangKetNoi,
      VoicePhase.reconnecting => vi.voiceView.dangKetNoiLai,
      VoicePhase.connected =>
        state.deafened
            ? vi.app.voice.daTatAmThanh
            : state.muted
            ? vi.app.voice.daKetNoiMicDang
            : vi.app.voice.daKetNoiMic,
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
                voiceFailureMessage(failure),
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
                            ? vi.app.voice.huyKetNoi
                            : vi.app.voice.roiPhong)
                      : vi.app.voice.thamGiaPhong,
                ),
              ),
              if (active && !selectedActive)
                OutlinedButton.icon(
                  onPressed: onLeave,
                  icon: const Icon(Icons.call_end),
                  label: Text(vi.app.voice.roiPhongHienTai),
                ),
              IconButton.filledTonal(
                tooltip: state.muted
                    ? vi.voiceView.batMic
                    : vi.voiceView.tatMic,
                isSelected: !state.muted,
                icon: Icon(state.muted ? Icons.mic_off : Icons.mic),
                onPressed: state.connected && !state.busy && !state.deafened
                    ? onMicrophone
                    : null,
              ),
              IconButton.filledTonal(
                tooltip: state.deafened
                    ? vi.voiceView.batAmThanh
                    : vi.app.common.tatAmThanh,
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

String voiceFailureMessage(VoiceFailure failure) => switch (failure) {
  VoicePermissionFailure() => vi.app.voice.chuaDuocCapQuyen,
  VoiceAccessFailure() => vi.app.voice.phienDangNhapKhong,
  VoiceAudioFailure() => vi.app.voice.amThanhGapLoi,
  VoiceUnavailableFailure() => vi.app.voice.phongHienKhongKha,
  VoiceConnectionFailure() => vi.app.voice.khongTheKetNoi,
};
