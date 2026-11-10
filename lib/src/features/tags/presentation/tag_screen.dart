import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/design_system.dart';
import '../../../domain/models.dart';
import '../../../i18n/vi.dart';
import '../../profile/presentation/profile_actions.dart';
import '../../shared/presentation/page_header_actions.dart';
import '../domain/tag_articles.dart';
import 'tag_providers.dart';

/// The website's topic page (`/t/[tag]`): a hero with the tag and its count,
/// then the posts as search rows. "Xem bài cũ hơn" opens the next page on
/// its own, as the website does, instead of growing the list.
class TagScreen extends ConsumerWidget {
  const TagScreen({super.key, required this.slug, this.cursor});

  final String slug;
  final String? cursor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phone =
        VnlfViewportSize.fromWidth(MediaQuery.sizeOf(context).width) ==
        VnlfViewportSize.mobile;
    final gap = phone ? 8.0 : 25.0;
    final List<Widget> content;
    if (!isTagSlug(slug)) {
      content = [
        VnlfStateCard(
          icon: Icons.search_off,
          title: vi.notFound.khongTimThayTrang,
          message: vi.notFound.urlKhongTonTaiHoac,
          actionLabel: vi.common.veBangTin,
          onAction: () => context.go('/'),
        ),
      ];
    } else {
      final query = (slug: slug, cursor: cursor);
      content = ref
          .watch(tagArticlesProvider(query))
          .when(
            loading: () => const [
              Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
            error: (error, stack) => [
              VnlfStateCard(
                icon: Icons.error_outline,
                isError: true,
                title: vi.error.chuaTaiDuocNoiDung,
                message: vi.error.shellVaDieuHuongVan,
                actionLabel: vi.common.thuLai,
                onAction: () => ref.invalidate(tagArticlesProvider(query)),
              ),
            ],
            data: (page) => page == null
                ? [
                    _TagHero(
                      phone: phone,
                      name: slug,
                      text: format(vi.pageTTag.chuaCoBaiVoiTag, {'name': slug}),
                    ),
                    _MoreRow(
                      label: vi.pageTTag.khamPhaChuDeKhac,
                      onPressed: () => context.go('/discover'),
                    ),
                  ]
                : [
                    _TagHero(
                      phone: phone,
                      name: page.name.isEmpty ? slug : page.name,
                      text: format(vi.pageTTag.baiVietPublicTrongCong, {
                        'count': page.total ?? page.items.length,
                      }),
                    ),
                    if (page.items.isNotEmpty) ...[
                      SizedBox(height: gap),
                      _TagRows(posts: page.items),
                    ],
                    if (page.nextCursor case final next?)
                      _MoreRow(
                        label: vi.pageTTag.xemBaiCuHon,
                        onPressed: () => context.push(
                          '/t/${Uri.encodeComponent(slug)}'
                          '?cursor=${Uri.encodeQueryComponent(next)}',
                        ),
                      ),
                  ],
          );
    }
    final list = RefreshIndicator(
      onRefresh: () => isTagSlug(slug)
          ? ref.refresh(
              tagArticlesProvider((slug: slug, cursor: cursor)).future,
            )
          : Future<void>.value(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: phone
            ? EdgeInsets.fromLTRB(
                8,
                10,
                8,
                68 + MediaQuery.viewPaddingOf(context).bottom,
              )
            : const EdgeInsets.only(bottom: 40),
        children: content,
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!phone)
          VnlfCenterPageHeader(
            title: format(vi.socialLayoutClient.chuDe, {'pathname': slug}),
            trailing: const PageHeaderActions(),
          ),
        Expanded(child: list),
      ],
    );
  }
}

/// "CHỦ ĐỀ", the tag, and one line about it (`.explore-hero`).
class _TagHero extends StatelessWidget {
  const _TagHero({required this.phone, required this.name, required this.text});

  final bool phone;
  final String name;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(
          phone ? VnlfDimensions.radiusMd : VnlfDimensions.radiusLg,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(phone ? 16 : 29),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.brandSoft,
                borderRadius: BorderRadius.circular(VnlfDimensions.radiusFull),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                child: Text(
                  vi.pageTTag.chuDe,
                  style: VnlfTypography.caption(
                    colors.brand,
                    fontWeight: FontWeight.w800,
                  ).copyWith(letterSpacing: 0.39),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: phone ? 4 : 6),
              child: Semantics(
                header: true,
                child: Text(
                  '#$name',
                  style: VnlfTypography.h2(colors.ink)
                      .copyWith(letterSpacing: -0.13),
                ),
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Text(text, style: VnlfTypography.body(colors.muted)),
            ),
          ],
        ),
      ),
    );
  }
}

/// The posts as `.search-result-row`s: initials, the title or excerpt, and
/// the author with the upvotes.
class _TagRows extends StatelessWidget {
  const _TagRows({required this.posts});

  final List<FeedPost> posts;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(VnlfDimensions.radiusLg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [for (final post in posts) _TagRow(post: post)],
        ),
      ),
    );
  }
}

class _TagRow extends StatelessWidget {
  const _TagRow({required this.post});

  final FeedPost post;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final title = post.title?.trim().isNotEmpty == true
        ? post.title!
        : post.excerpt;
    return InkWell(
      onTap: post.slug.isEmpty
          ? null
          : () => context.push('/a/${Uri.encodeComponent(post.slug)}'),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: colors.line)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Row(
            spacing: 10,
            children: [
              // The website shows initials here, never the photo.
              Container(
                width: 31,
                height: 31,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF2D6644),
                  borderRadius: BorderRadius.circular(VnlfDimensions.radiusMd),
                ),
                child: Text(
                  VnlfAvatar.initialsOf(post.author.displayName, '?'),
                  style: VnlfTypography.caption(
                    Colors.white,
                    fontWeight: FontWeight.w800,
                  ).copyWith(letterSpacing: -0.52),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 4,
                  children: [
                    Text(
                      title,
                      style: VnlfTypography.control(
                        colors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      format(vi.pageTTag.luotThich, {
                        'displayName': post.author.displayName,
                        'likeCount': post.likeCount,
                      }),
                      style: VnlfTypography.meta(colors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// `.tag-page-more`: one outline button, centred.
class _MoreRow extends StatelessWidget {
  const _MoreRow({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final phone =
        VnlfViewportSize.fromWidth(MediaQuery.sizeOf(context).width) ==
        VnlfViewportSize.mobile;
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Center(
        child: ProfileOutlineButton(
          label: label,
          onPressed: onPressed,
          minHeight: phone ? 48 : null,
        ),
      ),
    );
  }
}
