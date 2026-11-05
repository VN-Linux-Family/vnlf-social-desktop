import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/design_system.dart';
import '../../feed/presentation/post_mapper.dart';
import '../../shared/presentation/feature_widgets.dart';
import 'profile_data.dart';
import 'profile_header.dart';
import 'profile_wardrobe.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key, required this.username});

  /// The route accepts either a username or a public user ID.
  final String username;

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  int _tab = 0;

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.username != widget.username) _tab = 0;
  }

  @override
  Widget build(BuildContext context) {
    final english = Localizations.localeOf(context).languageCode == 'en';
    final profile = ref.watch(profileProvider(widget.username));
    return ListView(
      children: [
        if (context.canPop())
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                tooltip: english ? 'Back' : 'Quay lại',
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => context.pop(),
              ),
            ),
          ),
        const SizedBox(height: 12),
        ...profile.when(
          loading: () => const [Center(child: CircularProgressIndicator())],
          error: (error, stack) => [
            FeatureLoadError(
              onRetry: () => ref.invalidate(profileProvider(widget.username)),
            ),
          ],
          data: (value) => value == null
              ? [
                  VnlfStateCard(
                    icon: Icons.person_outline,
                    title: english
                        ? 'Profile unavailable'
                        : 'Không tìm thấy hồ sơ',
                    message: english
                        ? 'This member is not in the loaded community data.'
                        : 'Thành viên chưa có trong dữ liệu cộng đồng đã tải.',
                  ),
                ]
              : [
                  ProfileHeader(profile: value),
                  const SizedBox(height: 12),
                  VnlfFeedTabBar(
                    tabs: english
                        ? const ['Posts', 'Projects', 'Wardrobe & Badges']
                        : const ['Bài viết', 'Dự án', 'Tủ đồ & Huy hiệu'],
                    selectedIndex: _tab,
                    onTabSelected: (index) => setState(() => _tab = index),
                  ),
                  const SizedBox(height: 12),
                  ..._content(value, english),
                ],
        ),
      ],
    );
  }

  List<Widget> _content(ProfileViewData profile, bool english) =>
      switch (_tab) {
        0 => [
          if (profile.posts.isEmpty)
            Text(english ? 'No posts yet' : 'Chưa có bài viết'),
          for (final post in profile.posts)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () =>
                    context.push('/thread/${Uri.encodeComponent(post.id)}'),
                child: VnlfPostCard(
                  post: presentPost(post, english: english),
                  onCommentTap: () =>
                      context.push('/thread/${Uri.encodeComponent(post.id)}'),
                ),
              ),
            ),
        ],
        1 => [
          if (profile.projects.isEmpty)
            Text(english ? 'No projects yet' : 'Chưa có dự án'),
          for (final item in profile.projects)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: VnlfProjectPreviewCard(
                project: ProjectShowcaseData(
                  id: item.id,
                  name: item.name,
                  description: item.tagline,
                  primaryLanguage: item.repo?['language'] as String? ?? '',
                  tag: item.type,
                  stars: (item.repo?['stars'] as num?)?.toInt() ?? 0,
                  forks: (item.repo?['forks'] as num?)?.toInt() ?? 0,
                  rating: (item.rating?['average'] as num?)?.toDouble() ?? 0,
                ),
              ),
            ),
        ],
        _ => [ProfileWardrobe(author: profile.author)],
      };
}
