import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/design_system.dart';
import '../../../i18n/vi.dart';
import '../../projects/presentation/project_detail_sheet.dart';
import '../../shared/presentation/author_mapper.dart';
import '../domain/search_results.dart';

class SearchResultsList extends StatelessWidget {
  const SearchResultsList({
    super.key,
    required this.results,
    required this.scope,
    required this.onTopic,
  });
  final SearchResults results;
  final SearchScope scope;
  final ValueChanged<SearchTopic> onTopic;

  @override
  Widget build(BuildContext context) {
    bool visible(SearchScope group) =>
        scope == SearchScope.all || scope == group;
    final posts = visible(SearchScope.posts)
        ? results.posts
        : results.posts.take(0);
    final projects = visible(SearchScope.projects)
        ? results.projects
        : results.projects.take(0);
    final users = visible(SearchScope.users)
        ? results.users
        : results.users.take(0);
    final topics = visible(SearchScope.topics)
        ? results.topics
        : results.topics.take(0);
    final count = posts.length + projects.length + users.length + topics.length;
    final capped = results.hasMore.any(visible);
    Widget heading(String title, int count, SearchScope group) => Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 4),
      child: Text(
        '$title · $count${results.hasMore.contains(group) ? '+' : ''}',
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
    return ListView(
      children: [
        Text(
          format(vi.app.search.ketQua, {
            'count': count,
            'capped': capped ? '+' : '',
          }),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (capped) Text(vi.app.search.dangHienThiCac),
        if (count == 0)
          VnlfStateCard(
            icon: Icons.search_off,
            title: vi.searchView.chuaTimThayKetQua,
            message: vi.app.search.thuTuKhoaKhac,
          ),
        if (users.isNotEmpty) ...[
          heading(vi.common.roleMember, users.length, SearchScope.users),
          for (final user in users)
            ListTile(
              leading: VnlfAvatar(author: presentAuthor(user)),
              title: Text(user.displayName),
              subtitle: Text(
                '@${user.username}${(results.biographies[user.username] ?? '').isEmpty ? '' : '\n${results.biographies[user.username]}'}',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => context.push(
                '/profile/${Uri.encodeComponent(user.username)}',
              ),
            ),
        ],
        if (posts.isNotEmpty) ...[
          heading(vi.common.baiViet, posts.length, SearchScope.posts),
          for (final post in posts)
            ListTile(
              leading: VnlfAvatar(author: presentAuthor(post.author)),
              title: Text(
                post.title?.isNotEmpty == true ? post.title! : post.excerpt,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '@${post.author.username}\n${post.excerpt}',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () =>
                  context.push('/thread/${Uri.encodeComponent(post.id)}'),
            ),
        ],
        if (projects.isNotEmpty) ...[
          heading(vi.searchView.duAn, projects.length, SearchScope.projects),
          for (final project in projects)
            ListTile(
              leading: const Icon(Icons.workspaces_outline),
              title: Text(project.name),
              subtitle: Text(
                project.tagline,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => showProjectDetailSheet(context, project),
            ),
        ],
        if (topics.isNotEmpty) ...[
          heading(vi.searchView.chuDe, topics.length, SearchScope.topics),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final topic in topics)
                ActionChip(
                  label: Text('#${topic.name}'),
                  onPressed: () => onTopic(topic),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
