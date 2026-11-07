import '../../../core/api_client.dart';
import '../../../data/leaderboard_dto.dart';
import '../../../domain/models.dart';
import '../domain/leaderboard_week.dart';

final class LiveWeeklyLeaderboardRepository
    implements WeeklyLeaderboardRepository {
  const LiveWeeklyLeaderboardRepository(this._client);
  final ApiClient _client;

  @override
  Future<LeaderboardPage> getWeek({LeaderboardWeek? week}) => _client.get(
    '/api/v1/leaderboards',
    query: {'period': 'week', if (week != null) 'week': week.anchor},
    decode: (json) => LeaderboardPageDto.fromJson(json).toDomain(),
  );
}
