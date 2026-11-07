import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/core/api_client.dart';
import 'package:vnlfsocialapp/src/features/settings/domain/account_profile.dart';
import 'package:vnlfsocialapp/src/features/settings/domain/account_profile_repository.dart';
import 'package:vnlfsocialapp/src/features/settings/presentation/account_profile_controller.dart';

const _server = AccountProfile(username: 'minh', displayName: 'Minh');

final class _FakeRepository implements AccountProfileRepository {
  AccountProfile profile = _server;
  Object? saveError;
  Completer<void>? saveGate;
  final saved = <ProfilePatch>[];
  final loads = <String>[];
  Object? loadError;

  @override
  Future<AccountProfile> load(String username) async {
    loads.add(username);
    final error = loadError;
    if (error != null) throw error;
    return profile;
  }

  @override
  Future<void> save(ProfilePatch patch) async {
    saved.add(patch);
    await saveGate?.future;
    final error = saveError;
    if (error != null) throw error;
    profile = profile.apply(patch);
  }
}

Future<AccountProfileController> _ready(
  _FakeRepository repo, {
  void Function()? onSaved,
}) async {
  final controller = AccountProfileController(repo, 'minh', onSaved: onSaved);
  await Future<void>.delayed(Duration.zero);
  return controller;
}

AccountProfileEditing _editing(AccountProfileController c) =>
    c.state as AccountProfileEditing;

void main() {
  test('load failure is typed and retryable', () async {
    final repo = _FakeRepository()..loadError = const TransportFailure();
    final controller = await _ready(repo);
    expect(controller.state, isA<AccountProfileLoadFailed>());
    repo.loadError = null;
    await controller.load();
    expect(controller.state, isA<AccountProfileEditing>());
  });

  test('a signed-out controller never calls the server', () async {
    final repo = _FakeRepository();
    final controller = AccountProfileController(repo, '');
    await Future<void>.delayed(Duration.zero);
    expect(
      (controller.state as AccountProfileLoadFailed).failure,
      isA<HttpFailure>(),
    );
    expect(repo.loads, isEmpty);
  });

  test('invalid input is reported without a request', () async {
    final repo = _FakeRepository();
    final controller = await _ready(repo);
    await controller.submit(
      const AccountProfile(username: 'x', displayName: 'Minh'),
    );
    expect(_editing(controller).errors, {
      ProfileField.username: ProfileFieldError.tooShort,
    });
    expect(repo.saved, isEmpty);
  });

  test('an unchanged form sends nothing', () async {
    final repo = _FakeRepository();
    final controller = await _ready(repo);
    await controller.submit(_server);
    expect(repo.saved, isEmpty);
    expect(_editing(controller).saved, isFalse);
  });

  test('a successful save is confirmed from the server and notifies', () async {
    final repo = _FakeRepository();
    var notified = 0;
    final controller = await _ready(repo, onSaved: () => notified++);
    await controller.submit(
      const AccountProfile(username: 'minh2', displayName: 'Minh'),
    );
    expect(repo.saved.single.fields, {ProfileField.username: 'minh2'});
    expect(repo.loads.last, 'minh2');
    expect(_editing(controller).saved, isTrue);
    expect(_editing(controller).profile.username, 'minh2');
    expect(notified, 1);
  });

  test('a second submit while saving is ignored', () async {
    final repo = _FakeRepository()..saveGate = Completer<void>();
    final controller = await _ready(repo);
    const draft = AccountProfile(username: 'minh', displayName: 'Mới');
    final first = controller.submit(draft);
    await controller.submit(draft);
    repo.saveGate!.complete();
    await first;
    expect(repo.saved, hasLength(1));
  });

  test('a definite rejection keeps the form and allows another save', () async {
    final repo = _FakeRepository()
      ..saveError = const HttpFailure(409, code: 'USERNAME_TAKEN');
    final controller = await _ready(repo);
    await controller.submit(
      const AccountProfile(username: 'taken', displayName: 'Minh'),
    );
    final state = _editing(controller);
    expect(state.failure, isA<HttpFailure>());
    expect(state.outcomeUnknown, isFalse);
    expect(state.profile, _server);
  });

  test(
    'an unclear failure is verified by reading, never by resending',
    () async {
      final repo = _FakeRepository()..saveError = const TransportFailure();
      final controller = await _ready(repo);
      await controller.submit(
        const AccountProfile(username: 'minh', displayName: 'Mới'),
      );
      expect(_editing(controller).outcomeUnknown, isTrue);

      // The server did apply the write before the connection dropped.
      repo.profile = const AccountProfile(username: 'minh', displayName: 'Mới');
      await controller.verifyAfterUncertainWrite();
      expect(repo.saved, hasLength(1));
      final state = _editing(controller);
      expect(state.outcomeUnknown, isFalse);
      expect(state.saved, isTrue);
      expect(state.profile.displayName, 'Mới');
    },
  );

  test('verification that finds no change does not claim success', () async {
    final repo = _FakeRepository()..saveError = const HttpFailure(503);
    final controller = await _ready(repo);
    await controller.submit(
      const AccountProfile(username: 'minh', displayName: 'Mới'),
    );
    await controller.verifyAfterUncertainWrite();
    final state = _editing(controller);
    expect(state.saved, isFalse);
    expect(state.profile, _server);
  });

  test('a result arriving after disposal is discarded', () async {
    final repo = _FakeRepository()..saveGate = Completer<void>();
    var notified = 0;
    final controller = await _ready(repo, onSaved: () => notified++);
    final pending = controller.submit(
      const AccountProfile(username: 'minh', displayName: 'Mới'),
    );
    controller.dispose();
    repo.saveGate!.complete();
    await pending;
    expect(notified, 0);
  });
}
