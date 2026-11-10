import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/domain/models.dart';
import 'package:vnlfsocialapp/src/features/notifications/data/push_registration.dart';
import 'package:vnlfsocialapp/src/features/notifications/domain/push_distributor.dart';
import 'package:vnlfsocialapp/src/features/notifications/domain/push_subscriptions_repository.dart';

const _config = PushServerConfig(enabled: true, publicKey: 'key-2');

WebPushSubscription _subscription(String endpoint) => WebPushSubscription(
  endpoint: endpoint,
  p256dh: 'p256dh-$endpoint',
  auth: 'auth-$endpoint',
);

void main() {
  late _Repository repository;
  late _Distributor distributor;
  late PushRegistration registration;

  setUp(() {
    repository = _Repository();
    distributor = _Distributor();
    registration = PushRegistration(repository, distributor);
  });

  test(
    'is on only for a registered subscription made for the current key',
    () async {
      distributor.held = (subscription: _subscription('a'), serverKey: 'key-2');
      expect((await registration.load()).enabled, isFalse);
      repository.saved = ['a'];
      expect((await registration.load()).enabled, isTrue);
      distributor.held = (subscription: _subscription('a'), serverKey: 'key-1');
      expect((await registration.load()).enabled, isFalse);
    },
  );

  test('reuses a subscription made for the current key', () async {
    distributor.held = (subscription: _subscription('a'), serverKey: 'key-2');
    await registration.enable(_config);
    expect(distributor.log, isEmpty);
    expect(repository.log, ['POST a']);
  });

  test('replaces a subscription made for an older key', () async {
    distributor.held = (subscription: _subscription('old'), serverKey: 'key-1');
    repository.failDelete = true;
    await registration.enable(_config);
    expect(distributor.log, ['unsubscribe', 'subscribe key-2']);
    expect(repository.log, ['DELETE old', 'POST new']);
  });

  test(
    'a refused registration drops the new subscription and is not retried',
    () async {
      repository.failPost = true;
      await expectLater(
        registration.enable(_config),
        throwsA(isA<HttpFailure>()),
      );
      expect(distributor.log, ['subscribe key-2', 'unsubscribe']);
      expect(repository.log, ['POST new']);
    },
  );

  test('turning off deletes the endpoint, then the subscription', () async {
    distributor.held = (subscription: _subscription('a'), serverKey: 'key-2');
    await registration.disable();
    expect(repository.log, ['DELETE a']);
    expect(distributor.log, ['unsubscribe']);
  });

  test('a replaced endpoint is registered, then the old one deleted', () async {
    distributor.held = (subscription: _subscription('b'), serverKey: 'key-2');
    repository.failDelete = true;
    await registration.replace('a');
    expect(repository.log, ['POST b', 'DELETE a']);
    await registration.replace('b');
    expect(repository.log, ['POST b', 'DELETE a', 'POST b']);
  });

  test('a server without push cannot be turned on', () async {
    await expectLater(
      registration.enable(
        const PushServerConfig(enabled: false, publicKey: ''),
      ),
      throwsArgumentError,
    );
    expect(distributor.log, isEmpty);
  });
}

final class _Repository implements PushSubscriptionsRepository {
  List<String> saved = [];
  bool failPost = false;
  bool failDelete = false;
  final log = <String>[];

  @override
  Future<PushServerConfig> config() async => _config;

  @override
  Future<List<String>> endpoints() async => saved;

  @override
  Future<void> addSubscription(WebPushSubscription subscription) async {
    log.add('POST ${subscription.endpoint}');
    if (failPost) {
      throw const HttpFailure(400, code: 'PUSH_ENDPOINT_INVALID');
    }
  }

  @override
  Future<void> removeSubscription(String endpoint) async {
    log.add('DELETE $endpoint');
    if (failDelete) throw const TransportFailure();
  }
}

final class _Distributor implements PushDistributor {
  HeldPushSubscription? held;
  final log = <String>[];

  @override
  Future<HeldPushSubscription?> current() async => held;

  @override
  Future<WebPushSubscription> subscribe(String serverKey) async {
    log.add('subscribe $serverKey');
    final subscription = _subscription('new');
    held = (subscription: subscription, serverKey: serverKey);
    return subscription;
  }

  @override
  Future<void> unsubscribe() async {
    log.add('unsubscribe');
    held = null;
  }
}
