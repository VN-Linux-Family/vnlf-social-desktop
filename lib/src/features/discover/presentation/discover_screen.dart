import 'package:flutter/material.dart';
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

final discoverArticlesProvider = FutureProvider.autoDispose<List<FeedPost>>((
  ref,
) async {
  final page = await ref.watch(feedRepositoryProvider).getFeed(type: 'article');
  return [
    ...page.items,
    if (offlineFeatures && !page.items.any((post) => post.id == samplePost.id))
      samplePost,
  ];
});

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  String _query = '';
  String? _tag;

  static const _tags = [
    'Arch Linux',
    'Wayland',
    'CachyOS',
    'Debian',
    'Ubuntu',
    'Hyprland',
  ];

  @override
  Widget build(BuildContext context) {
    final english = Localizations.localeOf(context).languageCode == 'en';
    final colors = VnlfColors.of(context);
    final articles = ref.watch(discoverArticlesProvider);
    final projects = ref.watch(discoverProjectsProvider);
    final contributors = ref.watch(leaderboardProvider);
    return ListView(
      children: [
        FeatureHeader(title: english ? 'Discover' : 'Khám phá'),
        const SizedBox(height: 12),
        FeatureSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                decoration: InputDecoration(
                  labelText: english ? 'Search articles' : 'Tìm bài viết',
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() => _query = value.trim()),
              ),
              const SizedBox(height: 16),
              Text(
                english ? 'Popular tags' : 'Chủ đề phổ biến',
                style: VnlfTypography.h3(colors.ink),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final tag in _tags)
                    FilterChip(
                      selectedColor: colors.brandSoft,
                      checkmarkColor: colors.brand,
                      side: BorderSide(color: colors.line),
                      labelStyle: VnlfTypography.control(colors.ink),
                      label: Text(tag),
                      selected: _tag == tag,
                      onSelected: (selected) =>
                          setState(() => _tag = selected ? tag : null),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          english ? 'Featured articles' : 'Bài viết nổi bật',
          style: VnlfTypography.h2(colors.ink),
        ),
        const SizedBox(height: 12),
        ...articles.when(
          loading: () => const [
            VnlfLoadingShimmer(child: VnlfPostCard.loading()),
          ],
          error: (error, stack) => [
            FeatureLoadError(
              onRetry: () => ref.invalidate(discoverArticlesProvider),
            ),
          ],
          data: (items) => [
            DiscoverArticles(posts: items, query: _query, tag: _tag),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          english ? 'Community projects' : 'Dự án cộng đồng',
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
                if (page.items.isEmpty)
                  Text(english ? 'No projects yet' : 'Chưa có dự án'),
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
          english ? 'Active contributors' : 'Thành viên tích cực',
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
                if (page.items.isEmpty)
                  Text(english ? 'No contributors yet' : 'Chưa có thành viên'),
                for (final member in page.items)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.person_outline),
                    title: Text(member.displayName),
                    subtitle: Text('@${member.username}'),
                    trailing: Text('${member.earnedPoints}'),
                    onTap: () => context.push(
                      '/profile/${Uri.encodeComponent(member.username)}',
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
