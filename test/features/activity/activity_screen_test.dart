import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/features/activity/domain/activity_models.dart';
import 'package:vnlfsocialapp/src/features/activity/domain/activity_repository.dart';
import 'package:vnlfsocialapp/src/features/activity/domain/activity_service.dart';
import 'package:vnlfsocialapp/src/features/activity/presentation/activity_screen.dart';

void main() {
  testWidgets('loading and error do not display invented streaks or totals', (
    tester,
  ) async {
    final repository = _Repository();
    await tester.pumpWidget(
      MaterialApp(home: ActivityScreen(service: ActivityService(repository))),
    );
    expect(find.text('Longest streak: 0 days'), findsNothing);
    expect(find.text('Points this month'), findsNothing);
    repository.pending.completeError(Exception('offline'));
    await tester.pump();
    expect(
      find.text('Could not load activity for this month.'),
      findsOneWidget,
    );
    expect(find.text('Longest streak: 0 days'), findsNothing);
    expect(find.text('Points this month'), findsNothing);
  });

  testWidgets('resume advances the current Vietnam month and reloads', (
    tester,
  ) async {
    var now = DateTime.utc(2026, 1, 31, 16, 59);
    final repository = _Repository();
    await tester.pumpWidget(
      MaterialApp(
        home: ActivityScreen(
          service: ActivityService(repository),
          clock: () => now,
        ),
      ),
    );
    expect(repository.requests, ['2026-01-01']);
    now = DateTime.utc(2026, 1, 31, 17);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(repository.requests, ['2026-01-01', '2026-02-01']);
    expect(find.text('February 2026'), findsOneWidget);
  });
}

final class _Repository implements ActivityRepository {
  final pending = Completer<ActivityCalendarData>();
  final requests = <String>[];

  @override
  Future<ActivityCalendarData> loadCalendar({
    required String from,
    required String to,
  }) {
    requests.add(from);
    return pending.future;
  }

  @override
  Future<CheckInAcknowledgment> checkIn({required bool claimCelebration}) =>
      throw UnimplementedError();
}
