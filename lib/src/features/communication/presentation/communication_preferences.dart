import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/preferences_storage.dart';
import '../../../domain/models.dart';

final communicationFilterProvider = StateProvider<String>((ref) {
  ref.watch(sessionStateProvider.select((session) => session?.userId));
  return '';
});
final communicationPreferenceFailureProvider = StateProvider<StorageFailure?>(
  (ref) => null,
);
final channelsCollapsedProvider =
    StateNotifierProvider<ChannelCollapseController, bool>(
      (ref) => ChannelCollapseController(
        ref.watch(preferencesStorageProvider),
        (failure) =>
            ref.read(communicationPreferenceFailureProvider.notifier).state =
                failure,
      ),
    );

class ChannelCollapseController extends StateNotifier<bool> {
  ChannelCollapseController(this._storage, this._onError) : super(false) {
    unawaited(_restore());
  }
  final PreferencesStorage _storage;
  final void Function(StorageFailure?) _onError;
  int _revision = 0;
  Future<void> _writes = Future.value();
  Future<void> _restore() async {
    final revision = _revision;
    try {
      final value = await _storage.read('vnlf-channels-collapsed');
      if (mounted && revision == _revision) state = value == '1';
    } catch (_) {
      if (mounted && revision == _revision) _onError(const StorageFailure());
    }
  }

  Future<void> toggle() {
    final revision = ++_revision;
    final value = !state;
    state = value;
    return _writes = _writes.then((_) async {
      try {
        await _storage.write('vnlf-channels-collapsed', value ? '1' : '0');
        if (mounted && revision == _revision) _onError(null);
      } catch (_) {
        if (mounted && revision == _revision) _onError(const StorageFailure());
      }
    });
  }
}
