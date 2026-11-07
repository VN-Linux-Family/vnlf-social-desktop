import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/features/realtime/data/community_socket_client.dart';
import 'package:vnlfsocialapp/src/features/realtime/domain/community_connection.dart';
import 'package:vnlfsocialapp/src/features/realtime/domain/community_status.dart';

class _FakeConnection implements CommunityConnection {
  final _frames = StreamController<Object?>.broadcast(sync: true);
  int closeCount = 0;

  @override
  Stream<Object?> get frames => _frames.stream;

  @override
  int? get closeCode => null;

  @override
  Future<void> close([int? code, String? reason]) async {
    closeCount++;
  }

  @override
  void send(String frame) {
    try {
      final json = jsonDecode(frame) as Map<String, dynamic>;
      final requestId = json['requestId'];
      if (requestId is String) {
        _frames.add(jsonEncode({'ok': true, 'requestId': requestId}));
      }
    } catch (_) {}
  }
}

void main() {
  test('with keepAliveInBackground=true, setForeground(false) does not close socket', () async {
    final connection = _FakeConnection();
    final client = CommunitySocketClient(
      connector: () async => connection,
      keepAliveInBackground: true,
    );

    await client.start();
    expect(client.status.phase, CommunityConnectionPhase.connected);

    // Transition to background
    await client.setForeground(false);

    // When keepAliveInBackground is true, socket should NOT be closed
    expect(connection.closeCount, 0);
    expect(client.status.phase, CommunityConnectionPhase.connected);

    await client.dispose();
    expect(connection.closeCount, 1);
  });

  test(
    'with keepAliveInBackground=false, setForeground(false) suspends socket',
    () async {
      final connection = _FakeConnection();
      final client = CommunitySocketClient(
        connector: () async => connection,
        keepAliveInBackground: false,
      );

      await client.start();
      expect(client.status.phase, CommunityConnectionPhase.connected);

      await client.setForeground(false);

      // When keepAliveInBackground is false, socket IS released
      expect(connection.closeCount, 1);
      expect(client.status.phase, CommunityConnectionPhase.suspended);

      await client.dispose();
    },
  );
}
