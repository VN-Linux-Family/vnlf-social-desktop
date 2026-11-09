import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/features/activity/domain/activity_models.dart';
import 'package:vnlfsocialapp/src/features/activity/domain/activity_uncertainty.dart';
import 'package:vnlfsocialapp/src/core/session_storage_contract.dart';
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
    expect(find.text('Chuỗi dài nhất: 0 ngày'), findsNothing);
    expect(find.text('Điểm trong tháng'), findsNothing);
    repository.pending.completeError(Exception('offline'));
    await tester.pump();
    expect(
      find.text('Không tải được hoạt động trong tháng này.'),
      findsOneWidget,
    );
    expect(find.text('Chuỗi dài nhất: 0 ngày'), findsNothing);
    expect(find.text('Điểm trong tháng'), findsNothing);
  });

  testWidgets('check-in is explicit, single flight, and reconciles failure', (
    tester,
  ) async {
    final repository = _CheckInRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: ActivityScreen(
          service: ActivityService(
            repository,
            uncertainty: ActivityUncertainty(_Storage(), 'owner-a'),
          ),
          clock: () => DateTime.utc(2026, 11, 6),
        ),
      ),
    );
    await tester.pump();
    expect(repository.writes, 0);
    await tester.tap(find.text('Điểm danh hôm nay'));
    await tester.pump();
    expect(repository.writes, 1);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Đang điểm danh…'),
          )
          .onPressed,
      isNull,
    );
    repository.write.completeError(Exception('connection lost'));
    await tester.pump();
    expect(find.textContaining('Chưa xác nhận được điểm danh'), findsOneWidget);
    expect(find.text('Điểm danh hôm nay'), findsNothing);
    repository.failReads = true;
    await tester.tap(find.text('Làm mới hoạt động'));
    await tester.pump();
    expect(find.textContaining('Chưa xác nhận được điểm danh'), findsOneWidget);
    repository.failReads = false;
    repository.checkedIn = true;
    await tester.tap(find.text('Làm mới hoạt động'));
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('Chưa xác nhận được điểm danh'), findsNothing);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Điểm danh hôm nay'),
          )
          .onPressed,
      isNull,
    );
    expect(repository.writes, 1);
  });

  testWidgets('acknowledgment shows celebration and refreshes calendar', (
    tester,
  ) async {
    final repository = _CheckInRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: ActivityScreen(
          service: ActivityService(
            repository,
            uncertainty: ActivityUncertainty(_Storage(), 'owner-a'),
          ),
          clock: () => DateTime.utc(2026, 11, 6),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Điểm danh hôm nay'));
    repository.checkedIn = true;
    repository.write.complete(
      CheckInAcknowledgment(
        date: '2026-11-06',
        currentStreak: 1,
        longestStreak: 1,
        showCelebration: true,
        checkins: [const CheckInDay(date: '2026-11-06', streakDay: 1)],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(ActivityCheckInCelebration), findsOneWidget);
    expect(repository.reads, 2);
  });

  testWidgets('acknowledgment remains confirmed when calendar refresh fails', (
    tester,
  ) async {
    final storage = _Storage();
    final repository = _CheckInRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: ActivityScreen(
          service: ActivityService(
            repository,
            uncertainty: ActivityUncertainty(storage, 'owner-a'),
          ),
          clock: () => DateTime.utc(2026, 11, 6),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Điểm danh hôm nay'));
    repository.failReads = true;
    repository.write.complete(
      CheckInAcknowledgment(
        date: '2026-11-06',
        currentStreak: 1,
        longestStreak: 1,
        showCelebration: false,
        checkins: [const CheckInDay(date: '2026-11-06', streakDay: 1)],
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(
      find.textContaining('Đã xác nhận điểm danh. Hãy làm mới hoạt động'),
      findsOneWidget,
    );
    expect(find.textContaining('Chưa xác nhận được điểm danh'), findsNothing);
    expect(find.text('Điểm danh hôm nay'), findsNothing);
    expect(repository.writes, 1);
    repository.failReads = false;
    repository.checkedIn = true;
    await tester.tap(find.text('Làm mới hoạt động'));
    await tester.pump();
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Điểm danh hôm nay'),
          )
          .onPressed,
      isNull,
    );
    expect(repository.writes, 1);
  });

  testWidgets(
    'pending outcome survives screen recreation and is owner scoped',
    (tester) async {
      final storage = _Storage();
      final repository = _CheckInRepository();
      Widget screen(String owner) => MaterialApp(
        home: ActivityScreen(
          key: ValueKey(owner),
          service: ActivityService(
            repository,
            uncertainty: ActivityUncertainty(storage, owner),
          ),
          clock: () => DateTime.utc(2026, 11, 6),
        ),
      );
      await tester.pumpWidget(screen('owner-a'));
      await tester.pump();
      await tester.tap(find.text('Điểm danh hôm nay'));
      await tester.pump();
      expect(repository.writes, 1);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(screen('owner-a'));
      await tester.pump();
      expect(
        find.textContaining('Chưa xác nhận được điểm danh'),
        findsOneWidget,
      );
      await tester.pumpWidget(screen('owner-b'));
      await tester.pump();
      expect(find.text('Điểm danh hôm nay'), findsOneWidget);
      expect(find.textContaining('Chưa xác nhận được điểm danh'), findsNothing);
      repository.write.completeError(Exception('interrupted'));
      await tester.pump();
    },
  );

  testWidgets('screens for the same owner cannot send simultaneous writes', (
    tester,
  ) async {
    final storage = _Storage();
    final repository = _CheckInRepository();
    final service = ActivityService(
      repository,
      uncertainty: ActivityUncertainty(storage, 'lease-owner'),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Row(
          children: [
            Expanded(
              child: ActivityScreen(
                service: service,
                clock: () => DateTime.utc(2026, 11, 6),
              ),
            ),
            Expanded(
              child: ActivityScreen(
                service: service,
                clock: () => DateTime.utc(2026, 11, 6),
              ),
            ),
          ],
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Điểm danh hôm nay').first);
    await tester.pump();
    await tester.tap(find.text('Điểm danh hôm nay').last);
    await tester.pump();
    expect(repository.writes, 1);
    repository.write.completeError(Exception('interrupted'));
    await tester.pump();
  });

  testWidgets(
    'day rollover keeps pending marker during delayed reconciliation',
    (tester) async {
      var now = DateTime.utc(2026, 11, 6);
      final storage = _Storage();
      final uncertainty = ActivityUncertainty(storage, 'rollover-owner');
      await uncertainty.mark();
      final repository = _CheckInRepository();
      await tester.pumpWidget(
        MaterialApp(
          home: ActivityScreen(
            service: ActivityService(repository, uncertainty: uncertainty),
            clock: () => now,
          ),
        ),
      );
      await tester.pump();
      repository.delayReads = true;
      await tester.tap(find.text('Làm mới hoạt động'));
      await tester.pump();
      now = DateTime.utc(2026, 11, 7);
      repository.delayedRead.complete(
        repository.calendar('2026-11-01', '2026-11-30'),
      );
      await tester.pump();
      expect(await uncertainty.read(), isTrue);
      expect(
        find.textContaining('Chưa xác nhận được điểm danh'),
        findsOneWidget,
      );
    },
  );

  testWidgets('storage failure prevents check-in', (tester) async {
    final storage = _Storage()..failWrites = true;
    final repository = _CheckInRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: ActivityScreen(
          service: ActivityService(
            repository,
            uncertainty: ActivityUncertainty(storage, 'owner-a'),
          ),
          clock: () => DateTime.utc(2026, 11, 6),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Điểm danh hôm nay'));
    await tester.pump();
    expect(repository.writes, 0);
    expect(
      find.textContaining('Không thể lưu trạng thái điểm danh'),
      findsOneWidget,
    );
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
    expect(find.text('Tháng 2, 2026'), findsOneWidget);
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
  bool delayReads = false;
  final delayedRead = Completer<ActivityCalendarData>();

  @override
  Future<ActivityCalendarData> loadCalendar({
    required String from,
    required String to,
  }) async {
    reads++;
    if (failReads) throw Exception('offline');
    if (delayReads) return delayedRead.future;
    return calendar(from, to);
  }

  ActivityCalendarData calendar(String from, String to) => ActivityCalendarData(
    from: from,
    to: to,
    today: '2026-11-06',
    totalPoints: 0,
    earnedPoints: 0,
    reversedPoints: 0,
    currentStreak: 0,
    longestStreak: 0,
    days: [
      ActivityDay(
        date: '2026-11-06',
        points: 0,
        checkedIn: checkedIn,
        streakDay: 0,
      ),
    ],
  );

  @override
  Future<CheckInAcknowledgment> checkIn({required bool claimCelebration}) {
    writes++;
    return write.future;
  }
}

final class _Storage implements SessionStorage {
  final values = <String, String>{};
  bool failWrites = false;
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async {
    if (failWrites) throw Exception('storage unavailable');
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }
}
