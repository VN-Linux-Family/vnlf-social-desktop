import '../../../core/api_client.dart';
import '../domain/voice_models.dart';

final class VoiceRoomDto {
  VoiceRoomDto(Map<String, dynamic> json)
    : id = _required(json, 'id'),
      name = _required(json, 'name'),
      slug = json['slug'] as String? ?? '',
      description = json['description'] as String? ?? '',
      status = json['status'] as String? ?? '',
      capacity = (json['capacity'] as num?)?.toInt() ?? 0,
      position = (json['position'] as num?)?.toInt() ?? 0,
      participantCount = (json['participantCount'] as num?)?.toInt() ?? 0,
      viewerInRoom = json['viewerInRoom'] == true;

  final String id, name, slug, description, status;
  final int capacity, position, participantCount;
  final bool viewerInRoom;

  VoiceRoom toDomain() => VoiceRoom(
    id: id,
    name: name,
    slug: slug,
    description: description,
    status: status,
    capacity: capacity,
    position: position,
    participantCount: participantCount < 0 ? 0 : participantCount,
    viewerInRoom: viewerInRoom,
  );
}

final class VoiceConnectionDto {
  VoiceConnectionDto(Map<String, dynamic> json, {Uri? baseUri})
    : serverUrl = _normalizeServerUrl(_required(json, 'serverUrl'), baseUri),
      token = _required(json, 'token'),
      iceServers = _iceServers(json['iceServers']) {
    final uri = Uri.tryParse(serverUrl);
    if (uri == null ||
        uri.host.isEmpty ||
        !['ws', 'wss', 'http', 'https'].contains(uri.scheme)) {
      throw const ParseFailure('voice.serverUrl');
    }
  }
  final String serverUrl, token;
  final List<VoiceIceServer> iceServers;

  static String _normalizeServerUrl(String rawUrl, Uri? baseUri) {
    final uri = Uri.tryParse(rawUrl);
    if (uri == null) return rawUrl;
    if (baseUri != null &&
        (uri.host == 'localhost' || uri.host == '127.0.0.1') &&
        baseUri.host.isNotEmpty &&
        baseUri.host != 'localhost' &&
        baseUri.host != '127.0.0.1') {
      return uri.replace(host: baseUri.host).toString();
    }
    return rawUrl;
  }

  VoiceConnection toDomain() => VoiceConnection(
    serverUrl: serverUrl,
    token: token,
    iceServers: iceServers,
  );
}

String _required(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw ParseFailure('voice.$key');
  }
  return value;
}

List<VoiceIceServer> _iceServers(Object? value) {
  if (value == null) return const [];
  if (value is! List) throw const ParseFailure('voice.iceServers');
  return List.unmodifiable(
    value.map((item) {
      if (item is! Map<String, dynamic>) {
        throw const ParseFailure('voice.iceServers');
      }
      final urls = item['urls'];
      final values = urls is String ? [urls] : urls;
      if (values is! List ||
          values.isEmpty ||
          values.any((v) => v is! String)) {
        throw const ParseFailure('voice.iceServers.urls');
      }
      return VoiceIceServer(
        urls: List<String>.unmodifiable(values.cast<String>()),
        username: item['username'] as String?,
        credential: item['credential'] as String?,
      );
    }),
  );
}
