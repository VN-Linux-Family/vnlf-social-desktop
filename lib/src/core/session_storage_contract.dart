/// Opaque session storage used by the HTTP layer, independent of platform plugins.
abstract interface class SessionStorage {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}
