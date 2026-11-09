import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../design_system/components/vnlf_rich_content.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/models.dart';
import '../../../i18n/vi.dart';
import '../../moderation/presentation/report_dialog.dart';
import 'detail_parts.dart';

/// Reading time as the website counts it: 220 words a minute, at least 2.
int articleReadMinutes(String text) =>
    math.max(2, (text.trim().split(RegExp(r'\s+')).length / 220).ceil());

/// The website's long-form article page (`format: ARTICLE`): a back bar,
/// the article card, then the comments, 17px apart.
class ArticleDetailView extends StatelessWidget {
  const ArticleDetailView({
    super.key,
    required this.post,
    required this.detail,
    required this.onComment,
    required this.comments,
  });

  final FeedPost post;
  final PostData detail;
  final VoidCallback onComment;
  final Widget comments;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final phone = isPhoneLayout(context);
    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 17,
      children: [
        if (phone)
          Container(
            color: colors.surface,
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerLeft,
            child: const DetailBackButton(iconSize: 16),
          )
        else
          const Align(
            alignment: Alignment.centerLeft,
            child: DetailBackButton(iconSize: 16),
          ),
        _ArticleCard(
          post: post,
          detail: detail,
          phone: phone,
          onComment: onComment,
        ),
        comments,
      ],
    );
    if (phone) return column;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 780),
        child: column,
      ),
    );
  }
}

class _ArticleCard extends ConsumerWidget {
  const _ArticleCard({
    required this.post,
    required this.detail,
    required this.phone,
    required this.onComment,
  });

  final FeedPost post;
  final PostData detail;
  final bool phone;
  final VoidCallback onComment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = VnlfColors.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final body = VnlfTypography.body(colors.ink);
    final title =
        post.title ??
        post.contentText.substring(0, math.min(88, post.contentText.length));
    final padding = phone
        ? const EdgeInsets.fromLTRB(16, 4, 16, 4)
        : width <= 980
        ? const EdgeInsets.fromLTRB(27, 24, 27, 18)
        : const EdgeInsets.fromLTRB(38, 28, 38, 20);
    return Container(
      padding: padding,
      decoration: phone
          ? BoxDecoration(color: colors.surface)
          : BoxDecoration(
              color: colors.surface,
              border: Border.all(color: colors.line),
              borderRadius: BorderRadius.circular(VnlfDimensions.radiusLg),
              boxShadow: [
                BoxShadow(
                  color: colors.isDark
                      ? const Color(0x59000000)
                      : const Color(0x0D101814),
                  offset: const Offset(0, 1),
                  blurRadius: 2,
                ),
              ],
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            spacing: 8,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: colors.brandSoft,
                  borderRadius: BorderRadius.circular(
                    VnlfDimensions.radiusFull,
                  ),
                ),
                child: Text(
                  vi.miscViews.article,
                  style: body.copyWith(
                    color: colors.brand,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .39,
                    height: 1,
                  ),
                ),
              ),
              Flexible(
                child: Text(
                  format(vi.miscViews.phutDoc, {
                    'Math': articleReadMinutes(post.contentText),
                  }),
                  style: body.copyWith(color: colors.muted),
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(
              top: phone ? 12 : 19,
              bottom: phone ? 7 : 10,
            ),
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: body.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.08,
                  letterSpacing: -.65,
                ),
              ),
            ),
          ),
          if (post.excerpt.isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 650),
                child: Text(
                  post.excerpt,
                  style: body.copyWith(color: colors.muted, height: 1.65),
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.only(top: phone ? 14 : 24),
            child: Row(
              spacing: 9,
              children: [
                InkWell(
                  onTap: () => openAuthorProfile(context, post),
                  child: VnlfAvatar(
                    author: detail.author,
                    size: 38,
                    cornerRadius: phone ? null : 10,
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => openAuthorProfile(context, post),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 3,
                      children: [
                        VnlfAuthorNameRow(
                          author: detail.author,
                          showHandleInline: false,
                        ),
                        Text(
                          '@${post.author.username}',
                          style: body.copyWith(color: colors.muted),
                        ),
                      ],
                    ),
                  ),
                ),
                DetailMoreButton(
                  post: post,
                  size: phone ? 48 : 37,
                  iconSize: 18,
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: phone ? 14 : 24),
            child: Divider(height: 1, thickness: 1, color: colors.line),
          ),
          if (post.contentJson != null)
            VnlfRichContent(
              document: post.contentJson!,
              showImages: true,
              selectable: true,
              articleDetail: true,
            )
          else
            SelectableText(post.contentText, style: body.copyWith(height: 1.7)),
          _ArticleActionBar(
            post: post,
            detail: detail,
            phone: phone,
            onComment: onComment,
          ),
          if (detail.actionError != null)
            Semantics(
              liveRegion: true,
              child: Text(
                detail.actionError!,
                style: body.copyWith(color: colors.red),
              ),
            ),
        ],
      ),
    );
  }
}

class _ArticleActionBar extends ConsumerWidget {
  const _ArticleActionBar({
    required this.post,
    required this.detail,
    required this.phone,
    required this.onComment,
  });

  final FeedPost post;
  final PostData detail;
  final bool phone;
  final VoidCallback onComment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = VnlfColors.of(context);
    final buttons = detailActionButtons(
      context,
      ref,
      post: post,
      detail: detail,
      onComment: onComment,
      phone: phone,
      withLabels: !phone,
      commentIcon: 17,
      shareIcon: 16,
      bookmarkIcon: 17,
    );
    final author = ref.watch(sessionStateProvider)?.userId == post.author.id;
    final vote = DetailVote(post: post, detail: detail);
    return Container(
      margin: const EdgeInsets.only(top: 22),
      padding: const EdgeInsets.only(top: 13),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.line)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [vote, buttons[0], buttons[1], if (!phone) buttons[2]],
            ),
          ),
          if (phone)
            buttons[2]
          else if (!author)
            VnlfActionButton(
              icon: VnlfLucide.flag,
              iconSize: 16,
              label: vi.common.baoCao,
              semanticLabel: vi.common.baoCao,
              onPressed: () => showArticleReport(context, ref, post.id),
            ),
        ],
      ),
    );
  }
}
