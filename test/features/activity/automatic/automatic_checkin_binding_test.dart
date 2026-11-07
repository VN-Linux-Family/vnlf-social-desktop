import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/core/api_client.dart';
import 'package:vnlfsocialapp/src/core/session_storage_contract.dart';
import 'package:vnlfsocialapp/src/features/activity/automatic/automatic_checkin_binding.dart';

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
  testWidgets('offline mode never sends a check-in', (tester) async {
    var calls = 0;
    final client = ApiClient(transport: (_) async {
      calls++;
      throw StateError('unexpected request');
    });
    final tracker = AutomaticModalTracker();
    final key = GlobalKey<NavigatorState>();
    await tester.pumpWidget(MaterialApp(
      navigatorKey: key,
      navigatorObservers: [tracker.observer()],
      builder: (_, child) => AutomaticCheckInBinding(
        client: client, storage: MemoryStorage(), tracker: tracker,
        navigatorKey: key, ownerId: 'owner', confirmation: Object(),
        live: false, onViewActivity: () {}, child: child!,
      ),
      home: const Text('home'),
    ));
    await tester.pump();
    expect(calls, 0);
    await tester.pumpWidget(const SizedBox());
    tracker.dispose();
  });

  testWidgets('invalidation removes only the celebration beneath another dialog', (tester) async {
    final response = Completer<ApiResponse>();
    final client = ApiClient(transport: (_) => response.future,
        throttleInterval: Duration.zero, hostKey: Object());
    final tracker = AutomaticModalTracker();
    final key = GlobalKey<NavigatorState>();
    final storage = MemoryStorage();
    final confirmation = Object();
    await tester.pumpWidget(MaterialApp(
      navigatorKey: key,
      navigatorObservers: [tracker.observer()],
      builder: (_, child) => AutomaticCheckInBinding(
        client: client, storage: storage, tracker: tracker,
        navigatorKey: key, ownerId: 'owner', confirmation: confirmation,
        live: true, onViewActivity: () {}, child: child!,
      ),
      home: const Text('home'),
    ));
    await tester.pump();
    final day = DateTime.now().toUtc().add(const Duration(hours: 7));
    final date = '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    response.complete(ApiResponse(statusCode: 200, body: jsonEncode({
      'date': date, 'currentStreak': 1, 'longestStreak': 1,
      'showCelebration': true, 'checkins': [{'date': date, 'streakDay': 1}],
    })));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Continue'), findsOneWidget);
    key.currentState!.push(DialogRoute<void>(context: key.currentContext!,
        builder: (_) => const AlertDialog(title: Text('other dialog'))));
    await tester.pumpAndSettle();
    client.invalidateSession();
    await tester.pumpAndSettle();
    expect(find.text('Continue'), findsNothing);
    expect(find.text('other dialog'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    tracker.dispose();
  });

  testWidgets('late acknowledgment after logout cannot display a celebration', (tester) async {
    final response = Completer<ApiResponse>();
    final client = ApiClient(transport: (_) => response.future,
        throttleInterval: Duration.zero, hostKey: Object());
    final tracker = AutomaticModalTracker();
    final key = GlobalKey<NavigatorState>();
    final storage = MemoryStorage();
    final confirmation = Object();
    Widget app(String? owner) => MaterialApp(
      navigatorKey: key, navigatorObservers: [tracker.observer()],
      builder: (_, child) => AutomaticCheckInBinding(
        client: client, storage: storage, tracker: tracker, navigatorKey: key,
        ownerId: owner, confirmation: owner == null ? null : confirmation,
        live: true, onViewActivity: () {}, child: child!,
      ), home: const Text('home'),
    );
    await tester.pumpWidget(app('owner'));
    await tester.pump();
    await tester.pumpWidget(app(null));
    final day = DateTime.now().toUtc().add(const Duration(hours: 7));
    final date = '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    response.complete(ApiResponse(statusCode: 200, body: jsonEncode({
      'date': date, 'currentStreak': 1, 'longestStreak': 1,
      'showCelebration': true, 'checkins': [{'date': date, 'streakDay': 1}],
    })));
    await tester.pumpAndSettle();
    expect(find.text('Continue'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    tracker.dispose();
  });

  testWidgets('tracker counts popups on two navigators independently', (tester) async {
    final tracker = AutomaticModalTracker();
    final root = GlobalKey<NavigatorState>();
    final shell = GlobalKey<NavigatorState>();
    await tester.pumpWidget(MaterialApp(
      navigatorKey: root, navigatorObservers: [tracker.observer()],
      home: Navigator(key: shell, observers: [tracker.observer()],
        onGenerateRoute: (_) => MaterialPageRoute<void>(builder: (_) => const Text('shell'))),
    ));
    root.currentState!.push(DialogRoute<void>(context: root.currentContext!,
      builder: (_) => const AlertDialog(title: Text('root popup'))));
    shell.currentState!.push(DialogRoute<void>(context: shell.currentContext!,
      builder: (_) => const AlertDialog(title: Text('shell popup'))));
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
    final client = ApiClient(transport: (_) {
      calls++;
      return response.future;
    }, throttleInterval: Duration.zero, hostKey: Object());
    final tracker = AutomaticModalTracker();
    final key = GlobalKey<NavigatorState>();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pumpWidget(MaterialApp(
      navigatorKey: key, navigatorObservers: [tracker.observer()],
      builder: (_, child) => AutomaticCheckInBinding(
        client: client, storage: MemoryStorage(), tracker: tracker,
        navigatorKey: key, ownerId: 'owner', confirmation: Object(),
        live: true, onViewActivity: () {}, child: child!,
      ), home: const Text('home'),
    ));
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
