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
      expect(AndroidBackgroundService.isAndroid, isFalse);
    });

    test('starting or stopping off Android does nothing', () async {
      await const AndroidBackgroundService().start();
      await const AndroidBackgroundService().stop();
    });

    test('background notifications stay off until turned on', () async {
      final notifier = AndroidBackgroundSyncNotifier();
      await Future<void>.delayed(Duration.zero);
      expect(notifier.state, isFalse);

      await notifier.toggle(true);
      expect(notifier.state, isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('android_background_sync'), isTrue);

      await notifier.toggle(false);
      expect(notifier.state, isFalse);
      expect(prefs.getBool('android_background_sync'), isFalse);
    });

    test('a saved choice is restored', () async {
      SharedPreferences.setMockInitialValues({'android_background_sync': true});

      final notifier = AndroidBackgroundSyncNotifier();
      await Future<void>.delayed(Duration.zero);

      expect(notifier.state, isTrue);
    });
  });
}
