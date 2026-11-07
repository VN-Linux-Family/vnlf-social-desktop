import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vnlfsocialapp/src/core/desktop_tray_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test(
    'desktop setting notifier toggles and persists minimizeToTray',
    () async {
      final notifier = DesktopSettingNotifier(
        kPrefMinimizeToTray,
        defaultValue: true,
      );
      expect(notifier.state, isTrue);

      await notifier.toggle(false);
      expect(notifier.state, isFalse);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(kPrefMinimizeToTray), isFalse);

      await notifier.toggle(true);
      expect(notifier.state, isTrue);
      expect(prefs.getBool(kPrefMinimizeToTray), isTrue);
    },
  );

  test('desktop autostart notifier toggles and persists autostart', () async {
    final notifier = DesktopAutostartNotifier();
    expect(notifier.state, isFalse);

    await notifier.setAutostart(true);
    expect(notifier.state, isTrue);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(kPrefAutostart), isTrue);

    await notifier.setAutostart(false);
    expect(notifier.state, isFalse);
    expect(prefs.getBool(kPrefAutostart), isFalse);
  });
}
