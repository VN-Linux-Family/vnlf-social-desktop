import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/models.dart';
import '../../shared/presentation/author_mapper.dart';
import '../../shared/presentation/feature_samples.dart';

final leaderboardProvider = FutureProvider<LeaderboardPage>(
  (ref) => ref.watch(leaderboardRepositoryProvider).getLeaderboard(),
);

enum LeaderboardPeriod { week, month, all }

final leaderboardPeriodProvider = StateProvider<LeaderboardPeriod>(
  (ref) => LeaderboardPeriod.week,
);

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final english = Localizations.localeOf(context).languageCode == 'en';
    final colors = VnlfColors.of(context);
    final period = ref.watch(leaderboardPeriodProvider);
    final labels = english
        ? ['This week', 'This month', 'All time']
        : ['Tuần này', 'Tháng này', 'Tất cả'];
    final isDesktop = MediaQuery.sizeOf(context).width > 840;
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        if (isDesktop) ...[
          VnlfCenterPageHeader(
            title: english ? 'Leaderboard' : 'Bảng xếp hạng',
          ),
          const SizedBox(height: 12),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final value in LeaderboardPeriod.values)
              ChoiceChip(
                selectedColor: colors.brandSoft,
                backgroundColor: colors.surface,
                checkmarkColor: colors.brand,
                side: BorderSide(color: colors.line),
                labelStyle: VnlfTypography.control(colors.ink),
                label: Text(labels[value.index]),
                selected: period == value,
                onSelected: (_) =>
                    ref.read(leaderboardPeriodProvider.notifier).state = value,
              ),
          ],
        ),
        if (offlineFeatures && period != LeaderboardPeriod.week)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              english ? 'Sample community rankings' : 'Xếp hạng cộng đồng mẫu',
            ),
          ),
        const SizedBox(height: 12),
        const LeaderboardPanel(),
      ],
    );
  }
}

/// The same repository-backed rankings serve the sidebar and full route.
class LeaderboardPanel extends ConsumerWidget {
  const LeaderboardPanel({super.key, this.sidebar = false});

  final bool sidebar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final english = Localizations.localeOf(context).languageCode == 'en';
    final rankings = ref.watch(leaderboardProvider);
    final period = sidebar
        ? LeaderboardPeriod.week
        : ref.watch(leaderboardPeriodProvider);
    final weekly = rankings.asData?.value.items ?? const <LeaderboardItem>[];
    final entries = period == LeaderboardPeriod.week
        ? weekly
        : offlineFeatures
        ? _localPeriod(weekly, period)
        : const <LeaderboardItem>[];
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
      title: switch (period) {
        LeaderboardPeriod.week =>
          english ? 'Weekly leaderboard' : 'Xếp hạng tuần',
        LeaderboardPeriod.month =>
          english ? 'Monthly leaderboard' : 'Xếp hạng tháng',
        LeaderboardPeriod.all =>
          english ? 'All-time leaderboard' : 'Xếp hạng tổng',
      },
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
      emptyMessage: period != LeaderboardPeriod.week && !offlineFeatures
          ? (english
                ? 'Rankings for this period are not available.'
                : 'Chưa có dữ liệu xếp hạng cho kỳ này.')
          : english
          ? 'Community contributions will appear here.'
          : 'Đóng góp của cộng đồng sẽ xuất hiện tại đây.',
      retryLabel: english ? 'Retry' : 'Thử lại',
      onRetry: () => ref.invalidate(leaderboardProvider),
    );
    return rankings.isLoading ? VnlfLoadingShimmer(child: card) : card;
  }
}

/// Explicit synthetic period values; never applied to production responses.
List<LeaderboardItem> _localPeriod(
  List<LeaderboardItem> weekly,
  LeaderboardPeriod period,
) {
  final points = period == LeaderboardPeriod.month
      ? const {'hoangnam': 1120, 'minhtri': 1280, 'linhdan': 980}
      : const {'hoangnam': 8640, 'minhtri': 7560, 'linhdan': 7920};
  final sorted = [...weekly]
    ..sort(
      (a, b) => (points[b.username] ?? b.earnedPoints).compareTo(
        points[a.username] ?? a.earnedPoints,
      ),
    );
  return [
    for (var i = 0; i < sorted.length; i++)
      LeaderboardItem(
        userId: sorted[i].userId,
        username: sorted[i].username,
        displayName: sorted[i].displayName,
        avatarUrl: sorted[i].avatarUrl,
        earnedPoints: points[sorted[i].username] ?? sorted[i].earnedPoints,
        rank: i + 1,
        style: sorted[i].style,
      ),
  ];
}
