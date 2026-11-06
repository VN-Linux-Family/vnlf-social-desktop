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

  Future<CheckInAcknowledgment> checkIn({required bool claimCelebration}) =>
      _repository.checkIn(claimCelebration: claimCelebration);
}
