import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';
import '../domain/voice_models.dart';
import '../domain/voice_repository.dart';
import '../domain/voice_room_session.dart';

final class VoiceSessionState {
  const VoiceSessionState({
    this.phase = VoicePhase.disconnected,
    this.roomId,
    this.muted = true,
    this.deafened = false,
    this.busy = false,
    this.participants = const [],
    this.failure,
  });
  final VoicePhase phase;
  final String? roomId;
  final bool muted, deafened, busy;
  final List<VoiceMember> participants;
  final VoiceFailure? failure;
  bool get connected => phase == VoicePhase.connected;

  VoiceSessionState copyWith({
    VoicePhase? phase,
    bool? muted,
    bool? deafened,
    bool? busy,
    List<VoiceMember>? participants,
    VoiceFailure? failure,
  }) => VoiceSessionState(
    phase: phase ?? this.phase,
    roomId: roomId,
    muted: muted ?? this.muted,
    deafened: deafened ?? this.deafened,
    busy: busy ?? this.busy,
    participants: participants ?? this.participants,
    failure: failure,
  );
}

/// Invalidates late async work before releasing audio on leave/account change.
final class VoiceSessionController extends StateNotifier<VoiceSessionState> {
  VoiceSessionController(
    this._repository,
    this._createSession, {
    String? initialAccount,
  }) : _accountId = initialAccount,
       super(const VoiceSessionState());
  final VoiceRepository _repository;
  final VoiceRoomSessionFactory _createSession;
  String? _accountId;
  VoiceRoomSession? _session;
  StreamSubscription<VoiceRoomSnapshot>? _subscription;
  bool _grantReceived = false;
  bool _disposed = false;
  int _generation = 0;
  Future<void> _cleanup = Future.value();
  Future<void> get closed => _cleanup;

  bool _current(int generation) => !_disposed && generation == _generation;

  Future<void> setAccount(String? accountId) async {
    if (_accountId == accountId) return;
    _accountId = accountId;
    // The shared HTTP client now belongs to another account. Do not POST leave
    // for the old user with the new user's cookies; RTC disconnect clears audio.
    await leave(notifyServer: false);
  }

  Future<void> join(VoiceRoom room) async {
    if (_disposed || state.busy || state.roomId == room.id && state.connected) {
      return;
    }
    if (_accountId == null) {
      state = const VoiceSessionState(
        phase: VoicePhase.failed,
        failure: VoiceAccessFailure(),
      );
      return;
    }
    if (!room.canJoin) {
      state = const VoiceSessionState(
        phase: VoicePhase.failed,
        failure: VoiceUnavailableFailure(),
      );
      return;
    }
    final account = _accountId;
    await leave();
    if (_disposed || _accountId != account) return;
    final generation = ++_generation;
    state = VoiceSessionState(
      phase: VoicePhase.connecting,
      roomId: room.id,
      busy: true,
    );
    try {
      final session = _createSession();
      _session = session;
      _subscription = session.changes.listen(
        (snapshot) {
          if (!_current(generation)) return;
          if (snapshot.phase == VoicePhase.disconnected ||
              snapshot.phase == VoicePhase.failed) {
            unawaited(_failAndRelease(const VoiceConnectionFailure()));
          } else if (state.phase != VoicePhase.connecting) {
            state = state.copyWith(
              phase: snapshot.phase,
              participants: snapshot.participants,
            );
          }
        },
        onError: (Object error) {
          if (_current(generation)) unawaited(_failAndRelease(_failure(error)));
        },
      );
      final connection = await _repository.join(room.id);
      if (!_current(generation)) {
        if (_accountId == account && !_disposed && state.roomId != room.id) {
          try {
            await _repository.leave(room.id);
          } catch (_) {}
        }
        return;
      }
      _grantReceived = true;
      await session.connect(connection);
      if (!_current(generation)) return;
      await session.setMicrophoneEnabled(false);
      if (!_current(generation)) return;
      state = VoiceSessionState(
        phase: VoicePhase.connected,
        roomId: room.id,
        participants: session.snapshot.participants,
      );
    } catch (error) {
      if (_current(generation)) await _failAndRelease(_failure(error));
    }
  }

  Future<void> toggleMicrophone() async {
    if (!state.connected || state.busy || state.deafened) return;
    final generation = _generation;
    final enabled = state.muted;
    state = state.copyWith(busy: true);
    try {
      await _session!.setMicrophoneEnabled(enabled);
      if (_current(generation)) {
        state = state.copyWith(muted: !enabled, busy: false);
      }
    } catch (error) {
      if (!_current(generation)) return;
      // An unmute error remains safely muted. A failed mute must disconnect.
      if (enabled) {
        state = state.copyWith(busy: false, failure: _failure(error));
      } else {
        await _failAndRelease(_failure(error));
      }
    }
  }

  Future<void> toggleDeafen() async {
    if (!state.connected || state.busy) return;
    final generation = _generation;
    final deafened = !state.deafened;
    state = state.copyWith(busy: true);
    try {
      await _session!.setMicrophoneEnabled(false);
      if (!_current(generation)) return;
      await _session!.setPlaybackEnabled(!deafened);
      if (_current(generation)) {
        state = state.copyWith(muted: true, deafened: deafened, busy: false);
      }
    } catch (error) {
      if (_current(generation)) await _failAndRelease(_failure(error));
    }
  }

  Future<void> _failAndRelease(VoiceFailure failure) async {
    final cleanup = leave();
    final generation = _generation;
    await cleanup;
    if (_current(generation)) {
      state = VoiceSessionState(phase: VoicePhase.failed, failure: failure);
    }
  }

  Future<void> leave({bool notifyServer = true}) {
    final roomId = state.roomId;
    final account = _accountId;
    final session = _session;
    final subscription = _subscription;
    final granted = _grantReceived;
    final generation = ++_generation;
    _session = null;
    _subscription = null;
    _grantReceived = false;
    if (!_disposed) state = const VoiceSessionState();
    final previous = _cleanup;
    final cleanup = () async {
      VoiceFailure? failure;
      await subscription?.cancel();
      try {
        await session?.close();
      } catch (error) {
        failure = _failure(error);
      }
      if (notifyServer && granted && roomId != null && _accountId == account) {
        try {
          await _repository.leave(roomId);
        } catch (error) {
          failure ??= _failure(error);
        }
      }
      if (_current(generation) && failure != null) {
        state = VoiceSessionState(failure: failure);
      }
    }();
    _cleanup = Future.wait([previous, cleanup]).then((_) {});
    return _cleanup;
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    unawaited(leave());
    super.dispose();
  }
}

VoiceFailure _failure(Object error) => switch (error) {
  VoiceFailure() => error,
  HttpFailure(statusCode: 401 || 403) => const VoiceAccessFailure(),
  _ => const VoiceConnectionFailure(),
};
