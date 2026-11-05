import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../design_system/design_system.dart';
import '../../shared/presentation/author_mapper.dart';
import '../../shared/presentation/feature_samples.dart';
import '../data/comments_repository.dart';
import '../domain/article_comment.dart';

final commentsRepositoryProvider = Provider<CommentsRepository>(
  (ref) => offlineFeatures
      ? FixtureCommentsRepository()
      : LiveCommentsRepository(ref.watch(apiClientProvider)),
);

final articleCommentsProvider = FutureProvider.autoDispose
    .family<List<ArticleComment>, String>((ref, id) {
      ref.watch(sessionStateProvider);
      return ref.watch(commentsRepositoryProvider).load(id);
    });

List<CommentNodeData> presentComments(
  List<ArticleComment> comments, {
  required bool english,
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
    relativeTime: comment.createdAt == null
        ? ''
        : _time(comment.createdAt!, english),
    voteScore: comment.voteScore,
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
  return [for (final root in children[null] ?? <ArticleComment>[]) node(root)];
}

String _time(DateTime date, bool english) {
  final age = DateTime.now().difference(date);
  if (age.inMinutes < 1) return english ? 'Just now' : 'Vừa xong';
  if (age.inHours < 1) {
    return english ? '${age.inMinutes}m' : '${age.inMinutes} phút';
  }
  if (age.inDays < 1) return english ? '${age.inHours}h' : '${age.inHours} giờ';
  return english ? '${age.inDays}d' : '${age.inDays} ngày';
}
