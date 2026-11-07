import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/design_system.dart';
import '../../../domain/models.dart';
import '../../shared/presentation/author_mapper.dart';
import '../../shared/presentation/feature_samples.dart';

import '../domain/leaderboard_week.dart';
import 'leaderboard_providers.dart';

export 'leaderboard_providers.dart' show leaderboardProvider;

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final english = Localizations.localeOf(context).languageCode == 'en';
    final colors = VnlfColors.of(context);
    final current = LeaderboardWeek.current(DateTime.now());
    final selected = ref.watch(selectedLeaderboardWeekProvider) ?? current;
    final isCurrent = selected.anchor == current.anchor;
    String date(DateTime day) =>
        '${day.day.toString().padLeft(2, "0")}/${day.month.toString().padLeft(2, "0")}/${day.year}';
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
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            IconButton(
              tooltip: english ? 'Previous week' : 'Tuần trước',
              icon: const Icon(Icons.chevron_left),
              onPressed: () =>
                  ref.read(selectedLeaderboardWeekProvider.notifier).state =
                      selected.shift(-1),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCurrent
                      ? (english ? 'This week' : 'Tuần này')
                      : (english ? 'Selected week' : 'Tuần đã chọn'),
                  style: VnlfTypography.control(colors.ink),
                ),
                Text(
                  '${date(selected.date)} – ${date(selected.shift(1).date.subtract(const Duration(days: 1)))}',
                ),
              ],
            ),
            IconButton(
              tooltip: english ? 'Next week' : 'Tuần sau',
              icon: const Icon(Icons.chevron_right),
              onPressed: isCurrent
                  ? null
                  : () {
                      final next = selected.shift(1);
                      ref.read(selectedLeaderboardWeekProvider.notifier).state =
                          next.anchor == current.anchor ? null : next;
                    },
            ),
            if (!isCurrent)
              TextButton(
                onPressed: () =>
                    ref.read(selectedLeaderboardWeekProvider.notifier).state =
                        null,
                child: Text(english ? 'This week' : 'Tuần này'),
              ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            english
                ? 'Weeks start on Monday, Vietnam time (UTC+07).'
                : 'Tuần bắt đầu từ thứ Hai, theo giờ Việt Nam (UTC+07).',
          ),
        ),
        if (offlineFeatures)
          Text(
            english ? 'Sample community rankings' : 'Xếp hạng cộng đồng mẫu',
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => context.push('/activity'),
            icon: const Icon(Icons.calendar_month_outlined),
            label: Text(english ? 'My activity' : 'Hoạt động của tôi'),
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
    final rankings = sidebar
        ? ref.watch(leaderboardProvider)
        : ref.watch(selectedWeekRankingsProvider);
    final items = rankings.asData?.value.items ?? const <LeaderboardItem>[];
    final entries = sidebar ? items.take(3) : items;
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
      onRetry: () {
        if (sidebar || ref.read(selectedLeaderboardWeekProvider) == null) {
          ref.invalidate(leaderboardProvider);
        } else {
          ref.invalidate(selectedWeekRankingsProvider);
        }
      },
    );
    return rankings.isLoading ? VnlfLoadingShimmer(child: card) : card;
  }
}
