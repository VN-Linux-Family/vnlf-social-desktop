import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/app/providers.dart';
import 'package:vnlfsocialapp/src/core/api_client.dart';
import 'package:vnlfsocialapp/src/domain/models.dart';
import 'package:vnlfsocialapp/src/features/settings/blocked/data/live_blocked_people_repository.dart';
import 'package:vnlfsocialapp/src/features/settings/blocked/domain/blocked_people.dart';
import 'package:vnlfsocialapp/src/features/settings/blocked/presentation/blocked_people_controller.dart';
import 'package:vnlfsocialapp/src/features/settings/blocked/presentation/blocked_people_panel.dart';

void main() {
  testWidgets('account switch hides the previous blocked list', (tester) async {
    var calls = 0;
    final next = Completer<ApiResponse>();
    final client = ApiClient(
      hostKey: Object(),
      throttleInterval: Duration.zero,
      transport: (_) async {
        calls++;
        if (calls == 1) {
          return ApiResponse(
            statusCode: 200,
            body: '{"items":[{"id":"one","username":"one","displayName":"First list"}]}',
          );
        }
        return next.future;
      },
    );
    final container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWithValue(client),
        sessionStateProvider.overrideWith(
          (_) => const Session(userId: 'first', displayName: 'First'),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: BlockedPeoplePanel())),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('First list'), findsOneWidget);
    client.invalidateSession();
    container.read(sessionStateProvider.notifier).state = const Session(
      userId: 'second',
      displayName: 'Second',
    );
    await tester.pump();
    expect(find.text('First list'), findsNothing);
    next.complete(
      ApiResponse(
        statusCode: 200,
        body: '{"items":[{"id":"two","username":"two","displayName":"Second list"}]}',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Second list'), findsOneWidget);
  });

  testWidgets(
    'confirmed unblock is not described as unconfirmed when refresh fails',
    (tester) async {
      final repository = _Repository()..failRefresh = true;
      var invalidations = 0;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            blockedPeopleControllerProvider.overrideWith(
              (_) => BlockedPeopleController(
                repository,
                onPossibleChange: (_) => invalidations++,
              ),
            ),
          ],
          child: const MaterialApp(home: Scaffold(body: BlockedPeoplePanel())),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Unblock'));
      repository.write.complete();
      await tester.pumpAndSettle();
      expect(invalidations, 1);
      expect(find.text('Unblocked Target.'), findsOneWidget);
      expect(
        find.text(
          'Unblock was confirmed, but the list could not be refreshed.',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'The result could not be confirmed. Refresh before trying again.',
        ),
        findsNothing,
      );
    },
  );

  test(
    'repository validates acknowledgement and never retries a write',
    () async {
      var calls = 0;
      final client = ApiClient(
        hostKey: Object(),
        throttleInterval: Duration.zero,
        transport: (request) async {
          calls++;
          expect(request.path, '/api/v1/users/a%2Fb/block');
          expect(request.method, 'DELETE');
          return ApiResponse(statusCode: 200, body: '{}');
        },
      );
      final repository = LiveBlockedPeopleRepository(
        client,
        'owner',
        () => 'owner',
      );
      await expectLater(
        repository.unblock('a/b'),
        throwsA(isA<ParseFailure>()),
      );
      expect(calls, 1);
    },
  );

  test('repository rejects identity changes and malformed list', () async {
    var owner = 'owner';
    final client = ApiClient(
      hostKey: Object(),
      throttleInterval: Duration.zero,
      transport: (_) async => ApiResponse(
        statusCode: 200,
        body: '{"items":[{"id":"x"},{"id":"x"}]}',
      ),
    );
    final repository = LiveBlockedPeopleRepository(client, owner, () => owner);
    await expectLater(repository.load(), throwsA(isA<ParseFailure>()));
    owner = 'other';
    await expectLater(repository.unblock('x'), throwsA(isA<HttpFailure>()));
    owner = 'owner';
    client.invalidateSession();
    await expectLater(repository.load(), throwsA(isA<HttpFailure>()));
  });

  test('only an explicit ok acknowledges unblock', () async {
    final client = ApiClient(
      hostKey: Object(),
      throttleInterval: Duration.zero,
      transport: (_) async => ApiResponse(
        statusCode: 200,
        body: '{"ok":true,"viewerState":"REQUEST_REQUIRED"}',
      ),
    );
    final repository = LiveBlockedPeopleRepository(
      client,
      'owner',
      () => 'owner',
    );
    await repository.unblock('target');
  });

  test('in-flight list is rejected after account changes', () async {
    var owner = 'owner';
    final response = Completer<ApiResponse>();
    final client = ApiClient(
      hostKey: Object(),
      throttleInterval: Duration.zero,
      transport: (_) => response.future,
    );
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

  test(
    'failed refresh after uncertain write prevents further writes',
    () async {
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
    },
  );
}

final class _Repository implements BlockedPeopleRepository {
  final person = const BlockedPerson(
    id: 'target',
    username: 'target',
    displayName: 'Target',
  );
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
  Future<void> unblock(String id) {
    writes++;
    return write.future;
  }
}
