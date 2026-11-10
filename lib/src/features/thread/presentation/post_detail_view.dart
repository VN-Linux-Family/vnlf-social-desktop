import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../design_system/components/vnlf_rich_content.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/models.dart';
import '../../../i18n/vi.dart';
import '../../polls/presentation/poll_card.dart';
import '../../shared/presentation/post_link_preview.dart';
import 'detail_parts.dart';

/// The website's detail page for a regular post (`format: POST`): a header
/// bar, the post in a card, then the comments.
class PostDetailView extends StatelessWidget {
  const PostDetailView({
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
    final phone = isPhoneLayout(context);
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PostDetailHeader(post: post, phone: phone),
            _PostDetailCard(
              post: post,
              detail: detail,
              phone: phone,
              onComment: onComment,
            ),
            SizedBox(height: phone ? 6 : 12),
            comments,
          ],
        ),
      ),
    );
  }
}

class _PostDetailHeader extends StatelessWidget {
  const _PostDetailHeader({required this.post, required this.phone});

  final FeedPost post;
  final bool phone;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    if (phone) {
      final narrow = MediaQuery.sizeOf(context).width <= 520;
      return Container(
        color: colors.surface,
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: [
            Flexible(
              child: DetailBackButton(
                iconSize: narrow ? 21 : 20,
                showLabel: !narrow,
              ),
            ),
            const Spacer(),
            DetailMoreButton(post: post, size: 48),
          ],
        ),
      );
    }
    final views = post.viewCount;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 15),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 68),
        child: Row(
          spacing: 12,
          children: [
            const Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: DetailBackButton(),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    vi.common.baiViet,
                    style: VnlfTypography.body(colors.ink)
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                if (views != null)
                  Tooltip(
                    message: vi.miscViews.chiBanThayLuotXem,
                    child: Text(
                      format(vi.miscViews.luotXem, {
                        'viewCount': NumberFormat.decimalPattern('vi')
                            .format(views),
                      }),
                      style: VnlfTypography.body(colors.muted),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: DetailMoreButton(post: post),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostDetailCard extends ConsumerWidget {
  const _PostDetailCard({
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
    final title = post.title?.trim();
    final showTitle =
        title != null && title.isNotEmpty && title != post.contentText.trim();
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AuthorLine(post: post, detail: detail, phone: phone),
        if (showTitle)
          Padding(
            padding: const EdgeInsets.only(top: 13),
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: VnlfTypography.body(colors.ink).copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                  letterSpacing: -.325,
                ),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 11),
          child: post.contentJson != null
              ? VnlfRichContent(
                  document: post.contentJson!,
                  postStyle: true,
                  selectable: true,
                )
              : SelectableText(
                  post.contentText,
                  style: VnlfTypography.body(colors.ink).copyWith(height: 1.6),
                ),
        ),
        if (detail.attachment != null)
          Padding(
            padding: EdgeInsets.only(top: phone ? 8 : 12),
            child: VnlfPostAttachmentView(attachment: detail.attachment!),
          ),
        if (post.poll != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: PollCard(poll: post.poll!, authorId: post.author.id),
          ),
        if (post.attachments.isEmpty && post.poll == null)
          PostLinkPreview(content: post.contentText),
        if (post.coverUrl case final cover? when cover.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: _DetailCover(url: cover, alt: post.coverAlt),
          ),
        _PostActionBar(
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
              style: VnlfTypography.body(colors.red),
            ),
          ),
      ],
    );
    return Container(
      padding: phone
          ? const EdgeInsets.fromLTRB(16, 8, 16, 4)
          : const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colors.surface,
        border: phone ? null : Border.all(color: colors.line),
        borderRadius: phone
            ? null
            : BorderRadius.circular(VnlfDimensions.radiusLg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            button: true,
            label: format(vi.miscViews.xemHoSo, {
              'displayName': post.author.displayName,
            }),
            excludeSemantics: true,
            child: VnlfProfilePreview.wrap(
              context,
              post.author.username,
              InkWell(
                customBorder: const CircleBorder(),
                onTap: () => openAuthorProfile(context, post),
                child: VnlfAvatar(author: detail.author, size: phone ? 40 : 43),
              ),
            ),
          ),
          SizedBox(width: phone ? 10 : 13),
          Expanded(child: content),
        ],
      ),
    );
  }
}

class _AuthorLine extends StatelessWidget {
  const _AuthorLine({
    required this.post,
    required this.detail,
    required this.phone,
  });

  final FeedPost post;
  final PostData detail;
  final bool phone;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final name = VnlfAuthorNameRow(
      author: detail.author,
      showHandleInline: false,
      allowWrap: false,
    );
    final handle = Text(
      '@${post.author.username}',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: VnlfTypography.body(colors.muted),
    );
    final narrow = MediaQuery.sizeOf(context).width <= 520;
    final link = InkWell(
      onTap: () => openAuthorProfile(context, post),
      child: narrow
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 1,
              children: [name, handle],
            )
          : Row(
              crossAxisAlignment: phone
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              spacing: phone ? 6 : 8,
              children: [
                Flexible(child: name),
                Flexible(child: handle),
              ],
            ),
    );
    return VnlfProfilePreview.wrap(context, post.author.username, link);
  }
}

class _PostActionBar extends ConsumerWidget {
  const _PostActionBar({
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
    final buttons = detailActionButtons(
      context,
      ref,
      post: post,
      detail: detail,
      onComment: onComment,
      phone: phone,
      withLabels: false,
      commentIcon: 19,
      shareIcon: 18,
      bookmarkIcon: 18,
    );
    final vote = DetailVote(post: post, detail: detail);
    if (!phone) {
      return Padding(
        padding: const EdgeInsets.only(top: 14),
        child: Wrap(
          spacing: 13,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [vote, ...buttons],
        ),
      );
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: Row(
        children: [
          Expanded(
            child: Transform.translate(
              offset: const Offset(-10, 0),
              child: Wrap(
                spacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [vote, buttons[0], buttons[1]],
              ),
            ),
          ),
          Transform.translate(offset: const Offset(10, 0), child: buttons[2]),
        ],
      ),
    );
  }
}

class _DetailCover extends StatelessWidget {
  const _DetailCover({required this.url, required this.alt});

  final String url;
  final String alt;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 560),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: colors.line),
          borderRadius: BorderRadius.circular(VnlfDimensions.radiusLg),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(VnlfDimensions.radiusLg - 1),
          child: Image.network(
            url,
            width: double.infinity,
            fit: BoxFit.cover,
            semanticLabel: alt.isEmpty ? null : alt,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}
