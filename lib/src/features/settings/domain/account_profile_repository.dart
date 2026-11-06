import 'account_profile.dart';

abstract interface class AccountProfileRepository {
  /// Reads the signed-in owner's profile by username. Safe to repeat.
  Future<AccountProfile> load(String username);

  /// Sends the changed fields once. Never retried: a failure that may have
  /// reached the server is reported as such and left to the caller.
  Future<void> save(ProfilePatch patch);
}
