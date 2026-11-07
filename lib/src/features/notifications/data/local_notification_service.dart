import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      defaultActionName: 'Mở VNLF Social',
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
      return _initialized;
    } catch (e) {
      debugPrint('Failed to initialize local notifications: $e');
      return false;
    }
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String? groupKey,
  }) async {
    if (!_initialized) {
      final ok = await initialize(onSelectNotification: _onNotificationTap);
      if (!ok) return;
    }

    const androidDetails = AndroidNotificationDetails(
      'vnlf_messages',
      'Tin nhắn & Thông báo VNLF',
      channelDescription:
          'Thông báo tin nhắn và hoạt động mới từ Vietnam Linux Family',
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

    const linuxDetails = LinuxNotificationDetails(
      urgency: LinuxNotificationUrgency.normal,
      category: LinuxNotificationCategory.imReceived,
    );

    const notificationDetails = NotificationDetails(
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
    } catch (e) {
      debugPrint('Error showing local notification: $e');
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

  void dispose() {
    _onNotificationTap = null;
  }
}
