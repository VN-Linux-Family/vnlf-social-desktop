import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/core/api_client.dart';
import 'package:vnlfsocialapp/src/features/settings/blocked/data/live_blocked_people_repository.dart';
import 'package:vnlfsocialapp/src/features/settings/blocked/domain/blocked_people.dart';
import 'package:vnlfsocialapp/src/features/settings/blocked/presentation/blocked_people_controller.dart';

void main() {
  test('repository validates acknowledgement and never retries a write', () async {
    var calls = 0;
    final client = ApiClient(hostKey: Object(), throttleInterval: Duration.zero, transport: (request) async {
      calls++;
      expect(request.path, '/api/v1/users/a%2Fb/block');
      expect(request.method, 'DELETE');
      return ApiResponse(statusCode: 200, body: '{}');
    });
    final repository = LiveBlockedPeopleRepository(client, 'owner', () => 'owner');
    await expectLater(repository.unblock('a/b'), throwsA(isA<ParseFailure>()));
    expect(calls, 1);
  });

  test('repository rejects identity changes and malformed list', () async {
    var owner = 'owner';
    final client = ApiClient(hostKey: Object(), throttleInterval: Duration.zero, transport: (_) async => ApiResponse(statusCode: 200, body: '{"items":[{"id":"x"},{"id":"x"}]}'));
    final repository = LiveBlockedPeopleRepository(client, owner, () => owner);
    await expectLater(repository.load(), throwsA(isA<ParseFailure>()));
    owner = 'other';
    await expectLater(repository.unblock('x'), throwsA(isA<HttpFailure>()));
    owner = 'owner';
    client.invalidateSession();
    await expectLater(repository.load(), throwsA(isA<HttpFailure>()));
  });

  test('only an explicit ok acknowledges unblock', () async {
    final client = ApiClient(hostKey: Object(), throttleInterval: Duration.zero, transport: (_) async => ApiResponse(statusCode: 200, body: '{"ok":true,"viewerState":"REQUEST_REQUIRED"}'));
    final repository = LiveBlockedPeopleRepository(client, 'owner', () => 'owner');
    await repository.unblock('target');
  });

  test('in-flight list is rejected after account changes', () async {
    var owner = 'owner';
    final response = Completer<ApiResponse>();
    final client = ApiClient(hostKey: Object(), throttleInterval: Duration.zero, transport: (_) => response.future);
    final repository = LiveBlockedPeopleRepository(client, owner, () => owner);
    final pending = repository.load();
    await Future<void>.delayed(Duration.zero);
    owner = 'other';
    response.complete(ApiResponse(statusCode: 200, body: '{"items":[]}'));
    await expectLater(pending, throwsA(isA<HttpFailure>()));
  });

  test('uncertain write refreshes and blocks duplicate submissions', () async {
    final repository = _Repository();
    final controller = BlockedPeopleController(repository);
    await Future<void>.delayed(Duration.zero);
    final first = controller.unblock(repository.person);
    await controller.unblock(repository.person);
    expect(repository.writes, 1);
    repository.write.completeError(const TransportFailure());
    await first;
    expect(repository.loads, 2);
    expect(controller.state.items, isEmpty);
    expect(controller.state.confirmedName, isNull);
    controller.dispose();
  });

  test('failed refresh after uncertain write prevents further writes', () async {
    final repository = _Repository()..failRefresh = true;
    final controller = BlockedPeopleController(repository);
    await Future<void>.delayed(Duration.zero);
    final first = controller.unblock(repository.person);
    repository.write.completeError(const TransportFailure());
    await first;
    expect(controller.state.uncertain, isTrue);
    expect(controller.state.failed, isTrue);
    await controller.unblock(repository.person);
    expect(repository.writes, 1);
    controller.dispose();
  });
}

final class _Repository implements BlockedPeopleRepository {
  final person = const BlockedPerson(id: 'target', username: 'target', displayName: 'Target');
  final write = Completer<void>();
  int writes = 0;
  int loads = 0;
  bool failRefresh = false;
  @override
  Future<List<BlockedPerson>> load() async {
    loads++;
    if (loads > 1 && failRefresh) throw const TransportFailure();
    return loads == 1 ? [person] : [];
  }
  @override
  Future<void> unblock(String id) { writes++; return write.future; }
}
