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
    expect(coordinator.status, AutomaticCheckInStatus.failed);
  });

  test(
    'a storage failure with failed cleanup leaves status uncertain',
    () async {
      final storage = _Storage()
        ..failWrite = true
        ..failDelete = true;
      final repo = _Repository();
      final coordinator = _coordinator(storage, repo);
      await coordinator.update(_state());
      expect(repo.claims, isEmpty);
      expect(coordinator.status, AutomaticCheckInStatus.uncertain);
    },
  );

  test('a failed uncertainty marker restores the prior unsent phase', () async {
    final storage = _Storage()..failMarkerWrite = true;
    final repo = _Repository();
    final coordinator = _coordinator(storage, repo);
    await coordinator.update(_state());
    expect(repo.claims, isEmpty);
    expect(storage.values, isEmpty);
    expect(coordinator.status, AutomaticCheckInStatus.failed);
    storage.failMarkerWrite = false;
    await coordinator.update(_state());
    expect(repo.claims, [true]);
  });

  test(
    'a marker failure after persistence is cleaned up before retry',
    () async {
      final storage = _Storage()..failMarkerAfterWrite = true;
      final repo = _Repository();
      final coordinator = _coordinator(storage, repo);
      await coordinator.update(_state());
      expect(repo.claims, isEmpty);
      expect(storage.values, isEmpty);
      expect(coordinator.status, AutomaticCheckInStatus.failed);
      storage.failMarkerAfterWrite = false;
      await coordinator.update(_state());
      expect(repo.claims, [true]);
    },
  );

  test(
    'a pending phase write error is restored before subsequent runs',
    () async {
      final storage = _Storage()..failPendingPhaseAfterWrite = true;
      final repo = _Repository();
      final coordinator = _coordinator(storage, repo);
      await coordinator.update(_state());
      expect(repo.claims, isEmpty);
      expect(storage.values, isEmpty);
      expect(coordinator.status, AutomaticCheckInStatus.failed);
      storage.failPendingPhaseAfterWrite = false;
      await coordinator.update(_state());
      expect(repo.claims, [true]);
    },
  );

  test('an acknowledged check-in notifies callers even if post-ack storage write fails', () async {
    var refreshed = false;
    final storage = _Storage()..failPostAckPhaseWrite = true;
    final repo = _Repository();
    final coordinator = _coordinator(
      storage,
      repo,
      onAcknowledged: () => refreshed = true,
    );
    await coordinator.update(_state());
    expect(repo.claims, [true]);
    await Future<void>.delayed(Duration.zero);
    expect(refreshed, isTrue);
    expect(coordinator.status, AutomaticCheckInStatus.uncertain);
  });

  test(
    'a failed marker preserves a prior confirmed attendance record',
    () async {
      final storage = _Storage()..failMarkerWrite = true;
      storage.values['vnlf.activity.automatic.owner'] = '2026-11-07:recorded';
      final repo = _Repository();
      final coordinator = _coordinator(storage, repo);
      await coordinator.update(_state());
      expect(repo.claims, isEmpty);
      expect(
        storage.values['vnlf.activity.automatic.owner'],
        '2026-11-07:recorded',
      );
      storage.failMarkerWrite = false;
      await coordinator.update(_state());
      expect(repo.claims, [true]);
    },
  );

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

  test(
    'an unsent celebration claim retains a confirmed earlier record',
    () async {
      final storage = _DelayedMarkerStorage();
      storage.values['vnlf.activity.automatic.owner'] = '2026-11-07:recorded';
      final repo = _Repository();
      final coordinator = _coordinator(storage, repo);
      final pending = coordinator.update(_state());
      await storage.markerStarted.future;
      await coordinator.update(_state(modal: true));
      storage.allowMarker.complete();
      await pending;
      expect(repo.claims, isEmpty);
      expect(
        storage.values['vnlf.activity.automatic.owner'],
        '2026-11-07:recorded',
      );
      await coordinator.update(_state(modal: true));
      expect(repo.claims, isEmpty);
      await coordinator.update(_state());
      expect(repo.claims, [true]);
    },
  );

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
  void Function()? onAcknowledged,
}) => AutomaticCheckInCoordinator(
  ownerId: 'owner',
  service: ActivityService(
    repo,
    uncertainty: ActivityUncertainty(storage, 'owner'),
  ),
  storage: storage,
  clock: clock ?? () => DateTime.utc(2026, 11, 7),
  onAcknowledged: onAcknowledged,
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
  bool failDelete = false;
  bool failMarkerWrite = false;
  bool failMarkerAfterWrite = false;
  bool failPendingPhaseAfterWrite = false;
  bool failPostAckPhaseWrite = false;
  @override
  Future<void> delete(String key) async {
    if (failDelete) throw StateError('storage delete failure');
    values.remove(key);
  }

  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async {
    if (failWrite) throw StateError('storage failure');
    if (failMarkerWrite && key.startsWith('vnlf.activity.checkin.')) {
      throw StateError('marker write failed');
    }
    if (failPostAckPhaseWrite &&
        key.startsWith('vnlf.activity.automatic.') &&
        (value.endsWith(':done') || value.endsWith(':recorded'))) {
      throw StateError('post-ack storage write failed');
    }
    values[key] = value;
    if (failPendingPhaseAfterWrite &&
        key.startsWith('vnlf.activity.automatic.') &&
        value.endsWith(':pending')) {
      throw StateError('pending phase write failed after persistence');
    }
    if (failMarkerAfterWrite && key.startsWith('vnlf.activity.checkin.')) {
      throw StateError('marker failed after persistence');
    }
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
