import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/app/providers.dart';
import 'package:vnlfsocialapp/src/design_system/design_system.dart';
import 'package:vnlfsocialapp/src/domain/models.dart';
import 'package:vnlfsocialapp/src/features/notifications/data/local_notification_service.dart';
import 'package:vnlfsocialapp/src/features/notifications/data/push_registration.dart';
import 'package:vnlfsocialapp/src/features/notifications/domain/push_distributor.dart';
import 'package:vnlfsocialapp/src/features/notifications/domain/push_subscriptions_repository.dart';
import 'package:vnlfsocialapp/src/features/notifications/presentation/push_providers.dart';
import 'package:vnlfsocialapp/src/features/notifications/presentation/push_settings_card.dart';

const _member = Session(userId: 'me', displayName: 'Tôi');

void main() {
  late _Repository repository;
  late _Distributor distributor;
  late _Notifications notifications;

  setUp(() {
    repository = _Repository();
    distributor = _Distributor();
    notifications = _Notifications();
  });

  Future<void> pump(WidgetTester tester, {bool supported = true}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionStateProvider.overrideWith((ref) => _member),
          pushRegistrationProvider.overrideWithValue(
            supported ? PushRegistration(repository, distributor) : null,
          ),
          localNotificationServiceProvider.overrideWithValue(notifications),
        ],
        child: MaterialApp(
          theme: VnlfTheme.light(),
          home: const Scaffold(
            body: SingleChildScrollView(child: PushSettingsCard()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a device without a push service says so', (tester) async {
    await pump(tester, supported: false);
    expect(
      find.text('Thiết bị này chưa hỗ trợ thông báo đẩy.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Bật thông báo đẩy'));
    await tester.pumpAndSettle();
    expect(repository.log, isEmpty);
  });

  testWidgets('turning on registers, tests and turns off again', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.text('Bật thông báo đẩy'));
    await tester.pumpAndSettle();
    expect(repository.log, ['POST new']);
    expect(find.textContaining('Đã bật.'), findsOneWidget);

    await tester.tap(find.text('Gửi thông báo thử'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Đã gửi thông báo thử.'), findsOneWidget);

    await tester.tap(find.text('Tắt thông báo đẩy'));
    await tester.pumpAndSettle();
    expect(repository.log, ['POST new', 'DELETE new']);
    expect(find.text('Đã tắt thông báo đẩy.'), findsOneWidget);
    expect(find.text('Gửi thông báo thử'), findsNothing);
  });

  testWidgets('the reasons a turn-on fails are told apart', (tester) async {
    await pump(tester);
    notifications.granted = false;
    await tester.tap(find.text('Bật thông báo đẩy'));
    await tester.pumpAndSettle();
    expect(repository.log, isEmpty);
    expect(find.textContaining('chưa được phép gửi thông báo'), findsOneWidget);

    notifications.granted = true;
    distributor.failure = const PushDistributorUnavailable();
    await tester.tap(find.text('Bật thông báo đẩy'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Chưa có ứng dụng nhận thông báo đẩy.'),
      findsOneWidget,
    );

    distributor.failure = null;
    repository.failPost = true;
    await tester.tap(find.text('Bật thông báo đẩy'));
    await tester.pumpAndSettle();
    // Until the server accepts distributor endpoints.
    expect(
      find.textContaining(
        'Máy chủ VNLF chưa nhận thông báo đẩy qua UnifiedPush.',
      ),
      findsOneWidget,
    );
    expect(find.text('Bật thông báo đẩy'), findsOneWidget);
  });

  testWidgets('a server without push leaves the button off', (tester) async {
    repository.enabled = false;
    await pump(tester);
    expect(find.text('Máy chủ chưa bật thông báo đẩy.'), findsOneWidget);
    await tester.tap(find.text('Bật thông báo đẩy'));
    await tester.pumpAndSettle();
    expect(distributor.log, isEmpty);
  });
}

final class _Repository implements PushSubscriptionsRepository {
  bool enabled = true;
  bool failPost = false;
  final saved = <String>[];
  final log = <String>[];

  @override
  Future<PushServerConfig> config() async =>
      PushServerConfig(enabled: enabled, publicKey: enabled ? 'key' : '');

  @override
  Future<List<String>> endpoints() async => saved;

  @override
  Future<void> addSubscription(WebPushSubscription subscription) async {
    log.add('POST ${subscription.endpoint}');
    if (failPost) throw const HttpFailure(400, code: 'PUSH_ENDPOINT_INVALID');
    saved.add(subscription.endpoint);
  }

  @override
  Future<void> removeSubscription(String endpoint) async {
    log.add('DELETE $endpoint');
    saved.remove(endpoint);
  }
}

final class _Distributor implements PushDistributor {
  HeldPushSubscription? held;
  Exception? failure;
  final log = <String>[];

  @override
  Future<HeldPushSubscription?> current() async => held;

  @override
  Future<WebPushSubscription> subscribe(String serverKey) async {
    log.add('subscribe $serverKey');
    if (failure case final failure?) throw failure;
    const subscription = WebPushSubscription(
      endpoint: 'new',
      p256dh: 'BKey',
      auth: 'secret',
    );
    held = (subscription: subscription, serverKey: serverKey);
    return subscription;
  }

  @override
  Future<void> unsubscribe() async {
    log.add('unsubscribe');
    held = null;
  }
}

class _Notifications extends LocalNotificationService {
  bool granted = true;

  @override
  Future<bool> requestPermission() async => granted;
}
