import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vnlfsocialapp/src/core/android_background_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AndroidBackgroundService', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('isAndroid returns false on host test runner', () {
      // In host VM flutter test, Platform.isAndroid is false (running on Linux VM)
      expect(AndroidBackgroundService.isAndroid, isFalse);
    });

    test('notifier initializes with default true and toggles', () async {
      final notifier = AndroidBackgroundSyncNotifier();
      expect(notifier.state, isTrue);

      await notifier.toggle(false);
      expect(notifier.state, isFalse);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('android_background_sync'), isFalse);

      await notifier.toggle(true);
      expect(notifier.state, isTrue);
      expect(prefs.getBool('android_background_sync'), isTrue);
    });
  });
}
