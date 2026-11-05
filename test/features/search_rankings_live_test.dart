import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vnlfsocialapp/src/app/providers.dart';
import 'package:vnlfsocialapp/src/core/api_client.dart';
import 'package:vnlfsocialapp/src/data/fixture_repositories.dart';
import 'package:vnlfsocialapp/src/design_system/design_system.dart';
import 'package:vnlfsocialapp/src/features/leaderboard/presentation/leaderboard_screen.dart';
import 'package:vnlfsocialapp/src/features/leaderboard/presentation/leaderboard_providers.dart';
import 'package:vnlfsocialapp/src/features/leaderboard/data/live_weekly_leaderboard_repository.dart';
import 'package:vnlfsocialapp/src/features/search/presentation/search_screen.dart';
import 'package:vnlfsocialapp/src/features/search/presentation/search_providers.dart';
import 'package:vnlfsocialapp/src/features/search/data/live_search_repository.dart';

void main() {
  testWidgets('search finds a server article absent from loaded feed', (
    tester,
  ) async {
    final requests = <ApiRequest>[];
    final client = ApiClient(
      hostKey: Object(),
      throttleInterval: Duration.zero,
      transport: (request) async {
        requests.add(request);
        if (request.path == '/api/v1/search') {
          return ApiResponse(
            statusCode: 200,
            body: jsonEncode({
              'articles': [
                {
                  'id': 'remote-article',
                  'slug': 'remote-article',
                  'title': 'Remote server article',
                  'excerpt': 'Only the server knows this result',
                  'authorId': 'remote-user',
                  'username': 'remote',
                  'displayName': 'Thành viên từ máy chủ',
                  'format': 'ARTICLE',
                },
              ],
              'users': <Object?>[],
              'projects': <Object?>[],
              'tags': <Object?>[],
              'hasMore': {
                'articles': true,
                'users': false,
                'projects': false,
                'tags': false,
              },
            }),
          );
        }
        return fixtureTransport(request);
      },
    );
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: SearchScreen()),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(client),
          searchRepositoryProvider.overrideWithValue(
            LiveSearchRepository(client),
          ),
        ],
        child: MaterialApp.router(
          theme: VnlfTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.enterText(find.byKey(const Key('search-input')), 'remote');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.text('Remote server article'), findsOneWidget);
    expect(
      requests
          .where((request) => request.path == '/api/v1/search')
          .single
          .query,
      {'q': 'remote'},
    );
  });

  testWidgets('leaderboard offers weekly history used by website', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: VnlfTheme.light(),
          home: const Scaffold(body: LeaderboardScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byTooltip('Previous week'), findsOneWidget);
    expect(find.text('This month'), findsNothing);
  });
  testWidgets(
    'typing is debounced and older responses cannot replace latest query',
    (tester) async {
      final oldResponse = Completer<ApiResponse>();
      final queries = <String>[];
      final client = ApiClient(
        hostKey: Object(),
        throttleInterval: Duration.zero,
        transport: (request) async {
          if (request.path == '/api/v1/tags/suggest') {
            return ApiResponse(statusCode: 200, body: '{"items":[]}');
          }
          queries.add(request.query['q']!);
          if (request.query['q'] == 'old') return oldResponse.future;
          return searchResponse('Newest result');
        },
      );
      await pumpSearch(tester, client);
      await tester.enterText(find.byKey(const Key('search-input')), 'o');
      await tester.pump(const Duration(milliseconds: 400));
      expect(queries, isEmpty);
      await tester.enterText(find.byKey(const Key('search-input')), 'old');
      await tester.pump(const Duration(milliseconds: 299));
      expect(queries, isEmpty);
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump();
      expect(queries, ['old']);
      await tester.enterText(find.byKey(const Key('search-input')), 'new');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(find.text('Newest result'), findsOneWidget);
      oldResponse.complete(searchResponse('Obsolete result'));
      await tester.pumpAndSettle();
      expect(find.text('Newest result'), findsOneWidget);
      expect(find.text('Obsolete result'), findsNothing);
      await tester.tap(find.byTooltip('Clear search'));
      await tester.pumpAndSettle();
      expect(find.text('Newest result'), findsNothing);
      expect(queries, ['old', 'new']);
    },
  );

  testWidgets(
    'search errors retry only the requested query and show capped notices',
    (tester) async {
      var searches = 0;
      final client = ApiClient(
        hostKey: Object(),
        throttleInterval: Duration.zero,
        transport: (request) async {
          if (request.path == '/api/v1/tags/suggest') {
            return ApiResponse(statusCode: 200, body: '{"items":[]}');
          }
          searches++;
          if (searches == 1) return ApiResponse(statusCode: 422, body: '{}');
          return searchResponse('Recovered result', hasMore: true);
        },
      );
      await pumpSearch(tester, client);
      await tester.enterText(find.byKey(const Key('search-input')), 'linux');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(find.text('Recovered result'), findsNothing);
      expect(searches, 1);
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.text('Recovered result'), findsOneWidget);
      expect(find.text('1+ results'), findsOneWidget);
      expect(find.textContaining('Showing the first matches'), findsOneWidget);
      await tester.tap(find.widgetWithText(ChoiceChip, 'Users'));
      await tester.pumpAndSettle();
      expect(find.text('0 results'), findsOneWidget);
      expect(find.textContaining('Showing the first matches'), findsNothing);
      expect(searches, 2);
    },
  );

  testWidgets(
    'archive loads server points while sidebar retains current top three',
    (tester) async {
      final requests = <ApiRequest>[];
      final client = ApiClient(
        hostKey: Object(),
        throttleInterval: Duration.zero,
        transport: (request) async {
          requests.add(request);
          final archived = request.query.containsKey('week');
          return ApiResponse(
            statusCode: 200,
            body: jsonEncode({
              'period': 'week',
              'items': [
                for (var i = 1; i <= 4; i++)
                  {
                    'userId': 'u$i',
                    'username': 'member$i',
                    'displayName': 'Member $i',
                    'avatarUrl': null,
                    'earnedPoints': (archived ? 100 : 200) + i,
                    'rank': i,
                    'style': null,
                  },
              ],
            }),
          );
        },
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            weeklyLeaderboardRepositoryProvider.overrideWithValue(
              LiveWeeklyLeaderboardRepository(client),
            ),
          ],
          child: MaterialApp(
            theme: VnlfTheme.light(),
            home: const Scaffold(
              body: Row(
                children: [
                  Expanded(child: LeaderboardScreen()),
                  SizedBox(width: 304, child: LeaderboardPanel(sidebar: true)),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final cards = tester
          .widgetList<VnlfLeaderboardCard>(find.byType(VnlfLeaderboardCard))
          .toList();
      expect(cards[0].entries.length, 4);
      expect(cards[1].entries.length, 3);
      await tester.tap(find.byTooltip('Previous week'));
      await tester.pumpAndSettle();
      final updated = tester
          .widgetList<VnlfLeaderboardCard>(find.byType(VnlfLeaderboardCard))
          .toList();
      expect(updated[0].entries.first.points, 101);
      expect(updated[1].entries.first.points, 201);
      expect(requests.last.query['period'], 'week');
      expect(
        requests.last.query['week'],
        matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')),
      );
    },
  );
}

Future<void> pumpSearch(WidgetTester tester, ApiClient client) async {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(body: SearchScreen()),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        searchRepositoryProvider.overrideWithValue(
          LiveSearchRepository(client),
        ),
      ],
      child: MaterialApp.router(theme: VnlfTheme.light(), routerConfig: router),
    ),
  );
  await tester.pump();
}

ApiResponse searchResponse(String title, {bool hasMore = false}) => ApiResponse(
  statusCode: 200,
  body: jsonEncode({
    'articles': [
      {
        'id': title,
        'slug': title,
        'title': title,
        'excerpt': 'Server article',
        'authorId': 'remote-user',
        'username': 'remote',
        'displayName': 'Remote',
        'format': 'ARTICLE',
      },
    ],
    'users': <Object?>[],
    'projects': <Object?>[],
    'tags': <Object?>[],
    'hasMore': {
      'articles': hasMore,
      'users': false,
      'projects': false,
      'tags': false,
    },
  }),
);
