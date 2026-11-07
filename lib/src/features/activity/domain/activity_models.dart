/// Calendar day in Vietnam's community timezone (Asia/Ho_Chi_Minh).
final class ActivityDay {
  const ActivityDay({
    required this.date,
    required this.points,
    required this.checkedIn,
    required this.streakDay,
  });

  final String date;
  final int points;
  final bool checkedIn;
  final int streakDay;
}

final class ActivityCalendarData {
  ActivityCalendarData({
    required this.from,
    required this.to,
    required this.today,
    required this.totalPoints,
    required this.earnedPoints,
    required this.reversedPoints,
    required this.currentStreak,
    required this.longestStreak,
    required List<ActivityDay> days,
  }) : days = List.unmodifiable(days);

  final String from;
  final String to;
  final String today;
  final int totalPoints;
  final int earnedPoints;
  final int reversedPoints;
  final int currentStreak;
  final int longestStreak;
  final List<ActivityDay> days;
}

final class CheckInDay {
  const CheckInDay({required this.date, required this.streakDay});

  final String date;
  final int streakDay;
}

final class CheckInAcknowledgment {
  CheckInAcknowledgment({
    required this.date,
    required this.currentStreak,
    required this.longestStreak,
    required this.showCelebration,
    required List<CheckInDay> checkins,
  }) : checkins = List.unmodifiable(checkins);

  final String date;
  final int currentStreak;
  final int longestStreak;
  final bool showCelebration;
  final List<CheckInDay> checkins;
}

/// Date-only arithmetic. UTC is used for calendar math; the server interprets
/// calendar date boundaries in Asia/Ho_Chi_Minh (UTC+07), never device time.
String activityDayString(DateTime value) {
  final vietnamTime = value.toUtc().add(const Duration(hours: 7));
  return '${vietnamTime.year.toString().padLeft(4, '0')}-'
      '${vietnamTime.month.toString().padLeft(2, '0')}-'
      '${vietnamTime.day.toString().padLeft(2, '0')}';
}

String shiftActivityDay(String day, int offset) {
  final date = DateTime.utc(
    int.parse(day.substring(0, 4)),
    int.parse(day.substring(5, 7)),
    int.parse(day.substring(8, 10)),
  ).add(Duration(days: offset));
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

({String from, String to}) activityMonthRange(int year, int month) {
  final first = DateTime.utc(year, month);
  final last = DateTime.utc(year, month + 1).subtract(const Duration(days: 1));
  String format(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';
  return (from: format(first), to: format(last));
}
