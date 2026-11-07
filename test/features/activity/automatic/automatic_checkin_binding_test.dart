import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/core/api_client.dart';
import 'package:vnlfsocialapp/src/core/session_storage_contract.dart';
import 'package:vnlfsocialapp/src/features/activity/automatic/automatic_checkin_binding.dart';
import 'package:vnlfsocialapp/src/features/activity/domain/activity_uncertainty.dart';

class MemoryStorage implements SessionStorage {
  final values = <String, String>{};
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async => values[key] = value;
  @override
  Future<void> delete(String key) async => values.remove(key);
}

void main() {
  testWidgets('an unconfirmed write is reported once and not retried', (
    tester,
  ) async {
    var calls = 0;
    var problems = 0;
    final client = ApiClient(
      hostKey: Object(),
      throttleInterval: Duration.zero,
      transport: (_) async {
        calls++;
        return ApiResponse(statusCode: 500, body: '{}');
      },
    );
    final tracker = AutomaticModalTracker();
    final key = GlobalKey<NavigatorState>();
    final storage = MemoryStorage();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: key,
        navigatorObservers: [tracker.observer()],
        builder: (_, child) => AutomaticCheckInBinding(
          client: client,
          storage: storage,
          tracker: tracker,
          navigatorKey: key,
          ownerId: 'owner',
          confirmation: Object(),
          live: true,
          clock: () => DateTime.utc(2026, 11, 7),
          onViewActivity: () {},
          onProblem: (_) => problems++,
          child: child!,
        ),
        home: const Text('home'),
      ),
    );
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(problems, 1);
    await tester.pump(const Duration(minutes: 2));
    await tester.pump();
    expect(calls, 1);
    expect(problems, 1);
    await tester.pumpWidget(const SizedBox());
    tracker.dispose();
  });

  testWidgets(
    'each confirmed check-in refreshes activity even if the next claim is delayed',
    (tester) async {
      final first = Completer<ApiResponse>();
      final second = Completer<ApiResponse>();
      final claims = <bool>[];
      final client = ApiClient(
        hostKey: Object(),
        throttleInterval: Duration.zero,
        transport: (request) {
          final claim = jsonDecode(request.body!)['claimCelebration'] as bool;
          claims.add(claim);
          return claim ? second.future : first.future;
        },
      );
      final tracker = AutomaticModalTracker();
      final key = GlobalKey<NavigatorState>();
      final storage = MemoryStorage();
      final confirmation = Object();
      var refreshes = 0;
      Widget app(bool live) => MaterialApp(
        navigatorKey: key,
        navigatorObservers: [tracker.observer()],
        builder: (_, child) => AutomaticCheckInBinding(
          client: client,
          storage: storage,
          tracker: tracker,
          navigatorKey: key,
          ownerId: 'owner',
          confirmation: confirmation,
          live: live,
          clock: () => DateTime.utc(2026, 11, 7),
          onViewActivity: () {},
          onAcknowledged: (_) => refreshes++,
          child: child!,
        ),
        home: const Text('home'),
      );
      ApiResponse ack(bool celebrate) => ApiResponse(
        statusCode: 200,
        body: jsonEncode({
          'date': '2026-11-07',
          'currentStreak': 1,
          'longestStreak': 1,
          'showCelebration': celebrate,
          'checkins': [
            {'date': '2026-11-07', 'streakDay': 1},
          ],
        }),
      );
      await tester.pumpWidget(app(false));
      key.currentState!.push(
        DialogRoute<void>(
          context: key.currentContext!,
          builder: (_) => const AlertDialog(title: Text('dialog')),
        ),
      );
      await tester.pumpAndSettle();
      await tester.pumpWidget(app(true));
      await tester.pump();
      expect(claims, [false]);
      key.currentState!.pop();
      await tester.pumpAndSettle();
      first.complete(ack(false));
      await tester.pumpAndSettle();
      expect(claims, [false, true]);
      expect(refreshes, 1);
      second.complete(ack(true));
      await tester.pumpAndSettle();
      expect(refreshes, 2);
      await tester.pumpWidget(const SizedBox());
      tracker.dispose();
    },
  );

  testWidgets(
    'a backgrounded app presents the confirmed celebration after resume',
    (tester) async {
      final response = Completer<ApiResponse>();
      var calls = 0;
      final client = ApiClient(
        hostKey: Object(),
        throttleInterval: Duration.zero,
        transport: (_) {
          calls++;
          return response.future;
        },
      );
      final tracker = AutomaticModalTracker();
      final key = GlobalKey<NavigatorState>();
      final confirmation = Object();
      final storage = MemoryStorage();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: key,
          navigatorObservers: [tracker.observer()],
          builder: (_, child) => AutomaticCheckInBinding(
            client: client,
            storage: storage,
            tracker: tracker,
            navigatorKey: key,
            ownerId: 'owner',
            confirmation: confirmation,
            live: true,
            clock: () => DateTime.utc(2026, 11, 7),
            onViewActivity: () {},
            child: child!,
          ),
          home: const Text('home'),
        ),
      );
      await tester.pump();
      expect(calls, 1);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      response.complete(
        ApiResponse(
          statusCode: 200,
          body: jsonEncode({
            'date': '2026-11-07',
            'currentStreak': 1,
            'longestStreak': 1,
            'showCelebration': true,
            'checkins': [
              {'date': '2026-11-07', 'streakDay': 1},
            ],
          }),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Continue'), findsNothing);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.text('Continue'), findsOneWidget);
      expect(calls, 1);
      await tester.pumpWidget(const SizedBox());
      tracker.dispose();
    },
  );

  testWidgets('a temporary manual check-in lease is checked again', (
    tester,
  ) async {
    final storage = MemoryStorage();
    final lease = ActivityUncertainty(storage, 'owner');
    expect(lease.tryAcquire(), isTrue);
    addTearDown(lease.release);
    var calls = 0;
    final client = ApiClient(
      hostKey: Object(),
      throttleInterval: Duration.zero,
      transport: (_) async {
        calls++;
        return ApiResponse(statusCode: 400, body: '{}');
      },
    );
    final tracker = AutomaticModalTracker();
    final key = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: key,
        navigatorObservers: [tracker.observer()],
        builder: (_, child) => AutomaticCheckInBinding(
          client: client,
          storage: storage,
          tracker: tracker,
          navigatorKey: key,
          ownerId: 'owner',
          confirmation: Object(),
          live: true,
          onViewActivity: () {},
          child: child!,
        ),
        home: const Text('home'),
      ),
    );
    await tester.pump();
    expect(calls, 0);
    lease.release();
    await tester.pump(const Duration(minutes: 1));
    await tester.pump();
    expect(calls, 1);
    await tester.pumpWidget(const SizedBox());
    tracker.dispose();
  });

  testWidgets('offline mode never sends a check-in', (tester) async {
    var calls = 0;
    final client = ApiClient(
      transport: (_) async {
        calls++;
        throw StateError('unexpected request');
      },
    );
    final tracker = AutomaticModalTracker();
    final key = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: key,
        navigatorObservers: [tracker.observer()],
        builder: (_, child) => AutomaticCheckInBinding(
          client: client,
          storage: MemoryStorage(),
          tracker: tracker,
          navigatorKey: key,
          ownerId: 'owner',
          confirmation: Object(),
          live: false,
          onViewActivity: () {},
          child: child!,
        ),
        home: const Text('home'),
      ),
    );
    await tester.pump();
    expect(calls, 0);
    await tester.pumpWidget(const SizedBox());
    tracker.dispose();
  });

  testWidgets(
    'invalidation removes only the celebration beneath another dialog',
    (tester) async {
      final response = Completer<ApiResponse>();
      final client = ApiClient(
        transport: (_) => response.future,
        throttleInterval: Duration.zero,
        hostKey: Object(),
      );
      final tracker = AutomaticModalTracker();
      final key = GlobalKey<NavigatorState>();
      final storage = MemoryStorage();
      final confirmation = Object();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: key,
          navigatorObservers: [tracker.observer()],
          builder: (_, child) => AutomaticCheckInBinding(
            client: client,
            storage: storage,
            tracker: tracker,
            navigatorKey: key,
            ownerId: 'owner',
            confirmation: confirmation,
            live: true,
            onViewActivity: () {},
            child: child!,
          ),
          home: const Text('home'),
        ),
      );
      await tester.pump();
      final day = DateTime.now().toUtc().add(const Duration(hours: 7));
      final date =
          '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      response.complete(
        ApiResponse(
          statusCode: 200,
          body: jsonEncode({
            'date': date,
            'currentStreak': 1,
            'longestStreak': 1,
            'showCelebration': true,
            'checkins': [
              {'date': date, 'streakDay': 1},
            ],
          }),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Continue'), findsOneWidget);
      key.currentState!.push(
        DialogRoute<void>(
          context: key.currentContext!,
          builder: (_) => const AlertDialog(title: Text('other dialog')),
        ),
      );
      await tester.pumpAndSettle();
      client.invalidateSession();
      await tester.pumpAndSettle();
      expect(find.text('Continue'), findsNothing);
      expect(find.text('other dialog'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      tracker.dispose();
    },
  );

  testWidgets('late acknowledgment after logout cannot display a celebration', (
    tester,
  ) async {
    final response = Completer<ApiResponse>();
    final client = ApiClient(
      transport: (_) => response.future,
      throttleInterval: Duration.zero,
      hostKey: Object(),
    );
    final tracker = AutomaticModalTracker();
    final key = GlobalKey<NavigatorState>();
    final storage = MemoryStorage();
    final confirmation = Object();
    Widget app(String? owner) => MaterialApp(
      navigatorKey: key,
      navigatorObservers: [tracker.observer()],
      builder: (_, child) => AutomaticCheckInBinding(
        client: client,
        storage: storage,
        tracker: tracker,
        navigatorKey: key,
        ownerId: owner,
        confirmation: owner == null ? null : confirmation,
        live: true,
        onViewActivity: () {},
        child: child!,
      ),
      home: const Text('home'),
    );
    await tester.pumpWidget(app('owner'));
    await tester.pump();
    await tester.pumpWidget(app(null));
    final day = DateTime.now().toUtc().add(const Duration(hours: 7));
    final date =
        '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    response.complete(
      ApiResponse(
        statusCode: 200,
        body: jsonEncode({
          'date': date,
          'currentStreak': 1,
          'longestStreak': 1,
          'showCelebration': true,
          'checkins': [
            {'date': date, 'streakDay': 1},
          ],
        }),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Continue'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    tracker.dispose();
  });

  testWidgets('tracker counts popups on two navigators independently', (
    tester,
  ) async {
    final tracker = AutomaticModalTracker();
    final root = GlobalKey<NavigatorState>();
    final shell = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: root,
        navigatorObservers: [tracker.observer()],
        home: Navigator(
          key: shell,
          observers: [tracker.observer()],
          onGenerateRoute: (_) =>
              MaterialPageRoute<void>(builder: (_) => const Text('shell')),
        ),
      ),
    );
    root.currentState!.push(
      DialogRoute<void>(
        context: root.currentContext!,
        builder: (_) => const AlertDialog(title: Text('root popup')),
      ),
    );
    shell.currentState!.push(
      DialogRoute<void>(
        context: shell.currentContext!,
        builder: (_) => const AlertDialog(title: Text('shell popup')),
      ),
    );
    await tester.pumpAndSettle();
    expect(tracker.modalOpen, isTrue);
    root.currentState!.pop();
    await tester.pumpAndSettle();
    expect(tracker.modalOpen, isTrue);
    shell.currentState!.pop();
    await tester.pumpAndSettle();
    expect(tracker.modalOpen, isFalse);
    await tester.pumpWidget(const SizedBox());
    tracker.dispose();
  });

  testWidgets('background state prevents writes until resume', (tester) async {
    var calls = 0;
    final response = Completer<ApiResponse>();
    final client = ApiClient(
      transport: (_) {
        calls++;
        return response.future;
      },
      throttleInterval: Duration.zero,
      hostKey: Object(),
    );
    final tracker = AutomaticModalTracker();
    final key = GlobalKey<NavigatorState>();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: key,
        navigatorObservers: [tracker.observer()],
        builder: (_, child) => AutomaticCheckInBinding(
          client: client,
          storage: MemoryStorage(),
          tracker: tracker,
          navigatorKey: key,
          ownerId: 'owner',
          confirmation: Object(),
          live: true,
          onViewActivity: () {},
          child: child!,
        ),
        home: const Text('home'),
      ),
    );
    await tester.pump();
    expect(calls, 0);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(calls, 1);
    await tester.pumpWidget(const SizedBox());
    response.completeError(StateError('synthetic cancellation'));
    await tester.pump();
    tracker.dispose();
  });
}
