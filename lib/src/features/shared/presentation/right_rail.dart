import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/providers.dart';
import '../../../design_system/design_system.dart';
import '../../../i18n/vi.dart';
import '../../leaderboard/presentation/leaderboard_screen.dart';
import '../../settings/preferences/preferences_controller.dart';
import '../../stats/domain/point_stats.dart';
import '../../stats/presentation/point_stats_providers.dart';
import '../../voice/domain/voice_models.dart';
import '../../voice/presentation/voice_providers.dart';
import 'feature_samples.dart';

/// The website's right rail (`RightRail` in social-chrome.tsx): the member's
/// XP, the busiest open voice room, and the week's top three, each shown
/// only when it has something to show.
class RightRail extends ConsumerWidget {
  const RightRail({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signedIn = ref.watch(sessionStateProvider) != null;
    final stats = ref.watch(weekPointStatsProvider).valueOrNull;
    final room = busiestOpenRoom(
      ref.watch(voiceRoomsProvider).valueOrNull ?? const [],
    );
    final leaderboardVisible = !signedIn || offlineFeatures
        ? true
        : ref.watch(
            preferencesControllerProvider.select(
              (state) => state.confirmed?.leaderboardVisible ?? true,
            ),
          );
    final leaders = ref.watch(leaderboardProvider).valueOrNull?.items;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (signedIn) _RailGap(child: _ScoreCard(stats: stats)),
        if (room != null) _RailGap(child: _VoiceCard(room: room)),
        if (leaderboardVisible && (leaders?.isNotEmpty ?? false))
          const LeaderboardPanel(sidebar: true),
      ],
    );
  }
}

/// The open room with the most people, then the first in the list.
VoiceRoom? busiestOpenRoom(List<VoiceRoom> rooms) {
  final open = rooms.where((room) => room.status == 'ACTIVE').toList()
    ..sort(
      (a, b) => b.participantCount != a.participantCount
          ? b.participantCount.compareTo(a.participantCount)
          : a.position.compareTo(b.position),
    );
  return open.firstOrNull;
}

/// `.rail-card` keeps 13px below each card.
class _RailGap extends StatelessWidget {
  const _RailGap({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      Padding(padding: const EdgeInsets.only(bottom: 13), child: child);
}

class _RailCard extends StatelessWidget {
  const _RailCard({required this.padding, required this.child});

  final double padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(VnlfDimensions.radiusLg),
      ),
      child: Padding(padding: EdgeInsets.all(padding), child: child),
    );
  }
}

