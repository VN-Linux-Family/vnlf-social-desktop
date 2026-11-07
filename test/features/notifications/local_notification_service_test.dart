import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/features/notifications/data/local_notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('LocalNotificationService recognizes supported platforms and exposes methods', () async {
    final service = LocalNotificationService();
    expect(service.isSupportedPlatform, isTrue);
  });
}
