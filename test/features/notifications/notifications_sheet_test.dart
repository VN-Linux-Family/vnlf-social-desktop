import 'package:flutter/material.dart';
import 'package:vnlfsocialapp/src/domain/models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vnlfsocialapp/src/app/providers.dart';
import 'package:vnlfsocialapp/src/core/api_client.dart';
import 'package:vnlfsocialapp/src/features/notifications/presentation/notifications_sheet.dart';

void main() {
  testWidgets('notification category selection requests the server filter', (
    tester,
  ) async {
    final requests = <ApiRequest>[];
    final client = ApiClient(
      hostKey: Object(),
      throttleInterval: Duration.zero,
      transport: (request) async {
        requests.add(request);
        return ApiResponse(
          statusCode: 200,
          body: request.method == 'GET'
              ? '{"items":[],"nextCursor":null}'
              : '{"ok":true}',
        );
      },
    );
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: NotificationsSheet()),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionStateProvider.overrideWith(
            (_) => const Session(
              userId: 'owner',
              displayName: 'Owner',
              role: 'MEMBER',
            ),
          ),
          apiClientProvider.overrideWithValue(client),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('All types'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Comments').last);
    await tester.pumpAndSettle();
    expect(
      requests.where((r) => r.method == 'GET').last.query['kind'],
      'comment',
    );
  });

  testWidgets('signed-out sheet offers login and makes no private requests', (
    tester,
  ) async {
    var calls = 0;
    final client = ApiClient(
      hostKey: Object(),
      transport: (_) async {
        calls++;
        return ApiResponse(statusCode: 200, body: '{}');
      },
    );
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: NotificationsSheet()),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionStateProvider.overrideWith((ref) => null),
          apiClientProvider.overrideWithValue(client),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Sign in to view notifications'), findsOneWidget);
    expect(find.textContaining('Welcome'), findsNothing);
    expect(calls, 0);
  });
}