/// "XP của bạn": total points, the way to the next level, and the streak.
class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.stats});

  /// Null while it loads; the website shows zeros meanwhile.
  final PointStats? stats;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final numbers = NumberFormat.decimalPattern('vi');
    final total = stats?.totalPoints ?? 0;
    final next = stats?.nextLevel?.minTotalPoints ?? total;
    final previous = math.max(0, next - 500);
    final progress = next > previous
        ? ((total - previous) / (next - previous)).clamp(0.0, 1.0)
        : 1.0;
    final tabular = const [FontFeature.tabularFigures()];
    return _RailCard(
      padding: 14,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.brandSoft,
                  borderRadius: BorderRadius.circular(
                    VnlfDimensions.radiusFull,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 5,
                    children: [
                      VnlfIcon(
                        VnlfLucide.zap,
                        size: 13,
                        filled: true,
                        color: colors.brand,
                      ),
                      Text(
                        vi.socialChrome.xpCuaBan,
                        style: VnlfTypography.caption(
                          colors.brand,
                          fontWeight: FontWeight.w800,
                        ).copyWith(letterSpacing: 0.4),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                tooltip: vi.socialChrome.xemDiem,
                visualDensity: VisualDensity.compact,
                onPressed: () => context.push('/activity'),
                icon: VnlfIcon(
                  VnlfLucide.ellipsis,
                  size: 17,
                  color: colors.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text.rich(
            TextSpan(
              text: numbers.format(total),
              children: [
                TextSpan(
                  text: ' ${vi.socialChrome.xp}',
                  style: VnlfTypography.caption(
                    colors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            style: TextStyle(
              fontFamily: VnlfTypography.fontFamily,
              fontSize: 27,
              height: 1,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: colors.ink,
              fontFeatures: tabular,
            ),
          ),
          const SizedBox(height: 11),
          Semantics(
            value: '${(progress * 100).round()}%',
            child: Container(
              height: 5,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: colors.surfaceSoft,
                border: Border.all(color: colors.line),
                borderRadius: BorderRadius.circular(VnlfDimensions.radiusFull),
              ),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: progress,
                heightFactor: 1,
                child: ColoredBox(color: colors.brand),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            spacing: 5,
            children: [
              Text(
                format(vi.socialChrome.level, {'value': stats?.level ?? 1}),
                style: VnlfTypography.meta(colors.muted),
              ),
              Flexible(
                child: Text(
                  stats?.nextLevel == null && stats != null
                      ? vi.socialChrome.capCaoNhat
                      : '${numbers.format(next)} ${vi.socialChrome.xp}',
                  textAlign: TextAlign.end,
                  style: VnlfTypography.meta(
                    colors.ink,
                    fontWeight: FontWeight.w600,
                  ).copyWith(fontFeatures: tabular),
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surfaceSoft,
              borderRadius: BorderRadius.circular(VnlfDimensions.radiusMd),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
              child: Row(
                spacing: 7,
                children: [
                  VnlfIcon(VnlfLucide.flame, size: 16, color: colors.orange),
                  Expanded(
                    child: Text(
                      format(vi.socialChrome.ngayStreak, {
                        'value': stats?.currentStreak ?? 0,
                      }),
                      style: VnlfTypography.meta(
                        colors.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The open voice room with the most people, and a way in.
class _VoiceCard extends StatelessWidget {
  const _VoiceCard({required this.room});

  final VoiceRoom room;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final live = room.participantCount > 0;
    final liveInk = colors.isDark ? colors.red : const Color(0xFFA94737);
    final muted = VnlfTypography.meta(colors.muted);
    return _RailCard(
      padding: 17,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            spacing: 8,
            children: [
              if (live)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 5,
                  children: [
                    VnlfIcon(VnlfLucide.radio, size: 14, color: liveInk),
                    Text(
                      vi.socialChrome.live,
                      style: VnlfTypography.caption(
                        liveInk,
                        fontWeight: FontWeight.w800,
                      ).copyWith(letterSpacing: 0.4),
                    ),
                  ],
                )
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 5,
                  children: [
                    VnlfIcon(
                      VnlfLucide.headphones,
                      size: 14,
                      color: colors.muted,
                    ),
                    Text(
                      vi.socialChrome.phongThoaiDangMo,
                      style: VnlfTypography.meta(
                        colors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              Expanded(
                child: Text(
                  live
                      ? format(vi.socialChrome.nguoiDangKetNoi, {
                          'participantCount': room.participantCount,
                        })
                      : vi.voiceView.chuaCoAiTrongRoom,
                  textAlign: TextAlign.end,
                  style: muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            room.name,
            style: TextStyle(
              fontFamily: VnlfTypography.fontFamily,
              fontSize: 22,
              height: 1.2,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              color: colors.ink,
            ),
          ),
          if (room.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(room.description, style: muted.copyWith(height: 1.5)),
          ],
          const SizedBox(height: 17),
          Align(
            alignment: Alignment.centerRight,
            child: Material(
              color: colors.isDark ? colors.brand : const Color(0xFF304D38),
              borderRadius: BorderRadius.circular(VnlfDimensions.radiusMd),
              child: InkWell(
                borderRadius: BorderRadius.circular(VnlfDimensions.radiusMd),
                onTap: () => context.go('/voice'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 7,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 5,
                    children: [
                      VnlfIcon(
                        VnlfLucide.headphones,
                        size: 15,
                        color: colors.isDark
                            ? const Color(0xFF102016)
                            : Colors.white,
                      ),
                      Text(
                        vi.socialChrome.thamGia,
                        style: VnlfTypography.meta(
                          colors.isDark
                              ? const Color(0xFF102016)
                              : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
