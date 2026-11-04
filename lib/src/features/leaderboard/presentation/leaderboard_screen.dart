import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/models.dart';
import '../../shared/presentation/author_mapper.dart';

final leaderboardProvider = FutureProvider<LeaderboardPage>(
  (ref) => ref.watch(leaderboardRepositoryProvider).getLeaderboard(),
);

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      ListView(children: const [LeaderboardPanel()]);
}

/// The same repository-backed rankings serve the sidebar and full route.
class LeaderboardPanel extends ConsumerWidget {
  const LeaderboardPanel({super.key, this.sidebar = false});

  final bool sidebar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final english = Localizations.localeOf(context).languageCode == 'en';
    final rankings = ref.watch(leaderboardProvider);
    final entries = rankings.asData?.value.items ?? const <LeaderboardItem>[];
    final card = VnlfLeaderboardCard(
      width: sidebar ? VnlfDimensions.rightSidebarWidth : double.infinity,
      entries: [
        for (final item in entries)
          LeaderboardEntryData(
            rank: item.rank,
            points: item.earnedPoints,
            author: presentAuthor(
              Author(
                id: item.userId,
                username: item.username,
                displayName: item.displayName,
                avatarUrl: item.avatarUrl,
                style: item.style,
              ),
            ),
          ),
      ],
      title: english ? 'Weekly leaderboard' : 'Xếp hạng tuần',
      viewAllLabel: sidebar ? (english ? 'View all' : 'Xem tất cả') : '',
      onViewAll: sidebar ? () => context.go('/leaderboard') : null,
      isLoading: rankings.isLoading,
      errorTitle: english
          ? 'Unable to load leaderboard'
          : 'Không tải được bảng xếp hạng',
      errorMessage: rankings.hasError
          ? (english ? 'Please try again.' : 'Vui lòng thử lại.')
          : null,
      emptyTitle: english ? 'No rankings yet' : 'Chưa có xếp hạng',
      emptyMessage: english
          ? 'Community contributions will appear here.'
          : 'Đóng góp của cộng đồng sẽ xuất hiện tại đây.',
      retryLabel: english ? 'Retry' : 'Thử lại',
      onRetry: () => ref.invalidate(leaderboardProvider),
    );
    return rankings.isLoading ? VnlfLoadingShimmer(child: card) : card;
  }
}
