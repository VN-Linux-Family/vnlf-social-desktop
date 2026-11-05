import 'dart:async';
import 'dart:collection';

import 'package:flutter_test/flutter_test.dart';
import 'package:livekit_client/livekit_client.dart' as rtc;
import 'package:vnlfsocialapp/src/features/voice/data/livekit_voice_session.dart';
import 'package:vnlfsocialapp/src/features/voice/domain/voice_models.dart';

void main() {
  test(
    'connect forwards server ICE config and never auto-publishes microphone',
    () async {
      final room = _Room();
      final session = LiveKitVoiceSession(createRoom: () => room);
      await session.connect(
        const VoiceConnection(
          serverUrl: 'wss://voice.example.invalid',
          token: 'synthetic-test-value',
          iceServers: [
            VoiceIceServer(urls: ['stun:example.invalid:3478']),
          ],
        ),
      );
      expect(session.snapshot.phase, VoicePhase.connected);
      expect(room.options!.autoSubscribe, isFalse);
      expect(room.options!.rtcConfiguration.iceServers!.single.urls, [
        'stun:example.invalid:3478',
      ]);
      expect(room.local.microphoneEnabled, isFalse);
      await session.close();
      expect(room.disconnected, isTrue);
      expect(room.disposed, isTrue);
    },
  );

  test(
    'deafen unsubscribes existing audio and rejects newly published tracks',
    () async {
      final publication = _Publication();
      final participant = _Participant(publication);
      final room = _Room()..remote['synthetic-remote'] = participant;
      final session = LiveKitVoiceSession(createRoom: () => room);
      await session.connect(_connection);
      expect(publication.listening, isTrue);
      await session.setPlaybackEnabled(false);
      expect(publication.listening, isFalse);
      room.events.streamCtrl.add(
        rtc.TrackPublishedEvent(
          participant: participant,
          publication: publication,
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(publication.listening, isFalse);
      await session.setPlaybackEnabled(true);
      expect(publication.listening, isTrue);
      await session.close();
    },
  );

  test(
    'closing pending RTC connect cannot leave a late native room active',
    () async {
      final gate = Completer<void>();
      final room = _Room()..gate = gate.future;
      final session = LiveKitVoiceSession(createRoom: () => room);
      final joining = session.connect(_connection);
      await Future<void>.delayed(Duration.zero);
      await session.close();
      gate.complete();
      await expectLater(joining, throwsA(isA<VoiceConnectionFailure>()));
      expect(room.disconnected, isTrue);
      expect(room.disposed, isTrue);
      expect(session.snapshot.phase, VoicePhase.disconnected);
    },
  );
}

const _connection = VoiceConnection(
  serverUrl: 'wss://voice.example.invalid',
  token: 'synthetic-test-value',
);

class _Room extends Fake implements rtc.Room {
  @override
  final events = rtc.EventsEmitter<rtc.RoomEvent>();
  final local = _Local();
  final remote = <String, rtc.RemoteParticipant>{};
  bool disconnected = false;
  bool disposed = false;
  rtc.ConnectOptions? options;
  Future<void>? gate;
  @override
  rtc.LocalParticipant? get localParticipant => local;
  @override
  UnmodifiableMapView<String, rtc.RemoteParticipant> get remoteParticipants =>
      UnmodifiableMapView(remote);
  @override
  rtc.ConnectionState get connectionState => disconnected
      ? rtc.ConnectionState.disconnected
      : rtc.ConnectionState.connected;
  @override
  rtc.EventsListener<rtc.RoomEvent> createListener({
    bool synchronized = false,
  }) => rtc.EventsListener(events, synchronized: synchronized);
  @override
  Future<void> connect(
    String url,
    String token, {
    rtc.ConnectOptions? connectOptions,
    rtc.RoomOptions? roomOptions,
    rtc.FastConnectOptions? fastConnectOptions,
  }) async {
    options = connectOptions;
    await gate;
    disconnected = false;
  }

  @override
  Future<void> disconnect() async => disconnected = true;
  @override
  Future<bool> dispose() async {
    disposed = true;
    return true;
  }
}

class _Local extends Fake implements rtc.LocalParticipant {
  bool microphoneEnabled = false;
  @override
  String get identity => 'synthetic-local';
  @override
  String get name => 'Thành viên thử nghiệm';
  @override
  String? get metadata => null;
  @override
  bool get isMuted => !microphoneEnabled;
  @override
  bool get isSpeaking => false;
  @override
  List<rtc.LocalTrackPublication<rtc.LocalAudioTrack>>
  get audioTrackPublications => [];
  @override
  Future<rtc.LocalTrackPublication?> setMicrophoneEnabled(
    bool enabled, {
    rtc.AudioCaptureOptions? audioCaptureOptions,
  }) async {
    microphoneEnabled = enabled;
    return null;
  }
}

class _Participant extends Fake implements rtc.RemoteParticipant {
  _Participant(this.publication);
  final _Publication publication;
  @override
  List<rtc.RemoteTrackPublication<rtc.RemoteAudioTrack>>
  get audioTrackPublications => [publication];
  @override
  String get identity => 'synthetic-remote';
  @override
  String get name => 'Thành viên khác';
  @override
  String? get metadata => null;
  @override
  bool get isMuted => false;
  @override
  bool get isSpeaking => false;
}

class _Publication extends Fake
    implements rtc.RemoteTrackPublication<rtc.RemoteAudioTrack> {
  bool listening = false;
  @override
  rtc.RemoteAudioTrack? get track => null;
  @override
  rtc.TrackType get kind => rtc.TrackType.AUDIO;
  @override
  Future<void> subscribe() async => listening = true;
  @override
  Future<void> unsubscribe() async => listening = false;
}
