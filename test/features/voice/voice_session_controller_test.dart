import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/features/voice/domain/voice_models.dart';
import 'package:vnlfsocialapp/src/features/voice/domain/voice_repository.dart';
import 'package:vnlfsocialapp/src/features/voice/domain/voice_room_session.dart';
import 'package:vnlfsocialapp/src/features/voice/presentation/voice_session_controller.dart';

void main() {
  late _Repository repository;
  late _AudioSession audio;
  late VoiceSessionController controller;

  setUp(() {
    repository = _Repository();
    audio = _AudioSession();
    controller = VoiceSessionController(
      repository,
      () => audio,
      initialAccount: 'account-a',
    );
  });
  tearDown(() async {
    controller.dispose();
    await controller.closed;
  });

  test('RTC connection must finish before showing connected', () async {
    final gate = Completer<void>();
    audio.connectGate = gate.future;
    final joining = controller.join(_room);
    await _flush();
    expect(controller.state.phase, VoicePhase.connecting);
    expect(controller.state.connected, isFalse);
    gate.complete();
    await joining;
    expect(controller.state.connected, isTrue);
    expect(controller.state.muted, isTrue);
    expect(audio.microphoneEnabled, isFalse);
  });

  test(
    'failed RTC join releases audio and rolls server membership back',
    () async {
      audio.connectError = const VoiceConnectionFailure();
      await controller.join(_room);
      expect(controller.state.phase, VoicePhase.failed);
      expect(controller.state.roomId, isNull);
      expect(controller.state.failure, isA<VoiceConnectionFailure>());
      expect(audio.closed, isTrue);
      expect(repository.left, ['room-1']);
    },
  );

  test(
    'token failure does not connect audio or claim room membership',
    () async {
      repository.joinError = const VoiceAccessFailure();
      await controller.join(_room);
      expect(controller.state.connected, isFalse);
      expect(controller.state.failure, isA<VoiceAccessFailure>());
      expect(audio.connectCalls, 0);
      expect(audio.closed, isTrue);
    },
  );

  test(
    'microphone permission failure stays muted and exposes typed error',
    () async {
      await controller.join(_room);
      audio.microphoneError = const VoicePermissionFailure();
      await controller.toggleMicrophone();
      expect(controller.state.muted, isTrue);
      expect(controller.state.failure, isA<VoicePermissionFailure>());
      expect(audio.microphoneEnabled, isFalse);
    },
  );

  test(
    'deafen mutes microphone and new remote tracks, undeafen stays muted',
    () async {
      await controller.join(_room);
      await controller.toggleMicrophone();
      expect(controller.state.muted, isFalse);
      await controller.toggleDeafen();
      expect(controller.state.deafened, isTrue);
      expect(controller.state.muted, isTrue);
      expect(audio.playbackEnabled, isFalse);
      await controller.toggleDeafen();
      expect(controller.state.deafened, isFalse);
      expect(controller.state.muted, isTrue);
      expect(audio.microphoneEnabled, isFalse);
    },
  );

  test(
    'playback failure disconnects instead of claiming successful deafen',
    () async {
      await controller.join(_room);
      audio.playbackError = const VoiceAudioFailure();
      await controller.toggleDeafen();
      expect(controller.state.connected, isFalse);
      expect(controller.state.failure, isA<VoiceAudioFailure>());
      expect(audio.closed, isTrue);
    },
  );

  test('leave closes audio even when server leave fails', () async {
    await controller.join(_room);
    repository.leaveError = const VoiceConnectionFailure();
    await controller.leave();
    expect(controller.state.connected, isFalse);
    expect(controller.state.roomId, isNull);
    expect(audio.closed, isTrue);
    expect(controller.state.failure, isNotNull);
    expect(repository.left, ['room-1']);
  });

  test('dispose closes media and sends leave once', () async {
    await controller.join(_room);
    controller.dispose();
    await controller.closed;
    expect(audio.closed, isTrue);
    expect(repository.left, ['room-1']);
  });

  test(
    'account switch closes audio without a POST under the new account',
    () async {
      await controller.join(_room);
      await controller.setAccount('account-b');
      expect(controller.state.connected, isFalse);
      expect(audio.closed, isTrue);
      expect(repository.left, isEmpty);
    },
  );

  test(
    'logout during token request prevents a late audio connection',
    () async {
      final gate = Completer<VoiceConnection>();
      repository.joinGate = gate.future;
      final joining = controller.join(_room);
      await _flush();
      await controller.setAccount(null);
      gate.complete(_connection);
      await joining;
      expect(audio.connectCalls, 0);
      expect(controller.state.connected, isFalse);
      expect(repository.left, isEmpty);
    },
  );

  test(
    'leaving during connection cannot resurrect a late connected state',
    () async {
      final gate = Completer<void>();
      audio.connectGate = gate.future;
      final joining = controller.join(_room);
      await _flush();
      await controller.leave();
      gate.complete();
      await joining;
      expect(audio.closed, isTrue);
      expect(controller.state.connected, isFalse);
      expect(repository.left, ['room-1']);
    },
  );

  test('remote disconnect clears participants and releases audio', () async {
    await controller.join(_room);
    audio.events.add(const VoiceRoomSnapshot(phase: VoicePhase.disconnected));
    await _flush();
    expect(controller.state.connected, isFalse);
    expect(controller.state.participants, isEmpty);
    expect(audio.closed, isTrue);
  });
}

const _room = VoiceRoom(
  id: 'room-1',
  name: 'Phòng thử nghiệm',
  status: 'ACTIVE',
);
const _connection = VoiceConnection(
  serverUrl: 'wss://voice.example.invalid',
  token: 'synthetic-test-value',
);
Future<void> _flush() => Future<void>.delayed(Duration.zero);

class _Repository implements VoiceRepository {
  final left = <String>[];
  VoiceFailure? joinError;
  VoiceFailure? leaveError;
  Future<VoiceConnection>? joinGate;
  @override
  Future<List<VoiceRoom>> getRooms() async => [_room];
  @override
  Future<VoiceConnection> join(String roomId) async {
    if (joinError != null) throw joinError!;
    return joinGate ?? _connection;
  }

  @override
  Future<void> leave(String roomId) async {
    left.add(roomId);
    if (leaveError != null) throw leaveError!;
  }
}

class _AudioSession implements VoiceRoomSession {
  final events = StreamController<VoiceRoomSnapshot>.broadcast(sync: true);
  bool closed = false;
  bool microphoneEnabled = false;
  bool playbackEnabled = true;
  int connectCalls = 0;
  Future<void>? connectGate;
  VoiceFailure? connectError;
  VoiceFailure? microphoneError;
  VoiceFailure? playbackError;
  @override
  Stream<VoiceRoomSnapshot> get changes => events.stream;
  @override
  VoiceRoomSnapshot get snapshot =>
      const VoiceRoomSnapshot(phase: VoicePhase.connected);
  @override
  Future<void> connect(VoiceConnection connection) async {
    connectCalls++;
    if (connectError != null) throw connectError!;
    await connectGate;
  }

  @override
  Future<void> setMicrophoneEnabled(bool enabled) async {
    if (microphoneError != null) throw microphoneError!;
    microphoneEnabled = enabled;
  }

  @override
  Future<void> setPlaybackEnabled(bool enabled) async {
    if (playbackError != null) throw playbackError!;
    playbackEnabled = enabled;
  }

  @override
  Future<void> close() async {
    closed = true;
    microphoneEnabled = false;
    await events.close();
  }
}
