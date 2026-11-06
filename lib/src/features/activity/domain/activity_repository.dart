import 'activity_models.dart';

abstract interface class ActivityRepository {
  Future<ActivityCalendarData> loadCalendar({
    required String from,
    required String to,
  });

  /// A single non-idempotent attendance write. Never automatically retried.
  Future<CheckInAcknowledgment> checkIn({required bool claimCelebration});
}
