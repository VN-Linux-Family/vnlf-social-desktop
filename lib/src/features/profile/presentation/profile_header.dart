import 'package:flutter/material.dart';

import '../../../design_system/design_system.dart';
import '../../shared/presentation/author_mapper.dart';
import '../../shared/presentation/feature_widgets.dart';
import 'profile_data.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key, required this.profile});

  final ProfileViewData profile;

  @override
  Widget build(BuildContext context) {
    final english = Localizations.localeOf(context).languageCode == 'en';
    final colors = VnlfColors.of(context);
    final author = presentAuthor(profile.author);
    return FeatureSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              VnlfAvatar(
                author: author,
                size: 72,
                semanticLabel: author.displayName,
              ),
              const SizedBox(width: 16),
              Expanded(child: VnlfAuthorNameRow(author: author, fontSize: 18)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            profile.isSample
                ? (english
                      ? 'Linux enthusiast, sharing open source tools and desktop configurations.'
                      : 'Yêu thích Linux, chia sẻ công cụ mã nguồn mở và cấu hình máy tính. Tiếng Việt: ặ ữ ờ ẫ ệ')
                : (english ? 'Community member' : 'Thành viên cộng đồng'),
            style: VnlfTypography.body(colors.ink),
          ),
          if (profile.isSample) ...[
            const SizedBox(height: 6),
            Text(
              english ? 'Sample profile' : 'Hồ sơ mẫu',
              style: VnlfTypography.meta(colors.muted),
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              _Stat(label: 'Karma', value: profile.karma?.toString() ?? '—'),
              _Stat(
                label: english ? 'Posts' : 'Bài viết',
                value: '${profile.posts.length}',
              ),
              _Stat(
                label: english ? 'Followers' : 'Người theo dõi',
                value: profile.isSample ? '184' : '—',
              ),
              _Stat(
                label: english ? 'Projects' : 'Dự án',
                value: '${profile.projects.length}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: VnlfTypography.h2(colors.ink)),
        Text(label, style: VnlfTypography.meta(colors.muted)),
      ],
    );
  }
}
