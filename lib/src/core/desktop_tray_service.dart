// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:io' show Directory, File, Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tray_manager/legacy.dart';
import 'package:window_manager/legacy.dart';

const String kPrefMinimizeToTray = 'desktop_minimize_to_tray';
const String kPrefAutostart = 'desktop_autostart';

final desktopMinimizeToTrayProvider =
    StateNotifierProvider<DesktopSettingNotifier, bool>((ref) {
      return DesktopSettingNotifier(kPrefMinimizeToTray, defaultValue: true);
    });

final desktopAutostartProvider =
    StateNotifierProvider<DesktopAutostartNotifier, bool>((ref) {
      return DesktopAutostartNotifier();
    });

final desktopTrayServiceProvider = Provider<DesktopTrayService>((ref) {
  final service = DesktopTrayService(ref);
  ref.onDispose(service.dispose);
  return service;
});

class DesktopSettingNotifier extends StateNotifier<bool> {
  DesktopSettingNotifier(this.key, {required bool defaultValue})
    : super(defaultValue) {
    _load();
  }

  final String key;

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = prefs.getBool(key) ?? state;
    } catch (_) {}
  }

  Future<void> toggle(bool value) async {
    state = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (_) {}
  }
}

class DesktopAutostartNotifier extends StateNotifier<bool> {
  DesktopAutostartNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = prefs.getBool(kPrefAutostart) ?? false;
    } catch (_) {}
  }

  Future<void> setAutostart(bool enabled) async {
    state = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(kPrefAutostart, enabled);
    } catch (_) {}

    if (kIsWeb) return;

    if (Platform.isLinux) {
      await _syncLinuxAutostart(enabled);
    }
  }

  Future<void> _syncLinuxAutostart(bool enabled) async {
    try {
      final home = Platform.environment['HOME'];
      if (home == null || home.isEmpty) return;

      final autostartDir = Directory('$home/.config/autostart');
      if (!autostartDir.existsSync()) {
        autostartDir.createSync(recursive: true);
      }

      final desktopFile = File('$home/.config/autostart/vnlfsocialapp.desktop');
      if (enabled) {
        final execPath = Platform.resolvedExecutable;
        final content =
            '''[Desktop Entry]
Type=Application
Name=VNLF Social
Comment=Vietnam Linux Family Desktop Client
Exec=$execPath --minimized
Icon=vnlfsocialapp
Terminal=false
Categories=Network;InstantMessaging;
X-GNOME-Autostart-enabled=true
''';
        await desktopFile.writeAsString(content);
      } else {
        if (desktopFile.existsSync()) {
          await desktopFile.delete();
        }
      }
    } catch (e) {
      debugPrint('Failed to sync Linux autostart: $e');
    }
  }
}

class DesktopTrayService with TrayListener, WindowListener {
  DesktopTrayService(this._ref);

  final Ref _ref;
  bool _initialized = false;

  static bool get isDesktop {
    if (kIsWeb) return false;
    return Platform.isLinux || Platform.isWindows || Platform.isMacOS;
  }

  Future<void> initialize() async {
    if (_initialized || !isDesktop) return;

    try {
      await windowManager.ensureInitialized();
      windowManager.addListener(this);
      await windowManager.setPreventClose(true);

      trayManager.addListener(this);
      await trayManager.setIcon(
        Platform.isWindows
            ? 'assets/images/vnlf-icon-maskable.png'
            : 'assets/images/vnlf-icon-maskable.png',
      );
      await trayManager.setToolTip('Vietnam Linux Family');

      final menu = Menu(
        items: [
          MenuItem(key: 'show_window', label: 'Mở VNLF Social'),
          MenuItem.separator(),
          MenuItem(key: 'exit_app', label: 'Thoát'),
        ],
      );
      await trayManager.setContextMenu(menu);
      _initialized = true;
    } catch (e) {
      debugPrint('Failed to initialize desktop tray/window service: $e');
    }
  }

  @override
  void onWindowClose() async {
    final minimizeToTray = _ref.read(desktopMinimizeToTrayProvider);
    if (minimizeToTray) {
      await windowManager.hide();
    } else {
      await windowManager.destroy();
    }
  }

  @override
  void onTrayIconMouseDown() async {
    await restoreWindow();
  }

  @override
  void onTrayIconRightMouseDown() async {
    await trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) async {
    if (menuItem.key == 'show_window') {
      await restoreWindow();
    } else if (menuItem.key == 'exit_app') {
      await windowManager.destroy();
    }
  }

  Future<void> restoreWindow() async {
    if (!_initialized) return;
    try {
      final isVisible = await windowManager.isVisible();
      if (!isVisible) {
        await windowManager.show();
      }
      final isMinimized = await windowManager.isMinimized();
      if (isMinimized) {
        await windowManager.restore();
      }
      await windowManager.focus();
    } catch (e) {
      debugPrint('Failed to restore window: $e');
    }
  }

  void dispose() {
    if (_initialized) {
      trayManager.removeListener(this);
      windowManager.removeListener(this);
      _initialized = false;
    }
  }
}
