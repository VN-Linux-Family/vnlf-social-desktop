import '../../../i18n/vi.dart';
import '../../polls/presentation/poll_state.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/models.dart';
import '../../leaderboard/presentation/leaderboard_screen.dart';
import '../../shared/presentation/feature_samples.dart';
import '../../shared/presentation/feature_widgets.dart';
import 'discover_articles.dart';

final discoverProjectsProvider = FutureProvider.autoDispose<DiscoverPage>(
  (ref) => ref.watch(discoverRepositoryProvider).getProjects(),
);

final discoverDataProvider = FutureProvider.autoDispose<DiscoverData>((
  ref,
) async {
  ref.watch(sessionStateProvider.select((session) => session?.userId));
  final pollRead = ref.read(pollStoreProvider.notifier).beginRead();
  final data = await ref.watch(discoverRepositoryProvider).getDiscoverData();
  pollRead.acceptAll(data.articles.map((post) => post.poll));
  final articles = [
    ...data.articles,
    if (offlineFeatures &&
        !data.articles.any((post) => post.id == samplePost.id))
      samplePost,
  ];
  return DiscoverData(
    articles: articles,
    users: data.users,
    tags: data.tags,
    projects: data.projects,
    hasMore: data.hasMore,
  );
});

final discoverArticlesProvider = FutureProvider.autoDispose<List<FeedPost>>((
  ref,
) async {
  final data = await ref.watch(discoverDataProvider.future);
  return data.articles;
});

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  String _query = '';
  String? _tag;

  static const _defaultTags = [
    'Arch Linux',
    'Wayland',
    'CachyOS',
    'Debian',
    'Ubuntu',
    'Hyprland',
  ];

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final discoverData = ref.watch(discoverDataProvider);
    final articles = ref.watch(discoverArticlesProvider);
    final projects = ref.watch(discoverProjectsProvider);
    final contributors = ref.watch(leaderboardProvider);

    final tags = discoverData.maybeWhen(
      data: (data) => data.tags.isNotEmpty
          ? data.tags.map((t) => t.name).toList()
          : _defaultTags,
      orElse: () => _defaultTags,
    );

    final isDesktop =
        VnlfViewportSize.fromWidth(MediaQuery.sizeOf(context).width) !=
        VnlfViewportSize.mobile;

    return RefreshIndicator(
      onRefresh: () async {
        HapticFeedback.lightImpact();
        ref.invalidate(discoverDataProvider);
        ref.invalidate(discoverArticlesProvider);
        ref.invalidate(discoverProjectsProvider);
        ref.invalidate(leaderboardProvider);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          if (isDesktop) ...[
            VnlfCenterPageHeader(title: vi.feedViews.khamPha2),
            const SizedBox(height: 12),
          ],
          FeatureSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  decoration: InputDecoration(
                    labelText: vi.app.discover.timBaiViet,
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (value) => setState(() => _query = value.trim()),
                ),
                const SizedBox(height: 16),
                Text(
                  vi.app.common.chuDePhoBien,
                  style: VnlfTypography.h3(colors.ink),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final tag in tags)
                      FilterChip(
                        selectedColor: colors.brandSoft,
                        checkmarkColor: colors.brand,
                        side: BorderSide(color: colors.line),
                        labelStyle: VnlfTypography.control(colors.ink),
                        label: Text(tag),
                        selected: _tag == tag,
                        onSelected: (selected) {
                          HapticFeedback.selectionClick();
                          setState(() => _tag = selected ? tag : null);
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            vi.app.discover.baiVietNoiBat,
            style: VnlfTypography.h2(colors.ink),
          ),
          const SizedBox(height: 12),
          ...articles.when(
            loading: () => const [
              VnlfLoadingShimmer(child: VnlfPostCard.loading()),
            ],
            error: (error, stack) => [
              FeatureLoadError(
                onRetry: () {
                  ref.invalidate(discoverDataProvider);
                  ref.invalidate(discoverArticlesProvider);
                },
              ),
            ],
            data: (items) => [
              DiscoverArticles(posts: items, query: _query, tag: _tag),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            vi.app.discover.duAnCongDong,
            style: VnlfTypography.h2(colors.ink),
          ),
          const SizedBox(height: 8),
          projects.when(
            loading: () => const LinearProgressIndicator(),
            error: (error, stack) => FeatureLoadError(
              onRetry: () => ref.invalidate(discoverProjectsProvider),
            ),
            data: (page) => FeatureSurface(
              child: Column(
                children: [
                  if (page.items.isEmpty) Text(vi.app.common.chuaCoDuAn),
                  for (final project in page.items)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.terminal),
                      title: Text(project.name),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/projects'),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            vi.app.discover.thanhVienTichCuc,
            style: VnlfTypography.h2(colors.ink),
          ),
          const SizedBox(height: 8),
          contributors.when(
            loading: () => const LinearProgressIndicator(),
            error: (error, stack) => FeatureLoadError(
              onRetry: () => ref.invalidate(leaderboardProvider),
            ),
            data: (page) => FeatureSurface(
              child: Column(
                children: [
                  if (page.items.isEmpty) Text(vi.app.discover.chuaCoThanhVien),
                  for (final member in page.items)
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      leading: VnlfAvatar(
                        author: AuthorData(
                          id: member.userId,
                          username: member.username,
                          displayName: member.displayName,
                          avatarUrl: member.avatarUrl,
                          style: AuthorStyleData(
                            frame:
                                (member.style?.frame != null &&
                                    member.style!.frame!.isNotEmpty)
                                ? AvatarFrameType.ring
                                : AvatarFrameType.none,
                          ),
                          loadNetworkAvatar: member.avatarUrl.isNotEmpty,
                        ),
                        size: 36,
                      ),
                      title: Text(
                        member.displayName,
                        style: VnlfTypography.control(colors.ink),
                      ),
                      subtitle: Text(
                        '@${member.username}',
                        style: VnlfTypography.meta(colors.muted),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: colors.brandSoft,
                          borderRadius: BorderRadius.circular(
                            VnlfDimensions.radiusFull,
                          ),
                        ),
                        child: Text(
                          '${member.earnedPoints} pts',
                          style: VnlfTypography.caption(
                            colors.brand,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      onTap: () => context.push(
                        '/profile/${Uri.encodeComponent(member.username)}',
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
