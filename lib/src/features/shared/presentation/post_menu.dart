import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/models.dart';
import '../../../i18n/vi.dart';
import '../../feed/presentation/feed_notifier.dart';
import '../../moderation/presentation/report_dialog.dart';
import '../../profile/presentation/profile_data.dart';
import '../../thread/presentation/thread_post_provider.dart';
import 'post_interactions.dart';
import 'post_share.dart';

/// The website's post "…" menu (`PostMenu`): save and copy for everyone,
/// edit and delete for the author, hide and report for everyone else.
/// [onDetailPage] sends the author back to the feed after a delete.
Future<void> showPostMenu(
  BuildContext context,
  WidgetRef ref,
  FeedPost post, {
  required Rect anchor,
  bool onDetailPage = false,
}) {
  final session = ref.read(sessionStateProvider);
  final owner = session != null && session.userId == post.author.id;
  final saved =
      ref.read(postInteractionProvider(post.id)).bookmarked ??
      post.viewerBookmarked;
  return showVnlfActionMenu(
    context,
    anchor: anchor,
    label: vi.socialOverlays.tuyChonBaiViet,
    actions: [
      VnlfMenuAction(
        icon: VnlfLucide.bookmark,
        label: saved ? vi.common.boLuuBaiViet : vi.common.luuBaiViet,
        onSelected: () => togglePostBookmark(context, ref, post),
      ),
      VnlfMenuAction(
        icon: VnlfLucide.link2,
        label: vi.socialOverlays.saoChepLienKet,
        onSelected: () => copyPostLink(context, post),
      ),
      if (owner) ...[
        VnlfMenuAction(
          icon: VnlfLucide.penLine,
          label: vi.socialOverlays.suaBai,
          onSelected: () =>
              context.push('/compose/${Uri.encodeComponent(post.id)}'),
        ),
        VnlfMenuAction(
          icon: VnlfLucide.trash2,
          label: vi.socialOverlays.xoaBai,
          danger: true,
          onSelected: () =>
              _deletePost(context, ref, post, onDetailPage: onDetailPage),
        ),
      ] else ...[
        VnlfMenuAction(
          icon: VnlfLucide.eye,
          label: vi.socialOverlays.anBaiViet,
          onSelected: () => _hidePost(context, ref, post),
        ),
        VnlfMenuAction(
          icon: VnlfLucide.flag,
          label: vi.common.baoCao,
          danger: true,
          onSelected: () => showArticleReport(context, ref, post.id),
        ),
      ],
    ],
  );
}

bool _needsSignIn(Object? failure) =>
    failure is HttpFailure && failure.statusCode == 401;

/// Votes on [post]; a guest is sent to sign in, as on the website.
Future<void> votePost(
  BuildContext context,
  WidgetRef ref,
  FeedPost post,
  VoteState value,
) async {
  await ref.read(postInteractionsProvider.notifier).vote(post.id, value);
  if (!context.mounted) return;
  if (_needsSignIn(ref.read(postInteractionProvider(post.id)).failure)) {
    await context.push('/login');
  }
}

/// Saves or unsaves [post]. A guest is sent to sign in and any other
/// failure says so in a toast, like the website.
Future<void> togglePostBookmark(
  BuildContext context,
  WidgetRef ref,
  FeedPost post,
) async {
  await ref
      .read(postInteractionsProvider.notifier)
      .toggleBookmark(post.id, initialValue: post.viewerBookmarked);
  if (!context.mounted) return;
  final failure = ref.read(postInteractionProvider(post.id)).failure;
  if (_needsSignIn(failure)) {
    await context.push('/login');
  } else if (failure != null) {
    showVnlfToast(context, vi.socialOverlays.chuaTheCapNhatBai);
  }
}

void _refreshLists(WidgetRef ref, FeedPost post) {
  ref.invalidate(feedNotifierProvider);
  ref.invalidate(feedProvider);
  ref.invalidate(profilePostsProvider(post.author.username));
}

/// The title the delete confirmation quotes, as the website builds it.
String deleteConfirmTitle(FeedPost post) {
  final title = post.title?.trim() ?? '';
  if (title.isNotEmpty) return title;
  final line = post.contentText
      .split('\n')
      .map((line) => line.trim())
      .firstWhere((line) => line.isNotEmpty, orElse: () => '');
  if (line.isEmpty) return vi.articleTypes.baiVietMoi;
  return line.length > 88 ? '${line.substring(0, 85)}…' : line;
}

Future<void> _deletePost(
  BuildContext context,
  WidgetRef ref,
  FeedPost post, {
  required bool onDetailPage,
}) async {
  final confirmed = await showVnlfConfirm(
    context,
    title: vi.socialOverlays.xoaBaiNay,
    description: format(vi.socialOverlays.baiSeBienMat, {
      'title': deleteConfirmTitle(post),
    }),
    confirmLabel: vi.common.xoa,
  );
  if (!confirmed || !context.mounted) return;
  try {
    await ref.read(postActionsRepositoryProvider).deletePost(post.id);
  } on Object {
    if (context.mounted) {
      showVnlfToast(context, vi.socialOverlays.chuaXoaDuocBai);
    }
    return;
  }
  _refreshLists(ref, post);
  ref.invalidate(threadPostProvider(post.id));
  if (!context.mounted) return;
  showVnlfToast(context, vi.socialOverlays.daXoaBai);
  if (onDetailPage) context.go('/');
}

Future<void> _hidePost(
  BuildContext context,
  WidgetRef ref,
  FeedPost post,
) async {
  try {
    await ref.read(postActionsRepositoryProvider).hidePost(post.id);
  } on Object catch (error) {
    if (!context.mounted) return;
    if (_needsSignIn(error)) {
      await context.push('/login');
    } else {
      showVnlfToast(context, vi.socialOverlays.chuaTheAnBaiViet);
    }
    return;
  }
  _refreshLists(ref, post);
}
