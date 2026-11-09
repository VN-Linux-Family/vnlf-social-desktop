import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Whether the app runs on Android. Tests override it to render Android-only
/// settings on the host platform.
final androidPlatformProvider = Provider<bool>(
  (ref) => AndroidBackgroundService.isAndroid,
);

/// Starts and stops the Android foreground service that keeps the process,
/// and with it the realtime connection, alive in the background.
abstract interface class BackgroundServiceControl {
  Future<void> start();
  Future<void> stop();
}

final backgroundServiceControlProvider = Provider<BackgroundServiceControl>(
  (ref) => const AndroidBackgroundService(),
);

/// The member's choice to keep notifying in the background. It stays off
/// until they turn it on, because it shows a permanent notification.
final androidBackgroundSyncProvider =
    StateNotifierProvider<AndroidBackgroundSyncNotifier, bool>(
      (ref) => AndroidBackgroundSyncNotifier(),
    );

class AndroidBackgroundSyncNotifier extends StateNotifier<bool> {
  AndroidBackgroundSyncNotifier() : super(false) {
    unawaited(_load());
  }

  static const _prefKey = 'android_background_sync';

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getBool(_prefKey);
      if (mounted && stored != null) state = stored;
    } on Object catch (error) {
      debugPrint(
        'Background sync preference unavailable: ${error.runtimeType}',
      );
    }
  }

  Future<void> toggle(bool enabled) async {
    state = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, enabled);
    } on Object catch (error) {
      debugPrint('Background sync preference not saved: ${error.runtimeType}');
    }
  }
}

final class AndroidBackgroundService implements BackgroundServiceControl {
  const AndroidBackgroundService();

  static const _channel = MethodChannel(
    'net.vietnamlinuxfamily.vnlfsocialapp/background_sync',
  );

  static bool get isAndroid => !kIsWeb && Platform.isAndroid;

  @override
  Future<void> start() => _invoke('startService');

  @override
  Future<void> stop() => _invoke('stopService');

  Future<void> _invoke(String method) async {
    if (!isAndroid) return;
    await _channel.invokeMethod<bool>(method);
  }
}
