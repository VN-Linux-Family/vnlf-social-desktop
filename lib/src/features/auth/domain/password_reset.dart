/// Asks the server to email a password reset link
/// (`POST /api/v1/auth/forgot-password`). The server answers the same way
/// whether or not the address has an account.
abstract interface class PasswordResetRepository {
  Future<void> requestReset(String email);
}
