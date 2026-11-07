import '../../../domain/models.dart';
import '../../../domain/repositories.dart';
import '../domain/leaderboard_week.dart';

final class FixtureWeeklyLeaderboardRepository
    implements WeeklyLeaderboardRepository {
  const FixtureWeeklyLeaderboardRepository(this._source);
  final LeaderboardRepository _source;

  @override
  Future<LeaderboardPage> getWeek({LeaderboardWeek? week}) async {
    final page = await _source.getLeaderboard();
    final current = LeaderboardWeek.current(DateTime.now());
    final selected = week ?? current;
    return LeaderboardPage(
      period: 'week',
      periodStart: selected.start,
      periodEnd: selected.end,
      computedAt: page.computedAt,
      items: selected.anchor == current.anchor ? page.items : const [],
    );
  }
}
