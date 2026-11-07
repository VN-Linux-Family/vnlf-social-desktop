/// Authenticated session headers are intentionally absent from this interface.
abstract interface class CommunityConnection {
  Stream<Object?> get frames;
  int? get closeCode;
  void send(String frame);
  Future<void> close();
}

typedef CommunityConnector = Future<CommunityConnection> Function();
