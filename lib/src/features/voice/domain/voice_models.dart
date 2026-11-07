/// A server-owned voice room; no locally invented participant roster.
final class VoiceRoom {
  const VoiceRoom({
    required this.id,
    required this.name,
    required this.status,
    this.slug = '',
    this.description = '',
    this.capacity = 0,
    this.position = 0,
    this.participantCount = 0,
    this.viewerInRoom = false,
  });

  final String id;
  final String slug;
  final String name;
  final String description;
  final String status;
  final int capacity;
  final int position;
  final int participantCount;
  final bool viewerInRoom;

  bool get canJoin => status == 'ACTIVE';
}

/// Short-lived connection information. Never persist or log this object.
final class VoiceConnection {
  const VoiceConnection({
    required this.serverUrl,
    required this.token,
    this.iceServers = const [],
  });
  final String serverUrl;
  final String token;
  final List<VoiceIceServer> iceServers;
}

final class VoiceIceServer {
  const VoiceIceServer({required this.urls, this.username, this.credential});
  final List<String> urls;
  final String? username;
  final String? credential;
}

final class VoiceMember {
  const VoiceMember({
    required this.id,
    required this.name,
    this.username = '',
    this.avatarUrl = '',
    this.role = '',
    this.muted = true,
    this.speaking = false,
    this.local = false,
  });
  final String id;
  final String name;
  final String username;
  final String avatarUrl;
  final String role;
  final bool muted;
  final bool speaking;
  final bool local;
}

enum VoicePhase { disconnected, connecting, connected, reconnecting, failed }

final class VoiceRoomSnapshot {
  const VoiceRoomSnapshot({required this.phase, this.participants = const []});
  final VoicePhase phase;
  final List<VoiceMember> participants;
}

sealed class VoiceFailure implements Exception {
  const VoiceFailure();
}

final class VoiceAccessFailure extends VoiceFailure {
  const VoiceAccessFailure();
}

final class VoiceConnectionFailure extends VoiceFailure {
  const VoiceConnectionFailure();
}

final class VoicePermissionFailure extends VoiceFailure {
  const VoicePermissionFailure();
}

final class VoiceAudioFailure extends VoiceFailure {
  const VoiceAudioFailure();
}

final class VoiceUnavailableFailure extends VoiceFailure {
  const VoiceUnavailableFailure();
}
