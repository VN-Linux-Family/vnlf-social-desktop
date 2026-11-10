import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../shared/presentation/feature_samples.dart';
import '../data/live_point_stats_repository.dart';
import '../domain/point_stats.dart';

final pointStatsRepositoryProvider = Provider<PointStatsRepository?>(
  (ref) => offlineFeatures
      ? null
      : LivePointStatsRepository(ref.watch(apiClientProvider)),
);

/// This week's points of the signed-in member; null for a guest. Read again
/// for each account, and whenever the rail shows again.
final weekPointStatsProvider = FutureProvider.autoDispose<PointStats?>((ref) {
  final owner = ref.watch(
    sessionStateProvider.select((session) => session?.userId),
  );
  final repository = ref.watch(pointStatsRepositoryProvider);
  if (owner == null || repository == null) return null;
  return repository.week();
});
