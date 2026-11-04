import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../fixtures/vnlf_gallery_fixtures.dart';

/// Interactive Design Tokens & Component Showcase tab inside `/gallery`.
///
/// Covers all specs in `DESIGN_REFERENCE.md`:
/// - Section 2: Typography (`Be Vietnam Pro`, `Tiếng Việt: ặ ữ ờ ẫ ệ`)
/// - Section 3: Color Tokens (Light `:root` & Dark `html.vnlf-dark`)
/// - Section 4: Radii (`6, 10, 14, 999`) & Shadows
/// - Section 6: Core Component Gallery (Avatar frames, Name effects, Distro badges,
///   Vote capsules, Code block, Post card, Weekly Leaderboard, Chat bubbles).
class VnlfTokensCatalogView extends StatelessWidget {
  const VnlfTokensCatalogView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);

    return Scaffold(
      backgroundColor: colors.bg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Typography Section
                _CatalogSectionCard(
                  title: '1. Typography (Be Vietnam Pro)',
                  subtitle:
                      'Kiểm tra hiển thị dấu thanh: ${VnlfGalleryFixtures.diacriticSample}',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _TypeRow(
                        token: 'text-h1 (18/24 Bold)',
                        style: VnlfTypography.h1(colors.ink),
                        sample:
                            'Bảng tin cộng đồng — ${VnlfGalleryFixtures.diacriticSample}',
                      ),
                      _TypeRow(
                        token: 'text-h2 (16/22 Bold)',
                        style: VnlfTypography.h2(colors.ink),
                        sample:
                            'Xếp hạng tuần & Dự án — ${VnlfGalleryFixtures.diacriticSample}',
                      ),
                      _TypeRow(
                        token: 'text-h3 (14/20 SemiBold)',
                        style: VnlfTypography.h3(colors.ink),
                        sample:
                            'Cấu hình nhân Linux 6.12 — ${VnlfGalleryFixtures.diacriticSample}',
                      ),
                      _TypeRow(
                        token: 'text-body (13/20.8 Regular)',
                        style: VnlfTypography.body(colors.ink),
                        sample:
                            'Trải nghiệm cài đặt Debian 13 + XFCE mượt mà, hỗ trợ đầy đủ ${VnlfGalleryFixtures.diacriticSample}.',
                      ),
                      _TypeRow(
                        token: 'text-control (13/18 Medium)',
                        style: VnlfTypography.control(colors.ink),
                        sample:
                            'Mới nhất · Được chú ý · Article · Đang theo dõi',
                      ),
                      _TypeRow(
                        token: 'text-meta (12/16 Regular)',
                        style: VnlfTypography.meta(colors.muted),
                        sample: '@tranvannam · 1 giờ trước · 42 bình chọn',
                      ),
                      _TypeRow(
                        token: 'text-caption (11/14 Medium)',
                        style: VnlfTypography.caption(colors.brand),
                        sample: '#wayland  #pipewire  #flutter  #linux',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 2. Color Tokens Grid
                _CatalogSectionCard(
                  title: '2. Color Tokens (:root & html.vnlf-dark)',
                  subtitle: 'Bảng màu ngữ nghĩa trích xuất trực tiếp từ vietnamlinuxfamily.net',
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _ColorSwatchTile('--bg', colors.bg),
                      _ColorSwatchTile('--paper', colors.paper),
                      _ColorSwatchTile('--surface', colors.surface),
                      _ColorSwatchTile('--surface-soft', colors.surfaceSoft),
                      _ColorSwatchTile('--ink', colors.ink),
                      _ColorSwatchTile('--muted', colors.muted),
                      _ColorSwatchTile('--text-subtle', colors.textSubtle),
                      _ColorSwatchTile('--line', colors.line),
                      _ColorSwatchTile('--brand', colors.brand),
                      _ColorSwatchTile('--brand-strong', colors.brandStrong),
                      _ColorSwatchTile('--brand-soft', colors.brandSoft),
                      _ColorSwatchTile('--orange', colors.orange),
                      _ColorSwatchTile('--red', colors.red),
                      _ColorSwatchTile('--blue', colors.blue),
                      _ColorSwatchTile('--tier-partner', colors.tierPartner),
                      _ColorSwatchTile('--rating-star', colors.ratingStar),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 3. Radii, Avatar Frames, Distro Badges & Vote Capsules
                _CatalogSectionCard(
                  title: '3. Atomic Components: Avatar Frames, Distro Badges & Vote Capsules',
                  subtitle: 'Các trạng thái bình chọn (neutral / upvoted / downvoted), khung avatar và huy hiệu distro',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 20,
                        runSpacing: 12,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: const [
                          VnlfAuthorNameRow(
                            author: VnlfGalleryFixtures.authorNam,
                          ),
                          VnlfAuthorNameRow(
                            author: VnlfGalleryFixtures.authorMai,
                          ),
                          VnlfAuthorNameRow(
                            author: VnlfGalleryFixtures.authorBao,
                          ),
                          VnlfAuthorNameRow(
                            author: VnlfGalleryFixtures.authorHa,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: const [
                          VnlfDistroBadgePill(
                            badge: DistroBadgeType.caramos,
                            label: 'caramos',
                            iconTooltip: 'caramos',
                          ),
                          VnlfDistroBadgePill(
                            badge: DistroBadgeType.cachyos,
                            label: 'cachyos',
                            iconTooltip: 'cachyos',
                          ),
                          VnlfDistroBadgePill(
                            badge: DistroBadgeType.arch,
                            label: 'arch',
                            iconTooltip: 'arch',
                          ),
                          VnlfDistroBadgePill(
                            badge: DistroBadgeType.debian,
                            label: 'debian',
                            iconTooltip: 'debian',
                          ),
                          VnlfDistroBadgePill(
                            badge: DistroBadgeType.nixos,
                            label: 'nixos',
                            iconTooltip: 'nixos',
                          ),
                          VnlfDistroBadgePill(
                            badge: DistroBadgeType.fedora,
                            label: 'fedora',
                            iconTooltip: 'fedora',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 14,
                        runSpacing: 10,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          VnlfVoteCapsule(
                            score: 4,
                            voteState: VoteState.neutral,
                            semanticLabel:
                                VnlfGalleryFixtures.voteCapsuleSemanticLabel(4),
                            upvoteSemanticLabel:
                                VnlfGalleryFixtures.upvoteSemanticLabel,
                            downvoteSemanticLabel:
                                VnlfGalleryFixtures.downvoteSemanticLabel,
                          ),
                          VnlfVoteCapsule(
                            score: 42,
                            voteState: VoteState.upvoted,
                            semanticLabel:
                                VnlfGalleryFixtures.voteCapsuleSemanticLabel(
                                  42,
                                ),
                            upvoteSemanticLabel:
                                VnlfGalleryFixtures.upvoteSemanticLabel,
                            downvoteSemanticLabel:
                                VnlfGalleryFixtures.downvoteSemanticLabel,
                          ),
                          VnlfVoteCapsule(
                            score: -2,
                            voteState: VoteState.downvoted,
                            semanticLabel:
                                VnlfGalleryFixtures.voteCapsuleSemanticLabel(
                                  -2,
                                ),
                            upvoteSemanticLabel:
                                VnlfGalleryFixtures.upvoteSemanticLabel,
                            downvoteSemanticLabel:
                                VnlfGalleryFixtures.downvoteSemanticLabel,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 4. Direct Messages & Channel Chat Bubbles
                _CatalogSectionCard(
                  title: '4. Direct Messages & Community Channel Chat',
                  subtitle: 'Bong bóng tin nhắn cộng đồng kèm nhãn dán (sticker) và biểu cảm (reactions)',
                  child: Column(
                    children: [
                      for (
                        var i = 0;
                        i < VnlfGalleryFixtures.sampleChatMessages.length;
                        i++
                      ) ...[
                        if (i > 0) const SizedBox(height: 10),
                        VnlfChatBubble(
                          message: VnlfGalleryFixtures.sampleChatMessages[i],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CatalogSectionCard extends StatelessWidget {
  const _CatalogSectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(VnlfDimensions.radiusLg),
        border: Border.all(color: colors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: VnlfTypography.h2(colors.ink)),
          const SizedBox(height: 4),
          Text(subtitle, style: VnlfTypography.meta(colors.muted)),
          const SizedBox(height: 16),
          Divider(color: colors.line, height: 1),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _TypeRow extends StatelessWidget {
  const _TypeRow({
    required this.token,
    required this.style,
    required this.sample,
  });

  final String token;
  final TextStyle style;
  final String sample;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          SizedBox(
            width: 210,
            child: Text(
              token,
              style: VnlfTypography.code(colors.muted).copyWith(fontSize: 11.5),
            ),
          ),
          Expanded(child: Text(sample, style: style)),
        ],
      ),
    );
  }
}

class _ColorSwatchTile extends StatelessWidget {
  const _ColorSwatchTile(this.tokenName, this.color);

  final String tokenName;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final hex =
        '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

    return Container(
      width: 158,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.surfaceSoft,
        borderRadius: BorderRadius.circular(VnlfDimensions.radiusMd),
        border: Border.all(color: colors.line),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(VnlfDimensions.radiusSm),
              border: Border.all(color: colors.line),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tokenName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: VnlfTypography.caption(
                    colors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  hex,
                  style: VnlfTypography.code(colors.muted)
                      .copyWith(fontSize: 10.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
