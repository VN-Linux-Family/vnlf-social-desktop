import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../design_system/design_system.dart';
import '../../leaderboard/presentation/leaderboard_screen.dart';
import '../../projects/presentation/projects_screen.dart';
import '../../shared/presentation/author_mapper.dart';
import '../../shared/presentation/feature_widgets.dart';
import 'search_index.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _query = TextEditingController();
  int _scope = 0;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final english = Localizations.localeOf(context).languageCode == 'en';
    final colors = VnlfColors.of(context);
    final index = ref.watch(searchIndexProvider);
    final scopes = english
        ? ['All', 'Posts', 'Projects', 'Users']
        : ['Tất cả', 'Bài viết', 'Dự án', 'Thành viên'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VnlfCenterPageHeader(
          title: english ? 'Search' : 'Tìm kiếm',
          leading: context.canPop()
              ? IconButton(
                  tooltip: english ? 'Back' : 'Quay lại',
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => context.pop(),
                )
              : null,
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('search-input'),
          controller: _query,
          textInputAction: TextInputAction.search,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: english ? 'Search the community' : 'Tìm trong cộng đồng',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _query.text.isEmpty
                ? null
                : IconButton(
                    tooltip: english ? 'Clear search' : 'Xóa tìm kiếm',
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(_query.clear),
                  ),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var scope = 0; scope < scopes.length; scope++)
              ChoiceChip(
                selectedColor: colors.brandSoft,
                backgroundColor: colors.surface,
                checkmarkColor: colors.brand,
                side: BorderSide(color: colors.line),
                labelStyle: VnlfTypography.control(colors.ink),
                label: Text(scopes[scope]),
                selected: _scope == scope,
                onSelected: (_) => setState(() => _scope = scope),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _query.text.trim().isEmpty
              ? ListView(
                  children: [
                    Text(
                      english ? 'Popular tags' : 'Chủ đề phổ biến',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final tag in [
                          'Arch Linux',
                          'Wayland',
                          'CachyOS',
                          'Hyprland',
                          'Kernel',
                          'Rust',
                        ])
                          ActionChip(
                            backgroundColor: colors.surface,
                            side: BorderSide(color: colors.line),
                            labelStyle: VnlfTypography.control(colors.ink),
                            label: Text(tag),
                            onPressed: () => setState(() => _query.text = tag),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      english
                          ? 'Find posts, projects and members in the loaded community content.'
                          : 'Tìm bài viết, dự án và thành viên trong nội dung cộng đồng đã tải.',
                    ),
                  ],
                )
              : index.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => ListView(
                    children: [
                      FeatureLoadError(
                        onRetry: () {
                          ref.invalidate(feedProvider(null));
                          ref.invalidate(projectsProvider);
                          ref.invalidate(leaderboardProvider);
                          ref.invalidate(searchIndexProvider);
                        },
                      ),
                    ],
                  ),
                  data: (data) =>
                      _results(context, data.matching(_query.text), english),
                ),
        ),
      ],
    );
  }

  Widget _results(BuildContext context, SearchIndex matches, bool english) {
    final posts = _scope == 0 || _scope == 1
        ? matches.posts
        : matches.posts.take(0);
    final projects = _scope == 0 || _scope == 2
        ? matches.projects
        : matches.projects.take(0);
    final users = _scope == 0 || _scope == 3
        ? matches.users
        : matches.users.take(0);
    final count = posts.length + projects.length + users.length;
    if (count == 0) {
      return ListView(
        children: [
          VnlfStateCard(
            icon: Icons.search_off,
            title: english ? 'No results found' : 'Không tìm thấy kết quả',
            message: english
                ? 'Try another keyword or search scope.'
                : 'Thử từ khóa khác hoặc đổi phạm vi tìm kiếm.',
          ),
        ],
      );
    }
    return ListView(
      children: [
        Text(
          english ? '$count results' : '$count kết quả',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (posts.isNotEmpty) ...[
          _heading(context, english ? 'Posts' : 'Bài viết'),
          for (final post in posts)
            ListTile(
              leading: const Icon(Icons.article_outlined),
              title: Text(
                post.title?.isNotEmpty == true ? post.title! : post.excerpt,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                post.excerpt,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () =>
                  context.push('/thread/${Uri.encodeComponent(post.id)}'),
            ),
        ],
        if (projects.isNotEmpty) ...[
          _heading(context, english ? 'Projects' : 'Dự án'),
          for (final project in projects)
            ListTile(
              leading: const Icon(Icons.workspaces_outline),
              title: Text(project.name),
              subtitle: Text(
                project.tagline,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => context.push('/projects'),
            ),
        ],
        if (users.isNotEmpty) ...[
          _heading(context, english ? 'Users' : 'Thành viên'),
          for (final user in users)
            ListTile(
              leading: VnlfAvatar(author: presentAuthor(user)),
              title: Text(user.displayName),
              subtitle: Text('@${user.username}'),
              onTap: () => context.push(
                '/profile/${Uri.encodeComponent(user.username)}',
              ),
            ),
        ],
      ],
    );
  }

  Widget _heading(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 4),
    child: Text(text, style: Theme.of(context).textTheme.titleMedium),
  );
}
