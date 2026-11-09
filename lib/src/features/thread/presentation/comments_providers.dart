import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/models.dart';
import '../../../i18n/vi.dart';
import '../../shared/presentation/author_mapper.dart';
import '../../shared/presentation/feature_samples.dart';
import '../data/comments_repository.dart';
import '../data/comment_media_repository.dart';
import '../data/comment_attachment_controller.dart';
import '../data/comment_pending_store.dart';
import '../domain/article_comment.dart';
import 'comment_actions.dart';

final commentsRepositoryProvider = Provider<CommentsRepository>(
  (ref) => offlineFeatures
      ? FixtureCommentsRepository()
      : LiveCommentsRepository(ref.watch(apiClientProvider)),
);

final commentMediaRepositoryProvider = Provider<CommentMediaRepository>(
  (ref) => CommentMediaRepository(ref.watch(apiClientProvider)),
);

final commentAttachmentControllerProvider = Provider.autoDispose
    .family<CommentAttachmentController, String>((ref, id) {
      final owner = ref.watch(
        sessionStateProvider.select((session) => session?.userId),
      );
      return CommentAttachmentController(
        id,
        ref.watch(commentMediaRepositoryProvider),
        ref.watch(commentsRepositoryProvider),
        ref.watch(apiClientProvider),
        store: owner == null
            ? null
            : CommentPendingStore(ref.watch(sessionStorageProvider)),
        ownerId: owner,
      );
    });

final commentAttachmentRecoveryProvider = FutureProvider.autoDispose
    .family<void, String>(
      (ref, id) =>
          ref.watch(commentAttachmentControllerProvider(id)).initialize(),
    );

final articleCommentsProvider = FutureProvider.autoDispose
    .family<List<ArticleComment>, String>((ref, id) async {
      ref.watch(sessionStateProvider);
      final actions = ref.read(commentActionsProvider(id).notifier);
      final revision = actions.revision;
      final items = await ref.watch(commentsRepositoryProvider).load(id);
      // Only a read begun after the last mutation can replace its acknowledged UI.
      actions.acceptFresh(revision);
      return items;
    });

final commentActionsProvider = StateNotifierProvider.autoDispose
    .family<CommentActionsController, CommentActionState, String>((ref, id) {
      ref.watch(sessionStateProvider.select((session) => session?.userId));
      return CommentActionsController(
        ref.watch(commentsRepositoryProvider),
        id,
      );
    });

List<CommentNodeData> presentComments(
  List<ArticleComment> comments, {
  Set<String> pending = const {},
  Map<String, AppFailure> errors = const {},
}) {
  final byId = {for (final comment in comments) comment.id: comment};
  final children = <String?, List<ArticleComment>>{};
  for (final comment in byId.values) {
    var parent = comment.parentId;
    final visited = {comment.id};
    var ancestor = parent;
    while (ancestor != null && byId.containsKey(ancestor)) {
      if (!visited.add(ancestor)) {
        parent = null;
        break;
      }
      ancestor = byId[ancestor]!.parentId;
    }
    if (!byId.containsKey(parent)) parent = null;
    children.putIfAbsent(parent, () => []).add(comment);
  }
  CommentNodeData node(ArticleComment comment) => CommentNodeData(
    id: comment.id,
    author: presentAuthor(comment.author),
    body: comment.content,
    relativeTime: comment.createdAt == null ? '' : _time(comment.createdAt!),
    voteScore: comment.voteScore,
    canEdit: comment.canEdit,
    canDelete: comment.canDelete,
    canPin: comment.canPin,
    pinned: comment.pinned,
    edited: comment.editedAt != null,
    pending: pending.contains(comment.id),
    actionError: errors.containsKey(comment.id)
        ? vi.app.thread.chuaLuuDuocThayDoi
        : null,
    hiddenSticker: comment.gif?.hidden ?? false,
    gif: comment.gif == null || comment.gif!.hidden
        ? null
        : PostMediaData(
            url: comment.gif!.url,
            alt: comment.gif!.title,
            width: comment.gif!.width,
            height: comment.gif!.height,
          ),
    media: [
      for (final a in comment.attachments)
        PostMediaData(
          url: a.url,
          mime: a.mime,
          alt: a.alt,
          width: a.width,
          height: a.height,
        ),
    ],
    viewerVote: switch (comment.viewerVote) {
      1 => VoteState.upvoted,
      -1 => VoteState.downvoted,
      _ => VoteState.neutral,
    },
    replies: [
      for (final child in children[comment.id] ?? <ArticleComment>[])
        node(child),
    ],
  );
  final roots = children[null] ?? <ArticleComment>[];
  return [
    for (final root in roots.where((c) => c.pinned)) node(root),
    for (final root in roots.where((c) => !c.pinned)) node(root),
  ];
}

String _time(DateTime date) {
  final age = DateTime.now().difference(date);
  if (age.inMinutes < 1) return vi.app.common.vuaXong;
  if (age.inHours < 1) {
    return format(vi.app.common.phut, {'inMinutes': age.inMinutes});
  }
  if (age.inDays < 1) {
    return format(vi.app.common.gio, {'inHours': age.inHours});
  }
  return format(vi.app.common.ngay, {'inDays': age.inDays});
}

/// An orphan cannot target its deleted root or become a nested reply on the API.
/// Its reply remains a top-level comment with the recipient mention in its text.
String? commentReplyParent(
  ArticleComment selected,
  Iterable<ArticleComment> visible,
) {
  final ids = {for (final item in visible) item.id};
  if (!ids.contains(selected.id)) return null;
  final parent = selected.parentId;
  return parent == null ? selected.id : (ids.contains(parent) ? parent : null);
}
