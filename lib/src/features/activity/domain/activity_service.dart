import 'activity_models.dart';
import 'activity_repository.dart';

/// Small application service shared by the stats screen and session lifecycle.
final class ActivityService {
  const ActivityService(this._repository);

  final ActivityRepository _repository;

  Future<ActivityCalendarData> loadMonth(int year, int month) {
    final range = activityMonthRange(year, month);
    return _repository.loadCalendar(from: range.from, to: range.to);
  }

  Future<CheckInAcknowledgment> checkIn({
    required bool claimCelebration,
  }) => _repository.checkIn(claimCelebration: claimCelebration);
}

/// One-shot daily hook for the app's confirmed-session/foreground coordinator.
/// It deliberately owns no timers or lifecycle listeners. The coordinator
/// calls [runForConfirmedSession] after it confirms a visible active session;
/// failed POSTs stay consumed for that owner/date to prevent automatic retry.
final class DailyCheckInTrigger {
  DailyCheckInTrigger({
    required this.service,
    required this.ownerId,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final ActivityService service;
  final String ownerId;
  final DateTime Function() _clock;
  final Set<String> _attemptedDays = <String>{};
  final Map<String, Future<CheckInAcknowledgment?>> _pending = {};

  Future<CheckInAcknowledgment?> runForConfirmedSession({
    required bool claimCelebration,
  }) {
    final day = activityDayString(_clock());
    final key = '$ownerId:$day';
    final existing = _pending[key];
    if (existing != null) return existing;
    if (_attemptedDays.contains(key)) return Future.value(null);
    _attemptedDays.add(key);
    final request = service.checkIn(claimCelebration: claimCelebration);
    final guarded = request.then<CheckInAcknowledgment?>((value) => value);
    _pending[key] = guarded;
    return guarded.whenComplete(() => _pending.remove(key));
  }
}
