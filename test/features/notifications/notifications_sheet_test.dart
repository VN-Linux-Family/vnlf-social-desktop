import 'package:flutter/material.dart';

import 'dart:convert';

import 'package:vnlfsocialapp/src/domain/models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vnlfsocialapp/src/app/providers.dart';
import 'package:vnlfsocialapp/src/core/api_client.dart';
import 'package:vnlfsocialapp/src/features/notifications/presentation/notifications_sheet.dart';

void main() {
  for (final example in [
    ('FEEDBACK', 'ticket-1', '/feedback/ticket-1', 'ticket'),
    (
      'CONVERSATION',
      'conversation-1',
      '/messages/conversation-1',
      'conversation',
    ),
    ('PROJECT', 'project-1', '/projects/community-tool', 'project'),
    ('GUESTBOOK', 'owner-1', '/u/synthetic?tab=guestbook', 'guestbook'),
  ]) {
    testWidgets('notification opens the native ${example.$4} route', (
      tester,
    ) async {
      final client = ApiClient(
        hostKey: Object(),
        throttleInterval: Duration.zero,
        transport: (request) async {
          final payload = request.method == 'GET'
              ? {
                  'items': [
                    {
                      'id': 'notice',
                      'type': 'update',
                      'targetType': example.$1,
                      'targetId': example.$2,
                      'href': example.$3,
                      'targetSummary': {'title': 'Notice target'},
                      'actors': <Object?>[],
                      'readAt': '2026-01-01T00:00:00Z',
                    },
                  ],
                  'nextCursor': null,
                }
              : {'ok': true};
          return ApiResponse(statusCode: 200, body: jsonEncode(payload));
        },
      );
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, _) => Scaffold(
              body: TextButton(
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  builder: (_) => const NotificationsSheet(),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
          GoRoute(
            path: '/feedback/:id',
            builder: (_, _) => const Scaffold(body: Text('ticket')),
          ),
          GoRoute(
            path: '/messages/:id',
            builder: (_, _) => const Scaffold(body: Text('conversation')),
          ),
          GoRoute(
            path: '/projects/:slug',
            builder: (_, _) => const Scaffold(body: Text('project')),
          ),
          GoRoute(
            path: '/profile/:id',
            builder: (_, state) => Scaffold(
              body: Text(state.uri.queryParameters['tab'] ?? 'profile'),
            ),
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
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Notice target'));
      await tester.pumpAndSettle();
      expect(find.text(example.$4), findsOneWidget);
    });
  }

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
