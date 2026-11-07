import 'dart:async';
import 'dart:convert';

import 'package:livekit_client/livekit_client.dart' as rtc;

import '../domain/voice_models.dart';
import '../domain/voice_room_session.dart';

/// Native LiveKit boundary. Microphone capture is only requested on explicit unmute.
final class LiveKitVoiceSession implements VoiceRoomSession {
  LiveKitVoiceSession({rtc.Room Function()? createRoom})
    : _createRoom =
          createRoom ??
          (() => rtc.Room(
            roomOptions: const rtc.RoomOptions(
              adaptiveStream: true,
              dynacast: true,
            ),
          ));
  final rtc.Room Function() _createRoom;
  final _changes = StreamController<VoiceRoomSnapshot>.broadcast();
  rtc.Room? _room;
  rtc.EventsListener<rtc.RoomEvent>? _listener;
  bool _closed = false;
  bool _playbackEnabled = true;
  VoicePhase _phase = VoicePhase.disconnected;
  Future<void>? _closing;

  @override
  Stream<VoiceRoomSnapshot> get changes => _changes.stream;

  @override
  VoiceRoomSnapshot get snapshot => VoiceRoomSnapshot(
    phase: _phase,
    participants: List.unmodifiable([
      if (!_closed && _room?.localParticipant != null)
        _member(_room!.localParticipant!, local: true),
      if (!_closed && _room != null)
        for (final participant in _room!.remoteParticipants.values)
          _member(participant),
    ]),
  );

  @override
  Future<void> connect(VoiceConnection connection) async {
    if (_closed || _room != null) throw const VoiceConnectionFailure();
    _phase = VoicePhase.connecting;
    final room = _createRoom();
    _room = room;
    _listener = room.createListener(synchronized: true)..listen(_onEvent);
    try {
      await room.connect(
        connection.serverUrl,
        connection.token,
        connectOptions: rtc.ConnectOptions(
          // Subscribe to audio explicitly. A track published while deafened must
          // not play before a later UI event gets a chance to mute it.
          autoSubscribe: false,
          rtcConfiguration: rtc.RTCConfiguration(
            iceServers: connection.iceServers
                .map(
                  (server) => rtc.RTCIceServer(
                    urls: server.urls,
                    username: server.username,
                    credential: server.credential,
                  ),
                )
                .toList(),
          ),
        ),
      );
      if (_closed) {
        // An in-flight SDK connect can finish after disconnect was requested.
        await _releaseRoom(room);
        throw const VoiceConnectionFailure();
      }
      if (room.connectionState != rtc.ConnectionState.connected) {
        throw const VoiceConnectionFailure();
      }
      _phase = VoicePhase.connected;
      await _applyPlayback();
      _emit();
    } on VoiceFailure {
      rethrow;
    } catch (_) {
      throw const VoiceConnectionFailure();
    }
  }

  Future<void> _onEvent(rtc.RoomEvent event) async {
    if (_closed) return;
    if (event is rtc.RoomDisconnectedEvent) {
      _phase = VoicePhase.disconnected;
    } else if (event is rtc.RoomReconnectingEvent ||
        event is rtc.RoomResumingEvent) {
      _phase = VoicePhase.reconnecting;
    } else if (event is rtc.RoomReconnectedEvent) {
      _phase = VoicePhase.connected;
    } else if (event is rtc.AudioPlaybackStatusChanged && !event.isPlaying) {
      _changes.addError(const VoiceAudioFailure());
      return;
    }
    if (event is rtc.TrackPublishedEvent ||
        event is rtc.TrackSubscribedEvent ||
        event is rtc.RoomReconnectedEvent) {
      try {
        await _applyPlayback();
      } catch (_) {
        if (!_closed) _changes.addError(const VoiceAudioFailure());
        return;
      }
    }
    _emit();
  }

  void _emit() {
    if (!_closed) _changes.add(snapshot);
  }

  @override
  Future<void> setMicrophoneEnabled(bool enabled) async {
    if (_closed || _room?.localParticipant == null) {
      throw const VoiceConnectionFailure();
    }
    final room = _room!;
    try {
      await room.localParticipant!.setMicrophoneEnabled(enabled);
      if (_closed) {
        await _releaseRoom(room);
        throw const VoiceConnectionFailure();
      }
      _emit();
    } on VoiceFailure {
      rethrow;
    } catch (error) {
      // Flutter WebRTC can throw strings for getUserMedia permission denial.
      // Classify locally; never propagate native error text or RTC credentials.
      final description = error.toString().toLowerCase();
      if (description.contains('permission') ||
          description.contains('notallowed') ||
          description.contains('denied')) {
        throw const VoicePermissionFailure();
      }
      throw const VoiceAudioFailure();
    }
  }

  @override
  Future<void> setPlaybackEnabled(bool enabled) async {
    if (_closed || _room == null) throw const VoiceConnectionFailure();
    _playbackEnabled = enabled;
    try {
      await _applyPlayback();
    } catch (_) {
      throw const VoiceAudioFailure();
    }
  }

  Future<void> _applyPlayback() async {
    final room = _room;
    if (room == null || _closed) return;
    for (final participant in room.remoteParticipants.values.toList()) {
      for (final publication in participant.audioTrackPublications.toList()) {
        if (_closed) return;
        if (_playbackEnabled) {
          await publication.subscribe();
        } else {
          final track = publication.track;
          // Stop local playback before waiting for the server unsubscribe.
          if (track != null) await track.stop();
          await publication.unsubscribe();
        }
      }
    }
  }

  @override
  Future<void> close() {
    if (_closing != null) return _closing!;
    _closed = true;
    _phase = VoicePhase.disconnected;
    return _closing = () async {
      await _listener?.dispose();
      _listener = null;
      try {
        if (_room case final room?) await _releaseRoom(room);
      } finally {
        await _changes.close();
      }
    }();
  }

  Future<void> _releaseRoom(rtc.Room room) async {
    try {
      // Stop capture directly as well as disconnecting, including failed joins.
      for (final publication
          in room.localParticipant?.audioTrackPublications ??
              <rtc.LocalTrackPublication<rtc.LocalAudioTrack>>[]) {
        await publication.track?.stop();
      }
      await room.disconnect();
    } finally {
      await room.dispose();
    }
  }
}

VoiceMember _member(rtc.Participant participant, {bool local = false}) {
  Map<String, dynamic> metadata = const {};
  try {
    final decoded = jsonDecode(participant.metadata ?? '{}');
    if (decoded is Map<String, dynamic>) metadata = decoded;
  } on FormatException {
    // RTC metadata is optional and does not control identity or permissions.
  }
  String value(String key) =>
      metadata[key] is String ? metadata[key] as String : '';
  return VoiceMember(
    id: participant.identity,
    name: participant.name.isNotEmpty ? participant.name : participant.identity,
    username: value('username'),
    avatarUrl: value('avatarUrl'),
    role: value('role'),
    muted: participant.isMuted,
    speaking: participant.isSpeaking,
    local: local,
  );
}
