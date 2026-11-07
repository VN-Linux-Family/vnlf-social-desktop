import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../data/live_voice_repository.dart';
import '../data/livekit_voice_session.dart';
import '../domain/voice_models.dart';
import '../domain/voice_repository.dart';
import '../domain/voice_room_session.dart';
import 'voice_session_controller.dart';

final voiceAccountIdProvider = Provider<String?>(
  (ref) =>
      (ref.watch(sessionStateProvider) ??
              ref.watch(sessionProvider).valueOrNull)
          ?.userId,
);

final voiceRepositoryProvider = Provider<VoiceRepository>(
  (ref) => LiveVoiceRepository(ref.watch(apiClientProvider)),
);

final voiceRoomSessionFactoryProvider = Provider<VoiceRoomSessionFactory>(
  (ref) =>
      () => LiveKitVoiceSession(),
);

final voiceRoomsProvider = FutureProvider.autoDispose<List<VoiceRoom>>((ref) {
  if (ref.watch(voiceAccountIdProvider) == null) return const [];
  return ref.watch(voiceRepositoryProvider).getRooms();
});

final voiceSessionProvider =
    StateNotifierProvider.autoDispose<
      VoiceSessionController,
      VoiceSessionState
    >((ref) {
      final controller = VoiceSessionController(
        ref.watch(voiceRepositoryProvider),
        ref.watch(voiceRoomSessionFactoryProvider),
        initialAccount: ref.read(voiceAccountIdProvider),
      );
      ref.listen(voiceAccountIdProvider, (_, next) {
        unawaited(controller.setAccount(next));
      });
      return controller;
    });
