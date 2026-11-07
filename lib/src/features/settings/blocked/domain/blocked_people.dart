final class BlockedPerson {
  const BlockedPerson({required this.id, required this.username, required this.displayName, this.bio = '', this.avatarUrl, this.blockedAt});
  final String id;
  final String username;
  final String displayName;
  final String bio;
  final String? avatarUrl;
  final DateTime? blockedAt;
}

abstract interface class BlockedPeopleRepository {
  Future<List<BlockedPerson>> load();
  Future<void> unblock(String id);
}
