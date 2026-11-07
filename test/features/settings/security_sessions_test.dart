import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/app/providers.dart';
import 'package:vnlfsocialapp/src/core/api_client.dart';
import 'package:vnlfsocialapp/src/domain/models.dart';
import 'package:vnlfsocialapp/src/features/settings/data/live_security_sessions_repository.dart';
import 'package:vnlfsocialapp/src/features/settings/domain/security_sessions.dart';
import 'package:vnlfsocialapp/src/features/settings/presentation/security_sessions_controller.dart';
import 'package:vnlfsocialapp/src/features/settings/presentation/security_sessions_panel.dart';

void main() {
  test('confirmed revocation remains confirmed when refresh fails', () async {
    final repository = _Sessions();
    final controller = SecuritySessionsController(repository);
    await Future<void>.delayed(Duration.zero);
    repository.failReads = true;
    await controller.revoke(_Sessions.other);
    expect(repository.writes, 1);
    expect(controller.state.confirmed, isTrue);
    expect(controller.state.uncertain, isTrue);
    expect(controller.state.failed, isTrue);
    repository.failReads = false;
    await controller.refresh();
    expect(controller.state.uncertain, isFalse);
    controller.dispose();
  });

  testWidgets('account switch prevents a pending confirmation from revoking', (
    tester,
  ) async {
    final repository = _Sessions();
    final container = ProviderContainer(
      overrides: [
        sessionStateProvider.overrideWith(
          (_) => const Session(userId: 'first', displayName: 'First'),
        ),
        securitySessionsRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: SecuritySessionsPanel())),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Log out').first);
    await tester.pumpAndSettle();
    container.read(sessionStateProvider.notifier).state = const Session(
      userId: 'second',
      displayName: 'Second',
    );
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Log out'));
    await tester.pumpAndSettle();
    expect(repository.writes, 0);
  });

  testWidgets('session list reloads under the new account after a switch', (
    tester,
  ) async {
    var reads = 0;
    final client = ApiClient(
      hostKey: Object(),
      throttleInterval: Duration.zero,
      transport: (_) async {
        reads++;
        return ApiResponse(
          statusCode: 200,
          body: '{"items":[{"id":"current","current":true}]}',
        );
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
        child: const MaterialApp(home: Scaffold(body: SecuritySessionsPanel())),
      ),
    );
    await tester.pumpAndSettle();
    expect(reads, 1);
    client.invalidateSession();
    container.read(sessionStateProvider.notifier).state = const Session(
      userId: 'second',
      displayName: 'Second',
    );
    await tester.pumpAndSettle();
    expect(reads, 2);
    expect(find.text('Could not load sessions.'), findsNothing);
  });

  test(
    'requires a current session and explicit revoke acknowledgment',
    () async {
      final requests = <ApiRequest>[];
      final client = ApiClient(
        throttleInterval: Duration.zero,
        transport: (request) async {
          requests.add(request);
          return ApiResponse(
            statusCode: 200,
            body: jsonEncode(
              request.method == 'GET'
                  ? {
                      'items': [
                        {'id': 'current', 'current': true},
                        {'id': 'other', 'current': false},
                      ],
                    }
                  : {'ok': true},
            ),
          );
        },
      );
      final repository = LiveSecuritySessionsRepository(client);
      final sessions = await repository.load();
      expect(sessions.length, 2);
      await expectLater(
        repository.revoke(sessions.first),
        throwsA(isA<ParseFailure>()),
      );
      await expectLater(
        repository.revoke(sessions.last),
        throwsA(isA<ParseFailure>()),
      );
      expect(requests.where((r) => r.method == 'DELETE').length, 1);
      client.invalidateSession();
      await expectLater(
        repository.revoke(const SecuritySession(id: 'other', current: false)),
        throwsA(isA<HttpFailure>()),
      );
      expect(requests.length, 2);
    },
  );
}

final class _Sessions implements SecuritySessionsRepository {
  static const other = SecuritySession(
    id: 'other',
    current: false,
    deviceName: 'Other device',
  );
  var writes = 0;
  var failReads = false;
  @override
  Future<List<SecuritySession>> load() async {
    if (failReads) throw const TransportFailure();
    return [const SecuritySession(id: 'current', current: true), other];
  }

  @override
  Future<void> revoke(SecuritySession session) async {
    writes++;
  }

  @override
  Future<void> revokeOthers() async {
    writes++;
  }
}
