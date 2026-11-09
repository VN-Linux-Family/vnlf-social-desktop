import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/design_system.dart';
import '../../../domain/models.dart';
import '../../../i18n/vi.dart';
import '../../shared/presentation/author_mapper.dart';
import '../../shared/presentation/feature_samples.dart';

import '../domain/leaderboard_week.dart';
import 'leaderboard_providers.dart';

export 'leaderboard_providers.dart' show leaderboardProvider;

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = VnlfColors.of(context);
    final current = LeaderboardWeek.current(DateTime.now());
    final selected = ref.watch(selectedLeaderboardWeekProvider) ?? current;
    final isCurrent = selected.anchor == current.anchor;
    String date(DateTime day) =>
        '${day.day.toString().padLeft(2, "0")}/${day.month.toString().padLeft(2, "0")}/${day.year}';
    final isDesktop =
        VnlfViewportSize.fromWidth(MediaQuery.sizeOf(context).width) !=
        VnlfViewportSize.mobile;
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        if (isDesktop) ...[
          VnlfCenterPageHeader(title: vi.app.leaderboard.bangXepHang),
          const SizedBox(height: 12),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            IconButton(
              tooltip: vi.leaderboardView.tuanTruoc,
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
                      ? vi.leaderboardView.tuanNay
                      : vi.leaderboardView.tuanDaChon,
                  style: VnlfTypography.control(colors.ink),
                ),
                Text(
                  '${date(selected.date)} – ${date(selected.shift(1).date.subtract(const Duration(days: 1)))}',
                ),
              ],
            ),
            IconButton(
              tooltip: vi.leaderboardView.tuanSau,
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
                child: Text(vi.leaderboardView.tuanNay),
              ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(vi.app.leaderboard.tuanBatDauTu),
        ),
        if (offlineFeatures) Text(vi.app.leaderboard.xepHangCongDong),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => context.push('/activity'),
            icon: const Icon(Icons.calendar_month_outlined),
            label: Text(vi.app.leaderboard.hoatDongCuaToi),
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
      title: vi.socialChrome.bangDiemTuan,
      viewAllLabel: sidebar ? vi.socialChrome.xemTatCa : '',
      onViewAll: sidebar ? () => context.go('/leaderboard') : null,
      isLoading: rankings.isLoading,
      errorTitle: vi.app.leaderboard.khongTaiDuocBang,
      errorMessage: rankings.hasError ? vi.app.common.vuiLongThuLai : null,
      emptyTitle: vi.app.leaderboard.chuaCoXepHang,
      emptyMessage: vi.app.leaderboard.dongGopCuaCong,
      retryLabel: vi.common.thuLai,
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
