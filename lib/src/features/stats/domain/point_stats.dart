/// A member's points for a period (`GET /api/v1/me/point-stats`), as the
/// website's right rail reads them.
final class PointStats {
  const PointStats({
    required this.totalPoints,
    required this.level,
    required this.currentStreak,
    this.earnedPoints = 0,
    this.nextLevel,
  });

  final int totalPoints;
  final int level;
  final int currentStreak;

  /// Points earned within the period.
  final int earnedPoints;

  /// The next level and the total it starts at; null at the top level.
  final ({int level, String name, int minTotalPoints})? nextLevel;
}

abstract interface class PointStatsRepository {
  /// The signed-in member's points for the current week.
  Future<PointStats> week();
}
