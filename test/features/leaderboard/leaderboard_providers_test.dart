import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/app/providers.dart';
import 'package:vnlfsocialapp/src/domain/models.dart';
import 'package:vnlfsocialapp/src/features/leaderboard/domain/leaderboard_week.dart';
import 'package:vnlfsocialapp/src/features/leaderboard/presentation/leaderboard_providers.dart';

void main() {
  test(
    'the rail reads the week again once a saved session is restored',
    () async {
      final weeks = _Weeks();
      final container = ProviderContainer(
        overrides: [
          weeklyLeaderboardRepositoryProvider.overrideWithValue(weeks),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(leaderboardProvider, (_, _) {});
      addTearDown(subscription.close);

      // The guest request is rejected when the restored account arrives.
      await expectLater(
        container.read(leaderboardProvider.future),
        throwsA(isA<HttpFailure>()),
      );
      container.read(sessionStateProvider.notifier).state = const Session(
        userId: 'member',
        displayName: 'Thành viên',
      );
      final page = await container.read(leaderboardProvider.future);
      expect(page.items.single.username, 'lan');
      expect(weeks.calls, 2);
    },
  );
}

class _Weeks implements WeeklyLeaderboardRepository {
  int calls = 0;

  @override
  Future<LeaderboardPage> getWeek({LeaderboardWeek? week}) async {
    if (++calls == 1) throw const HttpFailure(401);
    return LeaderboardPage(
      period: 'week',
      items: const [
        LeaderboardItem(
          userId: 'lan',
          username: 'lan',
          displayName: 'Trần Lan',
          avatarUrl: '',
          earnedPoints: 15,
          rank: 1,
        ),
      ],
    );
  }
}
