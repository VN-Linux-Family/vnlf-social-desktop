import 'dart:io';

import '../../../core/api_client.dart';
import '../../../core/io_api_transport.dart';
import '../domain/community_connection.dart';

final class IoCommunityConnection implements CommunityConnection {
  IoCommunityConnection._(this._socket);
  final WebSocket _socket;
  static Future<CommunityConnection> connect(
    IoApiTransport transport,
    ApiSessionScope scope,
  ) async =>
      IoCommunityConnection._(await transport.openCommunitySocket(scope));
  @override
  Stream<Object?> get frames => _socket.cast<Object?>();
  @override
  int? get closeCode => _socket.closeCode;
  @override
  void send(String frame) {
    if (_socket.readyState != WebSocket.open) throw const TransportFailure();
    try {
      _socket.add(frame);
    } catch (_) {
      throw const TransportFailure();
    }
  }

  @override
  Future<void> close() async {
    await _socket.close();
  }
}
