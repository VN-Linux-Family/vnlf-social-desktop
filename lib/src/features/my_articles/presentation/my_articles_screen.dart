import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/providers.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/models.dart';
import '../../../i18n/vi.dart';
import '../../feed/presentation/feed_notifier.dart';
import '../../profile/presentation/profile_actions.dart';
import '../../shared/presentation/post_interactions.dart';
import '../../shared/presentation/post_menu.dart';
import 'my_articles_providers.dart';

enum _Tab { drafts, published, archived }

/// The website's "Bài viết của bạn" (`MyArticlesView`): drafts, published and
/// archived posts, with edit, archive, restore and delete.
class MyArticlesScreen extends ConsumerStatefulWidget {
  const MyArticlesScreen({super.key});

  @override
  ConsumerState<MyArticlesScreen> createState() => _MyArticlesScreenState();
}

class _MyArticlesScreenState extends ConsumerState<MyArticlesScreen> {
  _Tab _tab = _Tab.drafts;
  final _busy = <String>{};

  void _reload() {
    ref.invalidate(myDraftsProvider);
    ref.invalidate(myPostsProvider);
  }

  Future<void> _run(
    FeedPost post,
    Future<void> Function() action, {
    String? done,
    bool feed = true,
  }) async {
    if (!_busy.add(post.id)) return;
    setState(() {});
    try {
      await action();
      if (!mounted) return;
      if (done != null) showVnlfToast(context, done);
      _reload();
      if (feed) {
        ref.invalidate(feedNotifierProvider);
        ref.invalidate(feedProvider);
      }
    } on AppFailure {
      if (mounted) showVnlfToast(context, vi.myArticlesView.chuaThucHienDuoc);
    } finally {
      _busy.remove(post.id);
      if (mounted) setState(() {});
    }
  }

  Future<void> _delete(FeedPost post) async {
    final draft = post.status == 'DRAFT';
    final confirmed = await showVnlfConfirm(
      context,
      title: draft
          ? vi.myArticlesView.xoaBanNhapNay
          : vi.myArticlesView.xoaNoiDungNay,
      description: format(
        draft
            ? vi.myArticlesView.banNhapSeBiXoa
            : vi.myArticlesView.baiSeBienMat,
        {'title': deleteConfirmTitle(post)},
      ),
      confirmLabel: vi.common.xoa,
    );
    if (!confirmed || !mounted) return;
    await _run(
      post,
      () => ref.read(postActionsRepositoryProvider).deletePost(post.id),
      done: draft
          ? vi.myArticlesView.daXoaDraft
          : vi.myArticlesView.daXoaMemBaiViet,
      feed: !draft,
    );
  }

  Future<void> _archive(FeedPost post) async {
    final confirmed = await showVnlfConfirm(
      context,
      title: vi.myArticlesView.luuTruBaiViet,
      description: format(vi.myArticlesView.baiSeAnKhoiBangTin, {
        'title': deleteConfirmTitle(post),
      }),
      confirmLabel: vi.myArticlesView.luuTru2,
      danger: false,
    );
    if (!confirmed || !mounted) return;
    await _run(
      post,
      () => ref.read(myArticlesRepositoryProvider).archive(post.id),
      done: vi.myArticlesView.daLuuTruBaiViet,
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionStateProvider);
    final colors = VnlfColors.of(context);
    final phone =
        VnlfViewportSize.fromWidth(MediaQuery.sizeOf(context).width) ==
        VnlfViewportSize.mobile;
    final drafts = ref.watch(myDraftsProvider);
    final posts = ref.watch(myPostsProvider);
    final published = [
      for (final post in posts.valueOrNull ?? const <FeedPost>[])
        if (post.status == 'PUBLISHED') post,
    ];
    final archived = [
      for (final post in posts.valueOrNull ?? const <FeedPost>[])
        if (post.status == 'ARCHIVED') post,
    ];
    final current = switch (_tab) {
      _Tab.drafts => drafts,
      _Tab.published || _Tab.archived => posts,
    };
    final shown = switch (_tab) {
      _Tab.drafts => drafts.valueOrNull ?? const <FeedPost>[],
      _Tab.published => published,
      _Tab.archived => archived,
    };
    final Widget body;
    if (current.hasError) {
      body = VnlfStateCard(
        icon: Icons.error_outline,
        isError: true,
        title: vi.error.chuaTaiDuocNoiDung,
        message: '',
        actionLabel: vi.common.thuLai,
        onAction: _reload,
      );
    } else if (current.isLoading && !current.hasValue) {
      body = const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    } else {
      body = _ArticleList(
        posts: shown,
        phone: phone,
        busy: _busy,
        onEdit: (post) =>
            context.push('/compose/${Uri.encodeComponent(post.id)}'),
        onArchive: _archive,
        onRestore: (post) => _run(
          post,
          () => ref.read(myArticlesRepositoryProvider).restore(post.id),
          feed: false,
        ),
        onDelete: _delete,
      );
    }
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 980),
        child: ListView(
          padding: phone
              ? EdgeInsets.fromLTRB(
                  8,
                  10,
                  8,
                  68 + MediaQuery.viewPaddingOf(context).bottom,
                )
              : const EdgeInsets.fromLTRB(0, 25, 0, 40),
          children: [
            _Toolbar(
              phone: phone,
              onProfile: () => context.push(
                session == null
                    ? '/login'
                    : '/profile/${Uri.encodeComponent(session.username)}',
              ),
              onCompose: () => context.push('/compose'),
            ),
            SizedBox(height: phone ? 25 : 17),
            Semantics(
              container: true,
              label: vi.myArticlesView.trangThaiBaiViet,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: colors.line)),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    spacing: phone ? 12 : 7,
                    children: [
                      for (final (tab, label, count) in [
                        (
                          _Tab.drafts,
                          vi.myArticlesView.draft,
                          drafts.valueOrNull?.length ?? 0,
                        ),
                        (
                          _Tab.published,
                          vi.myArticlesView.daDang,
                          published.length,
                        ),
                        (
                          _Tab.archived,
                          vi.myArticlesView.luuTru,
                          archived.length,
                        ),
                      ])
                        _TabButton(
                          label: format(label, {'count': count}),
                          selected: _tab == tab,
                          phone: phone,
                          onTap: () => setState(() => _tab = tab),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 17),
            body,
          ],
        ),
      ),
    );
  }
}

