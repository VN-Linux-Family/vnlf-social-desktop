import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/core/session_storage_contract.dart';
import 'package:vnlfsocialapp/src/features/activity/automatic/automatic_checkin_coordinator.dart';
import 'package:vnlfsocialapp/src/features/activity/domain/activity_models.dart';
import 'package:vnlfsocialapp/src/features/activity/domain/activity_repository.dart';
import 'package:vnlfsocialapp/src/features/activity/domain/activity_service.dart';
import 'package:vnlfsocialapp/src/features/activity/domain/activity_uncertainty.dart';

void main() {
  test('does not write for hidden, unconfirmed, or different owners', () async {
    final repo = _Repository();
    final coordinator = _coordinator(_Storage(), repo);
    await coordinator.update(_state(visible: false));
    await coordinator.update(_state(confirmed: false));
    await coordinator.update(_state(owner: 'another'));
    expect(repo.claims, isEmpty);
  });

  test('shared manual lease prevents an automatic write', () async {
    final storage = _Storage();
    final uncertainty = ActivityUncertainty(storage, 'owner');
    final repo = _Repository();
    final coordinator = _coordinator(storage, repo);
    expect(uncertainty.tryAcquire(), isTrue);
    try {
      await coordinator.update(_state());
      expect(repo.claims, isEmpty);
      expect(coordinator.status, AutomaticCheckInStatus.blocked);
    } finally {
      uncertainty.release();
    }
    await coordinator.update(_state());
    expect(repo.claims, [true]);
  });

  test('storage failure before a write never sends a check-in', () async {
    final storage = _Storage()..failWrite = true;
    final repo = _Repository();
    final coordinator = _coordinator(storage, repo);
    await coordinator.update(_state());
    expect(repo.claims, isEmpty);
    expect(coordinator.status, AutomaticCheckInStatus.uncertain);
  });

  test('backgrounding before transport restores the unsent intent', () async {
    final storage = _DelayedMarkerStorage();
    final repo = _Repository();
    final coordinator = _coordinator(storage, repo);
    final pending = coordinator.update(_state());
    await storage.markerStarted.future;
    await coordinator.update(_state(visible: false));
    storage.allowMarker.complete();
    await pending;
    expect(repo.claims, isEmpty);
    expect(storage.values, isEmpty);
    await coordinator.update(_state());
    expect(repo.claims, [true]);
  });

  test('a response from the previous day cannot be presented', () async {
    var now = DateTime.utc(2026, 11, 7);
    final repo = _Repository()..response = Completer<CheckInAcknowledgment>();
    final coordinator = _coordinator(_Storage(), repo, clock: () => now);
    final pending = coordinator.update(_state());
    await repo.started.future;
    now = DateTime.utc(2026, 11, 8);
    repo.response!.complete(_ack());
    await pending;
    expect(coordinator.takeCelebration(), isNull);
  });

  test('a server date mismatch leaves the outcome unresolved', () async {
    final storage = _Storage();
    final repo = _Repository()..response = Completer<CheckInAcknowledgment>();
    final coordinator = _coordinator(storage, repo);
    final pending = coordinator.update(_state());
    await repo.started.future;
    repo.response!.complete(
      CheckInAcknowledgment(
        date: '2026-11-06',
        currentStreak: 1,
        longestStreak: 1,
        showCelebration: true,
        checkins: const [CheckInDay(date: '2026-11-06', streakDay: 1)],
      ),
    );
    await pending;
    expect(coordinator.status, AutomaticCheckInStatus.uncertain);
    expect(coordinator.takeCelebration(), isNull);
    await coordinator.update(_state());
    expect(repo.claims, [true]);
  });

  test('clearing a coordinator drops in-flight celebrations', () async {
    final repo = _Repository()..response = Completer<CheckInAcknowledgment>();
    final coordinator = _coordinator(_Storage(), repo);
    final pending = coordinator.update(_state());
    await repo.started.future;
    coordinator.clear();
    repo.response!.complete(_ack());
    await pending;
    expect(coordinator.takeCelebration(), isNull);
    await coordinator.update(_state());
    expect(repo.claims, [true]);
  });

  test(
    'confirmed false claim permits one true claim after modal closes',
    () async {
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
    },
  );

  test(
    'uncertain write stays blocked across restart and marker reconciliation',
    () async {
      final storage = _Storage();
      final repo = _Repository()..fail = true;
      await _coordinator(storage, repo).update(_state());
      await ActivityUncertainty(storage, 'owner').clear();
      repo.fail = false;
      await _coordinator(storage, repo).update(_state());
      expect(repo.claims, [true]);
    },
  );

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

AutomaticCheckInCoordinator _coordinator(
  SessionStorage storage,
  _Repository repo, {
  DateTime Function()? clock,
}) => AutomaticCheckInCoordinator(
  ownerId: 'owner',
  service: ActivityService(
    repo,
    uncertainty: ActivityUncertainty(storage, 'owner'),
  ),
  storage: storage,
  clock: clock ?? () => DateTime.utc(2026, 11, 7),
);

AutomaticCheckInContext _state({
  bool modal = false,
  int generation = 1,
  bool confirmed = true,
  bool visible = true,
  String owner = 'owner',
}) => AutomaticCheckInContext(
  ownerId: owner,
  sessionGeneration: generation,
  confirmed: confirmed,
  visible: visible,
  modalOpen: modal,
);

CheckInAcknowledgment _ack() => CheckInAcknowledgment(
  date: '2026-11-07',
  currentStreak: 1,
  longestStreak: 1,
  showCelebration: true,
  checkins: const [CheckInDay(date: '2026-11-07', streakDay: 1)],
);

final class _Storage implements SessionStorage {
  final values = <String, String>{};
  bool failWrite = false;
  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }

  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async {
    if (failWrite) throw StateError('storage failure');
    values[key] = value;
  }
}

final class _DelayedMarkerStorage implements SessionStorage {
  final values = <String, String>{};
  final markerStarted = Completer<void>();
  final allowMarker = Completer<void>();

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    if (key.startsWith('vnlf.activity.checkin.') &&
        !markerStarted.isCompleted) {
      markerStarted.complete();
      await allowMarker.future;
    }
    values[key] = value;
  }
}

final class _Repository implements ActivityRepository {
  final claims = <bool>[];
  final started = Completer<void>();
  Completer<CheckInAcknowledgment>? response;
  bool fail = false;
  @override
  Future<CheckInAcknowledgment> checkIn({
    required bool claimCelebration,
  }) async {
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
  Future<ActivityCalendarData> loadCalendar({
    required String from,
    required String to,
  }) => throw UnimplementedError();
}
