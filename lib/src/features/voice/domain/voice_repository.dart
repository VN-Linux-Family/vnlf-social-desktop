import 'voice_models.dart';

abstract interface class VoiceRepository {
  Future<List<VoiceRoom>> getRooms();
  Future<VoiceConnection> join(String roomId);
  Future<void> leave(String roomId);
}
