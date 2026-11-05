import '../../../domain/models.dart';

/// Calendar date at the start of a Monday-based week in Vietnam (UTC+07).
final class LeaderboardWeek {
  LeaderboardWeek._(this.date);
  factory LeaderboardWeek.current(DateTime now) {
    final local = now.toUtc().add(const Duration(hours: 7));
    final day = DateTime.utc(local.year, local.month, local.day);
    return LeaderboardWeek._(day.subtract(Duration(days: day.weekday - 1)));
  }
  final DateTime date;
  String get anchor => date.toIso8601String().substring(0, 10);
  DateTime get start => date.subtract(const Duration(hours: 7));
  DateTime get end => start.add(const Duration(days: 7));
  LeaderboardWeek shift(int weeks) =>
      LeaderboardWeek._(date.add(Duration(days: weeks * 7)));
}

abstract interface class WeeklyLeaderboardRepository {
  Future<LeaderboardPage> getWeek({LeaderboardWeek? week});
}
