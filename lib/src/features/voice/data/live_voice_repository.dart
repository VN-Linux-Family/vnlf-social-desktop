import '../../../core/api_client.dart';
import '../domain/voice_models.dart';
import '../domain/voice_repository.dart';
import 'voice_dto.dart';

final class LiveVoiceRepository implements VoiceRepository {
  const LiveVoiceRepository(this._client, {this.baseUri});
  final ApiClient _client;
  final Uri? baseUri;

  @override
  Future<List<VoiceRoom>> getRooms() => _client.get(
    '/api/v1/voice/rooms',
    decode: (json) {
      final items = json['items'];
      if (items is! List) throw const ParseFailure('voice.items');
      try {
        final rooms = items.map((item) {
          if (item is! Map<String, dynamic>) {
            throw const ParseFailure('voice.room');
          }
          return VoiceRoomDto(item).toDomain();
        }).toList()..sort((a, b) => a.position.compareTo(b.position));
        return List.unmodifiable(rooms);
      } on TypeError {
        throw const ParseFailure('voice.room');
      }
    },
  );

  @override
  Future<VoiceConnection> join(String roomId) => _client.request(
    'POST',
    '/api/v1/voice/rooms/${Uri.encodeComponent(roomId)}/join-token',
    decode: (json) {
      try {
        return VoiceConnectionDto(json, baseUri: baseUri).toDomain();
      } on TypeError {
        throw const ParseFailure('voice.connection');
      }
    },
  );

  @override
  Future<void> leave(String roomId) => _client.request<void>(
    'POST',
    '/api/v1/voice/rooms/${Uri.encodeComponent(roomId)}/leave',
    decode: (_) {},
  );
}
