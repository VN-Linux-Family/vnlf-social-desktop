enum ProfileRelationshipAction { follow, unfollow, block, unblock }

/// Writes the viewer's follow and block relationship with another member.
///
/// Implementations return only after the server acknowledged the change and
/// throw otherwise. Callers must not retry automatically.
abstract interface class ProfileRelationshipRepository {
  Future<void> setFollowing(String userId, {required bool following});
  Future<void> setBlocked(String userId, {required bool blocked});
}