/// "Bài của bạn" over the title on wider screens, then "Hồ sơ" and
/// "Viết bài mới".
class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.phone,
    required this.onProfile,
    required this.onCompose,
  });

  final bool phone;
  final VoidCallback onProfile;
  final VoidCallback onCompose;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      spacing: phone ? 5 : 8,
      children: [
        ProfileOutlineButton(
          label: vi.common.hoSo,
          icon: VnlfLucide.arrowLeft,
          onPressed: onProfile,
          minHeight: phone ? 48 : null,
        ),
        Material(
          color: colors.brand,
          borderRadius: BorderRadius.circular(VnlfDimensions.radiusSm),
          child: InkWell(
            borderRadius: BorderRadius.circular(VnlfDimensions.radiusSm),
            onTap: onCompose,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: phone ? 48 : 32),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 5,
                  children: [
                    const VnlfIcon(
                      VnlfLucide.plus,
                      size: 15,
                      color: Colors.white,
                    ),
                    Text(
                      vi.myArticlesView.vietBaiMoi,
                      style: VnlfTypography.control(
                        Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
    if (phone) {
      return Align(alignment: Alignment.centerRight, child: actions);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 7,
            children: [
              Text(
                vi.myArticlesView.yourWriting,
                style: VnlfTypography.meta(
                  colors.textSubtle,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Semantics(
                header: true,
                child: Text(
                  vi.common.baiVietCuaBan,
                  style: VnlfTypography.h2(colors.ink)
                      .copyWith(height: 1.3, letterSpacing: -0.52),
                ),
              ),
            ],
          ),
        ),
        actions,
      ],
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.selected,
    required this.phone,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool phone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: phone ? 48 : 0),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: selected ? colors.brand : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 2,
                vertical: phone ? 7 : 10,
              ),
              child: Center(
                widthFactor: 1,
                child: Text(
                  label,
                  style: VnlfTypography.control(
                    selected ? colors.brand : colors.muted,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ArticleList extends StatelessWidget {
  const _ArticleList({
    required this.posts,
    required this.phone,
    required this.busy,
    required this.onEdit,
    required this.onArchive,
    required this.onRestore,
    required this.onDelete,
  });

  final List<FeedPost> posts;
  final bool phone;
  final Set<String> busy;
  final ValueChanged<FeedPost> onEdit;
  final ValueChanged<FeedPost> onArchive;
  final ValueChanged<FeedPost> onRestore;
  final ValueChanged<FeedPost> onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(VnlfDimensions.radiusLg),
      ),
      child: posts.isEmpty
          ? ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 190),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 7,
                  children: [
                    VnlfIcon(
                      VnlfLucide.bookOpen,
                      size: 24,
                      color: colors.muted,
                    ),
                    Text(
                      vi.myArticlesView.chuaCoBaiTrongMuc,
                      style: VnlfTypography.control(
                        colors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      vi.myArticlesView.vietMoiHoacChuyenBai,
                      textAlign: TextAlign.center,
                      style: VnlfTypography.meta(colors.muted),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var index = 0; index < posts.length; index++)
                  _ArticleRow(
                    post: posts[index],
                    phone: phone,
                    last: index == posts.length - 1,
                    busy: busy.contains(posts[index].id),
                    onEdit: () => onEdit(posts[index]),
                    onArchive: () => onArchive(posts[index]),
                    onRestore: () => onRestore(posts[index]),
                    onDelete: () => onDelete(posts[index]),
                  ),
              ],
            ),
    );
  }
}

/// `articleExcerpt`: the excerpt, or the text on one line, at most 180.
String _excerpt(FeedPost post) {
  final excerpt = post.excerpt.trim();
  final text = excerpt.isNotEmpty
      ? excerpt
      : post.contentText.replaceAll(RegExp(r'\s+'), ' ').trim();
  return text.length > 180 ? '${text.substring(0, 177).trim()}…' : text;
}

class _ArticleRow extends StatelessWidget {
  const _ArticleRow({
    required this.post,
    required this.phone,
    required this.last,
    required this.busy,
    required this.onEdit,
    required this.onArchive,
    required this.onRestore,
    required this.onDelete,
  });

  final FeedPost post;
  final bool phone;
  final bool last;
  final bool busy;
  final VoidCallback onEdit;
  final VoidCallback onArchive;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final narrow = MediaQuery.sizeOf(context).width <= 620;
    final draft = post.status == 'DRAFT';
    final updated = post.updatedAt == null
        ? ''
        : DateFormat('HH:mm:ss d/M/yyyy').format(post.updatedAt!.toLocal());
    final excerpt = _excerpt(post);
    final cover = post.coverUrl ?? '';
    final thumb = Container(
      width: narrow ? 62 : 92,
      height: narrow ? 55 : 64,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.brandSoft,
        borderRadius: BorderRadius.circular(VnlfDimensions.radiusMd),
      ),
      child: cover.isEmpty
          ? Center(
              child: VnlfIcon(
                VnlfLucide.fileText,
                size: 19,
                color: colors.muted,
              ),
            )
          : Image.network(
              cover,
              fit: BoxFit.cover,
              semanticLabel: post.coverAlt,
              errorBuilder: (context, error, stack) => Center(
                child: VnlfIcon(
                  VnlfLucide.fileText,
                  size: 19,
                  color: colors.muted,
                ),
              ),
            ),
    );
    final heading = Text(
      deleteConfirmTitle(post),
      style: VnlfTypography.control(colors.ink, fontWeight: FontWeight.w700),
    );
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          draft
              ? format(vi.myArticlesView.draft2, {'value': updated})
              : '${post.status} · $updated',
          style: VnlfTypography.meta(colors.muted)
              .copyWith(letterSpacing: 0.39),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: post.status == 'PUBLISHED' && post.slug.isNotEmpty
              ? InkWell(
                  onTap: () =>
                      context.push('/a/${Uri.encodeComponent(post.slug)}'),
                  child: heading,
                )
              : heading,
        ),
        Text(
          draft && excerpt.isEmpty
              ? vi.myArticlesView.draftChuaCoNoiDung
              : excerpt,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: VnlfTypography.meta(colors.muted),
        ),
      ],
    );
    final actions = Wrap(
      alignment: WrapAlignment.end,
      spacing: 4,
      runSpacing: 4,
      children: [
        _RowAction(
          icon: VnlfLucide.penLine,
          label: vi.common.sua,
          onPressed: busy ? null : onEdit,
        ),
        if (post.status == 'PUBLISHED')
          _RowAction(
            icon: VnlfLucide.archive,
            label: vi.myArticlesView.luuTru2,
            onPressed: busy ? null : onArchive,
          ),
        if (post.status == 'ARCHIVED')
          _RowAction(
            icon: VnlfLucide.rotateCcw,
            label: vi.common.khoiPhuc,
            onPressed: busy ? null : onRestore,
          ),
        _RowAction(
          icon: VnlfLucide.trash2,
          label: vi.common.xoa,
          danger: true,
          onPressed: busy ? null : onDelete,
        ),
      ],
    );
    final gap = phone ? 8.0 : 13.0;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: last ? null : Border(bottom: BorderSide(color: colors.line)),
      ),
      child: Padding(
        padding: EdgeInsets.all(phone ? 9 : 14),
        child: narrow
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: gap,
                children: [
                  Row(
                    spacing: gap,
                    children: [
                      thumb,
                      Expanded(child: text),
                    ],
                  ),
                  Align(alignment: Alignment.centerRight, child: actions),
                ],
              )
            : Row(
                spacing: gap,
                children: [
                  thumb,
                  Expanded(child: text),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 175),
                    child: actions,
                  ),
                ],
              ),
      ),
    );
  }
}

class _RowAction extends StatelessWidget {
  const _RowAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.danger = false,
  });

  final VnlfLucide icon;
  final String label;
  final VoidCallback? onPressed;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final phone =
        VnlfViewportSize.fromWidth(MediaQuery.sizeOf(context).width) ==
        VnlfViewportSize.mobile;
    final ink = danger ? colors.red : colors.brand;
    final radius = BorderRadius.circular(VnlfDimensions.radiusSm);
    return Material(
      color: colors.surfaceSoft,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: colors.line),
      ),
      child: InkWell(
        borderRadius: radius,
        onTap: onPressed,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: phone ? 48 : 0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 4,
              children: [
                VnlfIcon(icon, size: 15, color: ink),
                Text(label, style: VnlfTypography.meta(ink)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
