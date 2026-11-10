import '../../../core/api_client.dart';
import '../../../data/field_reader.dart';
import '../domain/point_stats.dart';

/// `GET /api/v1/me/point-stats?period=week`, the call the website's right
/// rail makes for "XP của bạn".
final class LivePointStatsRepository implements PointStatsRepository {
  const LivePointStatsRepository(this._client);
  final ApiClient _client;

  @override
  Future<PointStats> week() => _client.get(
    '/api/v1/me/point-stats',
    query: const {'period': 'week'},
    refresh: true,
    decode: (json) {
      final next = objectValue(json['nextLevel'], 'pointStats.nextLevel');
      return PointStats(
        totalPoints: intValue(json['totalPoints'], 'pointStats.totalPoints'),
        level: intValue(json['level'], 'pointStats.level'),
        currentStreak: intValue(
          json['currentStreak'],
          'pointStats.currentStreak',
        ),
        earnedPoints: intValue(json['earnedPoints'], 'pointStats.earnedPoints'),
        nextLevel: next == null
            ? null
            : (
                level: intValue(next['level'], 'pointStats.nextLevel.level'),
                name: stringValue(next['name'], 'pointStats.nextLevel.name'),
                minTotalPoints: intValue(
                  next['minTotalPoints'],
                  'pointStats.nextLevel.minTotalPoints',
                ),
              ),
      );
    },
  );
}
