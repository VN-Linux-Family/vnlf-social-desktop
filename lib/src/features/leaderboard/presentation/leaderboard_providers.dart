import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../domain/models.dart';
import '../../shared/presentation/feature_samples.dart';
import '../data/fixture_weekly_leaderboard_repository.dart';
import '../data/live_weekly_leaderboard_repository.dart';
import '../domain/leaderboard_week.dart';

final weeklyLeaderboardRepositoryProvider =
    Provider<WeeklyLeaderboardRepository>((ref) {
      if (offlineFeatures) {
        return FixtureWeeklyLeaderboardRepository(
          ref.watch(leaderboardRepositoryProvider),
        );
      }
      return LiveWeeklyLeaderboardRepository(ref.watch(apiClientProvider));
    });

/// Sidebar and discovery always show the current week.
final leaderboardProvider = FutureProvider<LeaderboardPage>(
  (ref) => ref.watch(weeklyLeaderboardRepositoryProvider).getWeek(),
);

final selectedLeaderboardWeekProvider = StateProvider<LeaderboardWeek?>(
  (ref) => null,
);

final selectedWeekRankingsProvider =
    FutureProvider.autoDispose<LeaderboardPage>((ref) {
      final week = ref.watch(selectedLeaderboardWeekProvider);
      if (week == null) return ref.watch(leaderboardProvider.future);
      return ref.watch(weeklyLeaderboardRepositoryProvider).getWeek(week: week);
    });
