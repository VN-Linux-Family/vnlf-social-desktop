import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/app/app_router.dart';
import 'package:vnlfsocialapp/src/core/api_client.dart';
import 'package:vnlfsocialapp/src/core/session_storage_contract.dart';
import 'package:vnlfsocialapp/src/features/activity/automatic/automatic_checkin_binding.dart';
import 'package:vnlfsocialapp/src/features/feed/presentation/feed_screen.dart';

void main() {
  testWidgets('full-screen composer defers the celebration claim', (
    tester,
  ) async {
    final tracker = AutomaticModalTracker(
      blockedPageNames: {composeRouteName, editComposeRouteName},
    );
    final navigatorKey = GlobalKey<NavigatorState>();
    final router = createMainRouter(
      navigatorKey: navigatorKey,
      rootObservers: [tracker.observer()],
      shellObservers: [tracker.observer()],
    );
    final storage = _Storage();
    final claims = <bool>[];
    final client = ApiClient(
      hostKey: Object(),
      throttleInterval: Duration.zero,
      transport: (request) async {
        final claim = jsonDecode(request.body!)['claimCelebration'] as bool;
        claims.add(claim);
        return ApiResponse(
          statusCode: 200,
          body: jsonEncode({
            'date': '2026-11-07',
            'currentStreak': 1,
            'longestStreak': 1,
            'showCelebration': claim,
            'checkins': [
              {'date': '2026-11-07', 'streakDay': 1},
            ],
          }),
        );
      },
    );
    final confirmation = Object();
    Widget app(bool live) => ProviderScope(
      child: MaterialApp.router(
        routerConfig: router,
        builder: (_, child) => AutomaticCheckInBinding(
          client: client,
          storage: storage,
          tracker: tracker,
          navigatorKey: navigatorKey,
          ownerId: 'owner',
          confirmation: confirmation,
          live: live,
          clock: () => DateTime.utc(2026, 11, 7),
          onViewActivity: () {},
          child: child!,
        ),
      ),
    );
    await tester.pumpWidget(app(false));
    await tester.pumpAndSettle();
    router.go('/compose');
    await tester.pumpAndSettle();
    expect(tracker.modalOpen, isTrue);
    await tester.pumpWidget(app(true));
    await tester.pumpAndSettle();
    expect(claims, [false]);
    expect(find.text('Tiếp tục'), findsNothing);
    router.go('/');
    await tester.pumpAndSettle();
    expect(claims, [false, true]);
    expect(find.text('Tiếp tục'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    router.dispose();
    tracker.dispose();
  });

  testWidgets(
    'shell dialog delays celebration and its activity action navigates',
    (tester) async {
      final tracker = AutomaticModalTracker();
      final navigatorKey = GlobalKey<NavigatorState>();
      final router = createMainRouter(
        navigatorKey: navigatorKey,
        rootObservers: [tracker.observer()],
        shellObservers: [tracker.observer()],
      );
      final storage = _Storage();
      final claims = <bool>[];
      final paths = <String>[];
      final client = ApiClient(
        hostKey: Object(),
        throttleInterval: Duration.zero,
        transport: (request) async {
          paths.add(request.path);
          final claim = jsonDecode(request.body!)['claimCelebration'] as bool;
          claims.add(claim);
          return ApiResponse(
            statusCode: 200,
            body: jsonEncode({
              'date': '2026-11-07',
              'currentStreak': 1,
              'longestStreak': 1,
              'showCelebration': claim,
              'checkins': [
                {'date': '2026-11-07', 'streakDay': 1},
              ],
            }),
          );
        },
      );
      final confirmation = Object();
      var refreshes = 0;
      Widget app(bool live) => ProviderScope(
        child: MaterialApp.router(
          routerConfig: router,
          builder: (_, child) => AutomaticCheckInBinding(
            client: client,
            storage: storage,
            tracker: tracker,
            navigatorKey: navigatorKey,
            ownerId: 'owner',
            confirmation: confirmation,
            live: live,
            clock: () => DateTime.utc(2026, 11, 7),
            onViewActivity: () => router.go('/activity'),
            onAcknowledged: (_) => refreshes++,
            child: child!,
          ),
        ),
      );
      await tester.pumpWidget(app(false));
      await tester.pumpAndSettle();
      final feedContext = tester.element(find.byType(FeedScreen));
      unawaited(
        showDialog<void>(
          context: feedContext,
          useRootNavigator: false,
          builder: (_) => const AlertDialog(title: Text('Shell dialog')),
        ),
      );
      await tester.pumpAndSettle();
      expect(tracker.modalOpen, isTrue);
      await tester.pumpWidget(app(true));
      await tester.pumpAndSettle();
      expect(claims, [false]);
      expect(
        storage.values['vnlf.activity.automatic.owner'],
        '2026-11-07:recorded',
      );
      expect(refreshes, 1);
      expect(find.text('Tiếp tục'), findsNothing);
      Navigator.of(feedContext).pop();
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(claims, [
        false,
        true,
      ], reason: 'storage=${storage.values}, refreshes=$refreshes');
      expect(paths, ['/api/v1/me/check-in', '/api/v1/me/check-in']);
      expect(refreshes, 2);
      expect(find.text('Xem lịch hoạt động'), findsOneWidget);
      await tester.tap(find.text('Xem lịch hoạt động'));
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/activity');
      await tester.pumpWidget(const SizedBox());
      router.dispose();
      tracker.dispose();
    },
  );
}

final class _Storage implements SessionStorage {
  final values = <String, String>{};
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }
}
