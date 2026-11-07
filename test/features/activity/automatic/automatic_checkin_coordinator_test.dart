import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/core/session_storage_contract.dart';
import 'package:vnlfsocialapp/src/features/activity/automatic/automatic_checkin_coordinator.dart';
import 'package:vnlfsocialapp/src/features/activity/domain/activity_models.dart';
import 'package:vnlfsocialapp/src/features/activity/domain/activity_repository.dart';
import 'package:vnlfsocialapp/src/features/activity/domain/activity_service.dart';
import 'package:vnlfsocialapp/src/features/activity/domain/activity_uncertainty.dart';

void main() {
  test('confirmed false claim permits one true claim after modal closes', () async {
    final storage = _Storage();
    final repo = _Repository();
    final coordinator = _coordinator(storage, repo);
    await coordinator.update(_state(modal: true));
    expect(repo.claims, [false]);
    await coordinator.update(_state());
    expect(repo.claims, [false, true]);
    expect(coordinator.takeCelebration()?.date, '2026-11-07');
    await coordinator.update(_state());
    expect(repo.claims, [false, true]);
  });

  test('uncertain write stays blocked across restart and marker reconciliation', () async {
    final storage = _Storage();
    final repo = _Repository()..fail = true;
    await _coordinator(storage, repo).update(_state());
    await ActivityUncertainty(storage, 'owner').clear();
    repo.fail = false;
    await _coordinator(storage, repo).update(_state());
    expect(repo.claims, [true]);
  });

  test('stale response cannot produce celebration or another claim', () async {
    final storage = _Storage();
    final repo = _Repository()..response = Completer<CheckInAcknowledgment>();
    final coordinator = _coordinator(storage, repo);
    final pending = coordinator.update(_state());
    await repo.started.future;
    await coordinator.update(_state(generation: 2, confirmed: false));
    repo.response!.complete(_ack());
    await pending;
    expect(coordinator.takeCelebration(), isNull);
    await coordinator.update(_state(generation: 2));
    expect(repo.claims, [true]);
  });

  test('holds celebration until visible and modal free', () async {
    final repo = _Repository()..response = Completer<CheckInAcknowledgment>();
    final coordinator = _coordinator(_Storage(), repo);
    final pending = coordinator.update(_state());
    await repo.started.future;
    await coordinator.update(_state(modal: true));
    repo.response!.complete(_ack());
    await pending;
    expect(coordinator.takeCelebration(), isNull);
    await coordinator.update(_state());
    expect(coordinator.takeCelebration(), isNotNull);
    expect(coordinator.takeCelebration(), isNull);
  });
}

AutomaticCheckInCoordinator _coordinator(_Storage storage, _Repository repo) =>
    AutomaticCheckInCoordinator(
      ownerId: 'owner',
      service: ActivityService(repo, uncertainty: ActivityUncertainty(storage, 'owner')),
      storage: storage,
      clock: () => DateTime.utc(2026, 11, 7),
    );

AutomaticCheckInContext _state({bool modal = false, int generation = 1, bool confirmed = true}) =>
    AutomaticCheckInContext(ownerId: 'owner', sessionGeneration: generation, confirmed: confirmed, visible: true, modalOpen: modal);

CheckInAcknowledgment _ack() => CheckInAcknowledgment(date: '2026-11-07', currentStreak: 1, longestStreak: 1, showCelebration: true, checkins: const [CheckInDay(date: '2026-11-07', streakDay: 1)]);

final class _Storage implements SessionStorage {
  final values = <String, String>{};
  @override
  Future<void> delete(String key) async { values.remove(key); }
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async { values[key] = value; }
}

final class _Repository implements ActivityRepository {
  final claims = <bool>[];
  final started = Completer<void>();
  Completer<CheckInAcknowledgment>? response;
  bool fail = false;
  @override
  Future<CheckInAcknowledgment> checkIn({required bool claimCelebration}) async {
    claims.add(claimCelebration);
    if (!started.isCompleted) started.complete();
    if (fail) throw StateError('uncertain');
    if (response != null) return response!.future;
    final ack = _ack();
    return CheckInAcknowledgment(
      date: ack.date,
      currentStreak: ack.currentStreak,
      longestStreak: ack.longestStreak,
      showCelebration: claimCelebration,
      checkins: ack.checkins,
    );
  }
  @override
  Future<ActivityCalendarData> loadCalendar({required String from, required String to}) => throw UnimplementedError();
}
