import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../fixtures/vnlf_gallery_fixtures.dart';

/// Key Screen 2: Thread / Post Detail (`Bài viết & Thảo luận`) with full post content,
/// code configuration block, inline comment composer, and nested comment tree.
class VnlfThreadScreen extends StatefulWidget {
  const VnlfThreadScreen({
    super.key,
    this.themeMode = ThemeMode.light,
    this.onThemeModeChanged,
    this.onBackToFeed,
    this.onOpenProfile,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode>? onThemeModeChanged;
  final VoidCallback? onBackToFeed;
  final VoidCallback? onOpenProfile;

  @override
  State<VnlfThreadScreen> createState() => _VnlfThreadScreenState();
}

class _VnlfThreadScreenState extends State<VnlfThreadScreen> {
  late PostData _post;

  @override
  void initState() {
    super.initState();
    _post = VnlfGalleryFixtures.threadDetailPost;
  }

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);

    return VnlfAdaptiveShell(
      activeDestination: VnlfNavDestination.feed,
      themeMode: widget.themeMode,
      onThemeModeChanged: widget.onThemeModeChanged,
      onProfileTap: widget.onOpenProfile,
      rightSidebarChild: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ThreadAuthorCard(
            author: _post.author,
            onProfileTap: widget.onOpenProfile,
          ),
          const SizedBox(height: 16),
          VnlfLeaderboardCard(
            entries: VnlfGalleryFixtures.weeklyLeaderboard,
            onAuthorTap: (_) => widget.onOpenProfile?.call(),
          ),
        ],
      ),
      centerChild: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VnlfCenterPageHeader(
            title: 'Bài viết',
            onProfileTap: widget.onOpenProfile,
            leading: InkWell(
              borderRadius: BorderRadius.circular(VnlfDimensions.radiusMd),
              onTap: widget.onBackToFeed,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(VnlfDimensions.radiusMd),
                  border: Border.all(color: colors.line),
                ),
                child: Icon(
                  Icons.arrow_back_rounded,
                  size: 17,
                  color: colors.ink,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Full Post Detail Card
          VnlfPostCard(
            post: _post,
            onAuthorTap: widget.onOpenProfile,
            onVoteChanged: (next) {
              final delta = next.value - _post.viewerVote.value;
              setState(() {
                _post = _post.copyWith(
                  viewerVote: next,
                  voteScore: _post.voteScore + delta,
                );
              });
            },
            onBookmarkToggle: () {
              setState(() {
                _post = _post.copyWith(isBookmarked: !_post.isBookmarked);
              });
            },
          ),
          const SizedBox(height: 12),

          // Supplementary Terminal Configuration Block
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(VnlfDimensions.radiusLg),
              border: Border.all(color: colors.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.code_rounded, size: 16, color: colors.brand),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Cấu hình bộ đệm PipeWire quantum 64/48000',
                        style: VnlfTypography.h3(colors.ink),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const VnlfCodeBlock(
                  code:
                      '# Cấu hình PipeWire quantum siêu thấp (Tiếng Việt: ặ ữ ờ ẫ ệ)\n'
                      'default.clock.rate = 48000\n'
                      'default.clock.quantum = 64\n'
                      'default.clock.min-quantum = 32\n'
                      'default.clock.max-quantum = 1024\n'
                      '\n'
                      '# Khởi động lại dịch vụ người dùng\n'
                      'systemctl --user restart pipewire wireplumber',
                  showHorizontalScrollbar: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Inline Comment Composer Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(VnlfDimensions.radiusLg),
              border: Border.all(color: colors.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bình luận (${_post.commentCount})',
                  style: VnlfTypography.h3(colors.ink),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.surfaceSoft,
                    borderRadius: BorderRadius.circular(
                      VnlfDimensions.radiusMd,
                    ),
                    border: Border.all(color: colors.line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chia sẻ góc nhìn hoặc cấu hình của bạn (hỗ trợ Markdown & Tiếng Việt: ặ ữ ờ ẫ ệ)...',
                        style: VnlfTypography.body(colors.muted),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.code_rounded,
                            size: 16,
                            color: colors.muted,
                          ),
                          const SizedBox(width: 10),
                          Icon(
                            Icons.image_outlined,
                            size: 16,
                            color: colors.muted,
                          ),
                          const SizedBox(width: 10),
                          Icon(
                            Icons.alternate_email_rounded,
                            size: 16,
                            color: colors.muted,
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: colors.brand,
                              borderRadius: BorderRadius.circular(
                                VnlfDimensions.radiusMd,
                              ),
                            ),
                            child: Text(
                              'Gửi bình luận',
                              style: VnlfTypography.control(
                                colors.isDark ? colors.bg : colors.surface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Divider(color: colors.line, height: 1),
                const SizedBox(height: 16),

                // Nested Comment Hierarchy
                for (
                  var i = 0;
                  i < VnlfGalleryFixtures.threadComments.length;
                  i++
                ) ...[
                  if (i > 0) ...[
                    const SizedBox(height: 16),
                    Divider(color: colors.line, height: 1),
                    const SizedBox(height: 16),
                  ],
                  VnlfCommentTree(
                    comment: VnlfGalleryFixtures.threadComments[i],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThreadAuthorCard extends StatelessWidget {
  const _ThreadAuthorCard({required this.author, this.onProfileTap});

  final AuthorData author;
  final VoidCallback? onProfileTap;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(VnlfDimensions.radiusLg),
        border: Border.all(color: colors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tác giả bài viết',
            style: VnlfTypography.meta(
              colors.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              VnlfAvatar(author: author, size: 44),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    VnlfAuthorNameRow(author: author, showHandleInline: false),
                    const SizedBox(height: 2),
                    Text(
                      '@${author.username}',
                      style: VnlfTypography.meta(colors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Kỹ sư hệ thống Linux & người đóng góp tài liệu mã nguồn mở cho cộng đồng.',
            style: VnlfTypography.body(colors.ink),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.brand,
                side: BorderSide(color: colors.brand),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(VnlfDimensions.radiusMd),
                ),
                padding: const EdgeInsets.symmetric(vertical: 9),
              ),
              onPressed: onProfileTap,
              child: Text(
                'Xem hồ sơ cá nhân',
                style: VnlfTypography.control(
                  colors.brand,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
