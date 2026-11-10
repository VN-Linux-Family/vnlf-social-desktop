import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/core/session_storage_contract.dart';
import 'package:vnlfsocialapp/src/features/notifications/data/unified_push_distributor.dart';
import 'package:vnlfsocialapp/src/features/notifications/domain/push_distributor.dart';

void main() {
  late _Connector connector;
  late _Storage storage;
  late UnifiedPushDistributor distributor;

  setUp(() {
    connector = _Connector();
    storage = _Storage();
    distributor = UnifiedPushDistributor(connector, storage);
  });

  test('without a distributor app there is nothing to subscribe', () async {
    connector.hasDistributor = false;
    await expectLater(
      distributor.subscribe('vapid'),
      throwsA(isA<PushDistributorUnavailable>()),
    );
    expect(connector.log, isEmpty);
  });

  test('the endpoint the distributor answers with is kept', () async {
    final subscription = distributor.subscribe('vapid');
    await pumpEventQueue();
    expect(connector.log, ['register vapid']);
    await distributor.endpointChanged((
      url: 'https://push.example/a',
      p256dh: 'BKey',
      auth: 'secret',
    ));
    final made = await subscription;
    expect(made.toJson(), {
      'endpoint': 'https://push.example/a',
      'keys': {'p256dh': 'BKey', 'auth': 'secret'},
    });
    final held = await distributor.current();
    expect(held?.serverKey, 'vapid');
    expect(held?.subscription.endpoint, 'https://push.example/a');
  });

  test('an endpoint without keys cannot take Web Push', () async {
    final failed = expectLater(
      distributor.subscribe('vapid'),
      throwsA(isA<PushDistributorUnavailable>()),
    );
    await pumpEventQueue();
    await distributor.endpointChanged((
      url: 'https://push.example/a',
      p256dh: null,
      auth: null,
    ));
    await failed;
    expect(await distributor.current(), isNull);
  });

  test('a refusal carries the distributor\'s reason', () async {
    final subscription = distributor.subscribe('vapid');
    await pumpEventQueue();
    distributor.registrationFailed('network');
    await expectLater(
      subscription,
      throwsA(
        isA<PushRegistrationRefused>().having(
          (refusal) => refusal.reason,
          'reason',
          'network',
        ),
      ),
    );
  });

  test('a distributor that never answers times out', () async {
    distributor = UnifiedPushDistributor(
      connector,
      storage,
      answerTimeout: const Duration(milliseconds: 10),
    );
    await expectLater(
      distributor.subscribe('vapid'),
      throwsA(isA<PushDistributorUnavailable>()),
    );
  });

  test('a replaced endpoint is remembered until it is registered', () async {
    final subscription = distributor.subscribe('vapid');
    await pumpEventQueue();
    await distributor.endpointChanged((
      url: 'https://push.example/a',
      p256dh: 'BKey',
      auth: 'secret',
    ));
    await subscription;
    var replaced = 0;
    distributor.onReplaced = () => replaced++;

    await distributor.endpointChanged((
      url: 'https://push.example/b',
      p256dh: 'BKey2',
      auth: 'secret2',
    ));
    await distributor.endpointChanged((
      url: 'https://push.example/c',
      p256dh: 'BKey3',
      auth: 'secret3',
    ));
    // The server still has the first endpoint.
    expect(await distributor.replacedEndpoint(), 'https://push.example/a');
    expect(
      (await distributor.current())?.subscription.endpoint,
      'https://push.example/c',
    );
    expect(replaced, 2);
    await distributor.forgetReplacedEndpoint();
    expect(await distributor.replacedEndpoint(), isNull);
  });

  test('unregistering forgets the subscription', () async {
    final subscription = distributor.subscribe('vapid');
    await pumpEventQueue();
    await distributor.endpointChanged((
      url: 'https://push.example/a',
      p256dh: 'BKey',
      auth: 'secret',
    ));
    await subscription;
    await distributor.unsubscribe();
    expect(connector.log, ['register vapid', 'unregister']);
    expect(await distributor.current(), isNull);

    storage.data[UnifiedPushDistributor.storageKey] = 'not json';
    expect(await distributor.current(), isNull);
    expect(storage.data, isEmpty);
  });
}

final class _Connector implements UnifiedPushConnector {
  bool hasDistributor = true;
  final log = <String>[];

  @override
  Future<bool> useDefaultDistributor() async => hasDistributor;

  @override
  Future<void> register({required String vapid}) async =>
      log.add('register $vapid');

  @override
  Future<void> unregister() async => log.add('unregister');
}

final class _Storage implements SessionStorage {
  final data = <String, String>{};

  @override
  Future<String?> read(String key) async => data[key];

  @override
  Future<void> write(String key, String value) async => data[key] = value;

  @override
  Future<void> delete(String key) async => data.remove(key);
}
