import 'package:flutter/material.dart';

import '../../../design_system/design_system.dart';
import '../../shared/presentation/author_mapper.dart';
import '../domain/public_profile.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key, required this.profile});
  final PublicProfile profile;

  @override
  Widget build(BuildContext context) {
    final english = Localizations.localeOf(context).languageCode == 'en';
    final colors = VnlfColors.of(context);
    final author = presentAuthor(profile.author);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(VnlfDimensions.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 195,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 160,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: colors.brandStrong,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(VnlfDimensions.radiusLg),
                    ),
                  ),
                  child: profile.coverUrl == null
                      ? null
                      : Image.network(
                          profile.coverUrl!,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, error, stack) =>
                              const SizedBox.expand(),
                        ),
                ),
                Positioned(
                  left: 24,
                  top: 120,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      shape: BoxShape.circle,
                    ),
                    child: VnlfAvatar(
                      author: author,
                      size: 76,
                      semanticLabel: author.displayName,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VnlfAuthorNameRow(
                  author: author,
                  showHandleInline: false,
                  fontSize: 25,
                ),
                const SizedBox(height: 3),
                Text(
                  '@${author.username}',
                  style: VnlfTypography.meta(colors.muted),
                ),
                if (profile.bio case final bio? when bio.isNotEmpty) ...[
                  const SizedBox(height: 11),
                  Text(bio, style: VnlfTypography.body(colors.ink)),
                ],
                if (profile.isSample) ...[
                  const SizedBox(height: 6),
                  Text(
                    english ? 'Sample profile' : 'Hồ sơ mẫu',
                    style: VnlfTypography.meta(colors.muted),
                  ),
                ],
                const SizedBox(height: 20),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns =
                        constraints.maxWidth < 500 ||
                            MediaQuery.textScalerOf(context).scale(12) > 16
                        ? 2
                        : 4;
                    final stats = [
                      _Stat(
                        label: english ? 'Total XP' : 'Tổng XP',
                        value: profile.totalPoints,
                        level: profile.level,
                      ),
                      _Stat(
                        label: english ? 'Day streak' : 'ngày liên tiếp',
                        value: profile.currentStreak,
                      ),
                      _Stat(
                        label: english ? 'Following' : 'đang theo dõi',
                        value: profile.followingCount,
                      ),
                      _Stat(
                        label: english ? 'Followers' : 'người theo dõi',
                        value: profile.followerCount,
                      ),
                    ];
                    return Wrap(
                      runSpacing: 16,
                      children: [
                        for (final stat in stats)
                          SizedBox(
                            width: constraints.maxWidth / columns,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: stat,
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.level});
  final String label;
  final int? value;
  final int? level;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              value?.toString() ?? '—',
              style: VnlfTypography.h2(colors.ink).copyWith(fontSize: 22),
            ),
            if (level != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                decoration: BoxDecoration(
                  color: colors.brandSoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Level $level',
                  style: VnlfTypography.meta(colors.brand),
                ),
              ),
          ],
        ),
        Text(label, style: VnlfTypography.meta(colors.muted)),
      ],
    );
  }
}
