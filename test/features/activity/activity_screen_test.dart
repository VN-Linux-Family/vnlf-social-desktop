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

  testWidgets('check-in is explicit, single flight, and reconciles failure', (tester) async {
    final repository = _CheckInRepository();
    await tester.pumpWidget(MaterialApp(home: ActivityScreen(
      service: ActivityService(repository),
      clock: () => DateTime.utc(2026, 11, 6),
    )));
    await tester.pump();
    expect(repository.writes, 0);
    await tester.tap(find.text('Check in today'));
    await tester.pump();
    expect(repository.writes, 1);
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Checking in…')).onPressed, isNull);
    repository.write.completeError(Exception('connection lost'));
    await tester.pump();
    expect(find.textContaining('could not be confirmed'), findsOneWidget);
    expect(find.text('Check in today'), findsNothing);
    repository.failReads = true;
    await tester.tap(find.text('Refresh activity'));
    await tester.pump();
    expect(find.textContaining('could not be confirmed'), findsOneWidget);
    repository.failReads = false;
    repository.checkedIn = true;
    await tester.tap(find.text('Refresh activity'));
    await tester.pump();
    expect(find.textContaining('could not be confirmed'), findsNothing);
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Check in today')).onPressed, isNull);
    expect(repository.writes, 1);
  });

  testWidgets('acknowledgment shows celebration and refreshes calendar', (tester) async {
    final repository = _CheckInRepository();
    await tester.pumpWidget(MaterialApp(home: ActivityScreen(
      service: ActivityService(repository),
      clock: () => DateTime.utc(2026, 11, 6),
    )));
    await tester.pump();
    await tester.tap(find.text('Check in today'));
    repository.checkedIn = true;
    repository.write.complete(CheckInAcknowledgment(
      date: '2026-11-06', currentStreak: 1, longestStreak: 1,
      showCelebration: true,
      checkins: [const CheckInDay(date: '2026-11-06', streakDay: 1)],
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(ActivityCheckInCelebration), findsOneWidget);
    expect(repository.reads, 2);
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

final class _CheckInRepository implements ActivityRepository {
  final write = Completer<CheckInAcknowledgment>();
  int writes = 0;
  int reads = 0;
  bool failReads = false;
  bool checkedIn = false;

  @override
  Future<ActivityCalendarData> loadCalendar({required String from, required String to}) async {
    reads++;
    if (failReads) throw Exception('offline');
    return ActivityCalendarData(
      from: from, to: to, today: '2026-11-06', totalPoints: 0,
      earnedPoints: 0, reversedPoints: 0, currentStreak: 0, longestStreak: 0,
      days: [ActivityDay(date: '2026-11-06', points: 0, checkedIn: checkedIn, streakDay: 0)],
    );
  }

  @override
  Future<CheckInAcknowledgment> checkIn({required bool claimCelebration}) {
    writes++;
    return write.future;
  }
}
