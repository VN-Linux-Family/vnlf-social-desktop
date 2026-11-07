import 'voice_models.dart';

/// Owns all audio tracks and native resources for exactly one connection.
abstract interface class VoiceRoomSession {
  Stream<VoiceRoomSnapshot> get changes;
  VoiceRoomSnapshot get snapshot;
  Future<void> connect(VoiceConnection connection);
  Future<void> setMicrophoneEnabled(bool enabled);
  Future<void> setPlaybackEnabled(bool enabled);

  /// Cancels in-flight connection work and releases tracks, even on failure.
  Future<void> close();
}

typedef VoiceRoomSessionFactory = VoiceRoomSession Function();
