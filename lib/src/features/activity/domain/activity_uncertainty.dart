import '../../../core/session_storage_contract.dart';

/// Stores only whether an owner's attendance result needs reconciliation.
final class ActivityUncertainty {
  const ActivityUncertainty(this._storage, this.ownerId);

  final SessionStorage _storage;
  final String ownerId;

  String get _key => 'vnlf.activity.checkin.${Uri.encodeComponent(ownerId)}';

  Future<bool> read() async => await _storage.read(_key) != null;
  Future<void> mark() => _storage.write(_key, 'pending');
  Future<void> clear() => _storage.delete(_key);
}
