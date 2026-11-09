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

final androidBackgroundSyncProvider =
    StateNotifierProvider<AndroidBackgroundSyncNotifier, bool>((ref) {
      return AndroidBackgroundSyncNotifier();
    });

class AndroidBackgroundSyncNotifier extends StateNotifier<bool> {
  AndroidBackgroundSyncNotifier() : super(true) {
    _load();
  }

  static const _prefKey = 'android_background_sync';

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final val = prefs.getBool(_prefKey) ?? true;
      state = val;
      if (val && AndroidBackgroundService.isAndroid) {
        await AndroidBackgroundService.start();
      }
    } catch (_) {}
  }

  Future<void> toggle(bool enabled) async {
    state = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, enabled);
    } catch (_) {}

    if (AndroidBackgroundService.isAndroid) {
      if (enabled) {
        await AndroidBackgroundService.start();
      } else {
        await AndroidBackgroundService.stop();
      }
    }
  }
}

class AndroidBackgroundService {
  static const _channel = MethodChannel(
    'net.vietnamlinuxfamily.vnlfsocialapp/background_sync',
  );

  static bool get isAndroid => !kIsWeb && Platform.isAndroid;

  static Future<bool> start() async {
    if (!isAndroid) return false;
    try {
      if (Platform.environment.containsKey('FLUTTER_TEST')) return true;
    } catch (_) {}
    try {
      final res = await _channel.invokeMethod<bool>('startService');
      return res ?? false;
    } catch (e) {
      debugPrint('AndroidBackgroundService start failed: $e');
      return false;
    }
  }

  static Future<bool> stop() async {
    if (!isAndroid) return false;
    try {
      final res = await _channel.invokeMethod<bool>('stopService');
      return res ?? false;
    } catch (e) {
      debugPrint('AndroidBackgroundService stop failed: $e');
      return false;
    }
  }

  static Future<bool> isRunning() async {
    if (!isAndroid) return false;
    try {
      final res = await _channel.invokeMethod<bool>('isServiceRunning');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }
}
