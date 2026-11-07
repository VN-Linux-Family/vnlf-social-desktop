final class SecuritySession {
  const SecuritySession({required this.id, required this.current, this.deviceName, this.userAgent, this.lastSeenAt});
  final String id;
  final bool current;
  final String? deviceName;
  final String? userAgent;
  final DateTime? lastSeenAt;
}

abstract interface class SecuritySessionsRepository {
  Future<List<SecuritySession>> load();
  Future<void> revoke(SecuritySession session);
  Future<void> revokeOthers();
}
