import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../i18n/vi.dart';

final localNotificationServiceProvider = Provider<LocalNotificationService>((
  ref,
) {
  final service = LocalNotificationService();
  ref.onDispose(service.dispose);
  return service;
});

class LocalNotificationService {
  LocalNotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;
  void Function(String? payload)? _onNotificationTap;

  bool get isSupportedPlatform {
    if (kIsWeb) return false;
    return Platform.isLinux ||
        Platform.isWindows ||
        Platform.isMacOS ||
        Platform.isAndroid;
  }

  Future<bool> initialize({
    void Function(String? payload)? onSelectNotification,
  }) async {
    if (_initialized) return true;
    if (!isSupportedPlatform) return false;
    try {
      if (Platform.environment.containsKey('FLUTTER_TEST')) {
        _initialized = true;
        return true;
      }
    } catch (_) {}

    _onNotificationTap = onSelectNotification;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    final linuxSettings = LinuxInitializationSettings(
      defaultActionName: vi.app.common.moVnlfSocial,
      defaultIcon: AssetsLinuxIcon('assets/images/vnlf-icon-maskable.png'),
    );

    final initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
      linux: linuxSettings,
    );

    try {
      final initialized = await _plugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (response) {
          _onNotificationTap?.call(response.payload);
        },
      );
      _initialized = initialized ?? false;
      if (_initialized) unawaited(_openLaunchNotification());
      return _initialized;
    } catch (e) {
      debugPrint('Failed to initialize local notifications: $e');
      return false;
    }
  }

  /// Asks Android 13+ for the notification permission and reports whether
  /// notifications can be shown. Older Android versions report the system
  /// setting; other platforms need no grant here.
  Future<bool> requestPermission() async {
    if (kIsWeb || !Platform.isAndroid) return true;
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return await android?.requestNotificationsPermission() ?? false;
  }

  /// Shows a notification; false when the system did not take it.
  Future<bool> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String? groupKey,
    bool persistent = false,
  }) async {
    try {
      if (Platform.environment.containsKey('FLUTTER_TEST')) return true;
    } catch (_) {}

    if (!_initialized) {
      final ok = await initialize(onSelectNotification: _onNotificationTap);
      if (!ok) return false;
    }

    final androidDetails = AndroidNotificationDetails(
      'vnlf_messages',
      vi.app.notifications.tinNhanThongBao,
      channelDescription: vi.app.notifications.thongBaoTinNhan,
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    // The website's `requireInteraction` keeps a notification on screen until
    // it is dismissed. Linux takes that as a timeout; elsewhere the system's
    // notification settings decide.
    final linuxDetails = LinuxNotificationDetails(
      urgency: LinuxNotificationUrgency.normal,
      category: LinuxNotificationCategory.imReceived,
      timeout: persistent
          ? const LinuxNotificationTimeout.expiresNever()
          : const LinuxNotificationTimeout.systemDefault(),
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
      linux: linuxDetails,
    );

    try {
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
        payload: payload,
      );
      return true;
    } catch (e) {
      debugPrint('Error showing local notification: $e');
      return false;
    }
  }

  Future<void> cancel(int id) async {
    if (!_initialized) return;
    try {
      await _plugin.cancel(id: id);
    } catch (_) {}
  }

  Future<void> cancelAll() async {
    if (!_initialized) return;
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }

  /// A tap on a notification can start the app, for example one shown while
  /// it was closed. The plugin reports that tap here instead of through the
  /// tap callback.
  Future<void> _openLaunchNotification() async {
    try {
      final details = await _plugin.getNotificationAppLaunchDetails();
      final payload = details?.notificationResponse?.payload;
      if (details?.didNotificationLaunchApp == true && payload != null) {
        _onNotificationTap?.call(payload);
      }
    } catch (error) {
      debugPrint('Notification launch details unavailable: $error');
    }
  }

  void dispose() {
    _onNotificationTap = null;
  }
}
