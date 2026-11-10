import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/app/providers.dart';
import 'package:vnlfsocialapp/src/design_system/design_system.dart';
import 'package:vnlfsocialapp/src/domain/models.dart';
import 'package:vnlfsocialapp/src/features/leaderboard/presentation/leaderboard_providers.dart';
import 'package:vnlfsocialapp/src/features/shared/presentation/right_rail.dart';
import 'package:vnlfsocialapp/src/features/stats/domain/point_stats.dart';
import 'package:vnlfsocialapp/src/features/stats/presentation/point_stats_providers.dart';
import 'package:vnlfsocialapp/src/features/voice/domain/voice_models.dart';
import 'package:vnlfsocialapp/src/features/voice/presentation/voice_providers.dart';

LeaderboardPage _week(int count) => LeaderboardPage(
  period: 'week',
  items: [
    for (var index = 0; index < count; index++)
      LeaderboardItem(
        userId: 'user-$index',
        username: 'nguoi$index',
        displayName: 'Người $index',
        avatarUrl: '',
        earnedPoints: 20 - index,
        rank: index + 1,
      ),
  ],
);

void main() {
  Future<void> pump(
    WidgetTester tester, {
    Session? session,
    PointStats? stats,
    List<VoiceRoom> rooms = const [],
    int leaders = 3,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionStateProvider.overrideWith((ref) => session),
          weekPointStatsProvider.overrideWith(
            (ref) async => session == null ? null : stats,
          ),
          voiceRoomsProvider.overrideWith((ref) async => rooms),
          leaderboardProvider.overrideWith((ref) async => _week(leaders)),
        ],
        child: MaterialApp(
          theme: VnlfTheme.light(),
          home: const Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(width: 304, child: RightRail()),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a guest sees the week\'s top three only', (tester) async {
    await pump(tester);
    expect(find.text('XP của bạn'), findsNothing);
    expect(find.text('Người 0'), findsOneWidget);
    expect(find.text('Người 3'), findsNothing);
  });

  testWidgets('a member sees their XP, level and streak', (tester) async {
    await pump(
      tester,
      session: const Session(userId: 'me', displayName: 'Tôi'),
      stats: const PointStats(
        totalPoints: 1234,
        level: 3,
        currentStreak: 5,
        nextLevel: (level: 4, name: 'Thợ', minTotalPoints: 1500),
      ),
    );
    expect(find.text('XP của bạn'), findsOneWidget);
    expect(find.textContaining('1.234'), findsOneWidget);
    expect(find.text('Level 3'), findsOneWidget);
    expect(find.text('1.500 XP'), findsOneWidget);
    expect(find.text('Streak 5 ngày'), findsOneWidget);
  });

  testWidgets('the top level has no next goal', (tester) async {
    await pump(
      tester,
      session: const Session(userId: 'me', displayName: 'Tôi'),
      stats: const PointStats(totalPoints: 9000, level: 9, currentStreak: 0),
    );
    expect(find.text('Level cao nhất'), findsOneWidget);
  });

  testWidgets('an open voice room is offered; an empty week is hidden', (
    tester,
  ) async {
    await pump(
      tester,
      leaders: 0,
      rooms: const [
        VoiceRoom(id: 'a', name: 'Phòng chờ', status: 'ACTIVE'),
        VoiceRoom(
          id: 'b',
          name: 'Phòng Linux',
          status: 'ACTIVE',
          participantCount: 4,
          description: 'Nói chuyện về Wayland',
        ),
      ],
    );
    expect(find.text('Phòng Linux'), findsOneWidget);
    expect(find.text('Phòng chờ'), findsNothing);
    expect(find.text('LIVE'), findsOneWidget);
    expect(find.text('4 người đang trong room'), findsOneWidget);
    expect(find.text('Tham gia'), findsOneWidget);
    expect(find.text('Xếp hạng tuần'), findsNothing);
  });

  test('the busiest open room wins, then the first in order', () {
    expect(
      busiestOpenRoom(const [
        VoiceRoom(id: 'a', name: 'A', status: 'CLOSED', participantCount: 9),
        VoiceRoom(id: 'b', name: 'B', status: 'ACTIVE', position: 2),
        VoiceRoom(id: 'c', name: 'C', status: 'ACTIVE', position: 1),
      ])?.id,
      'c',
    );
    expect(busiestOpenRoom(const []), isNull);
  });
}
