import 'dart:ffi';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/preferences_storage.dart';
import '../data/github_update_repository.dart';
import '../domain/app_update.dart';

const installedAppVersion = String.fromEnvironment(
  'APP_VERSION',
  defaultValue: '0.1.0',
);
final updateRepositoryProvider = Provider<UpdateRepository>(
  (ref) => GitHubUpdateRepository(),
);
final updatePlatformProvider = Provider<UpdatePlatform>(
  (ref) => switch (Abi.current()) {
    Abi.linuxX64 => const UpdatePlatform('linux', 'x64', 'tar.gz'),
    Abi.linuxArm64 => const UpdatePlatform('linux', 'arm64', 'tar.gz'),
    Abi.macosX64 => const UpdatePlatform('macos', 'x64', 'zip'),
    Abi.macosArm64 => const UpdatePlatform('macos', 'arm64', 'zip'),
    Abi.windowsX64 => const UpdatePlatform('windows', 'x64', 'zip'),
    Abi.windowsArm64 => const UpdatePlatform('windows', 'arm64', 'zip'),
    Abi.androidArm => const UpdatePlatform('android', 'armv7', 'apk'),
    Abi.androidArm64 => const UpdatePlatform('android', 'arm64', 'apk'),
    Abi.androidX64 => const UpdatePlatform('android', 'x64', 'apk'),
    _ => const UpdatePlatform('unsupported', 'unsupported', ''),
  },
);

final updateControllerProvider =
    StateNotifierProvider<UpdateController, AsyncValue<AppUpdate?>>(
      (ref) => UpdateController(
        ref.watch(updateRepositoryProvider),
        ref.watch(updatePlatformProvider),
        ref.watch(preferencesStorageProvider),
      ),
    );

class UpdateController extends StateNotifier<AsyncValue<AppUpdate?>> {
  UpdateController(this._repository, this._platform, this._storage)
    : super(const AsyncData(null));
  final UpdateRepository _repository;
  final UpdatePlatform _platform;
  final PreferencesStorage _storage;
  bool _pending = false;

  Future<void> check({bool automatic = false}) async {
    if (_pending) return;
    _pending = true;
    try {
      if (automatic) {
        DateTime? last;
        try {
          last = DateTime.tryParse(
            await _storage.read('vnlf_last_update_check') ?? '',
          );
        } catch (_) {
          // A cache failure must not disable the actual release check.
        }
        final age = last == null ? null : DateTime.now().difference(last);
        if (age != null &&
            age >= Duration.zero &&
            age < const Duration(hours: 24)) {
          return;
        }
      }
      if (!mounted) return;
      state = const AsyncLoading();
      final result = await _repository.check(installedAppVersion, _platform);
      if (!mounted) return;
      state = AsyncData(result);
      try {
        await _storage.write(
          'vnlf_last_update_check',
          DateTime.now().toUtc().toIso8601String(),
        );
      } catch (_) {
        /* Preferences do not invalidate a completed release check. */
      }
    } catch (error, stack) {
      if (mounted) {
        state = AsyncError(
          error is UpdateFailure ? error : const UpdateFailure(),
          stack,
        );
      }
    } finally {
      _pending = false;
    }
  }
}
