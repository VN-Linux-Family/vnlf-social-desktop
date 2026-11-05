import '../../../design_system/design_system.dart';
import '../../../domain/models.dart';
import '../../shared/presentation/author_mapper.dart';

PostData presentPost(FeedPost post, {required bool english}) => PostData(
  id: post.id,
  author: presentAuthor(post.author),
  relativeTime: _timestamp(post.publishedAt, english),
  paragraphs: [post.excerpt.isEmpty ? post.contentText : post.excerpt],
  title: post.title,
  tags: post.tags,
  voteScore: post.voteScore,
  viewerVote: switch (post.viewerVote) {
    1 => VoteState.upvoted,
    -1 => VoteState.downvoted,
    _ => VoteState.neutral,
  },
  commentCount: post.commentCount,
  isBookmarked: post.viewerBookmarked,
  isArticle: post.format.toLowerCase() == 'article',
  attachment: (post.coverUrl != null && post.coverUrl!.isNotEmpty)
      ? ImagePlaceholderAttachment(
          imageUrl: post.coverUrl,
          semanticLabel: post.coverAlt.isNotEmpty
              ? post.coverAlt
              : (post.title ?? ''),
        )
      : null,
);

String _timestamp(DateTime? date, bool english) {
  if (date == null) return '';
  final age = DateTime.now().difference(date);
  if (age.inMinutes < 1) {
    return english ? 'Just now' : 'Vừa xong';
  }
  if (age.inHours < 1) {
    return english ? '${age.inMinutes}m' : '${age.inMinutes} phút';
  }
  if (age.inDays < 1) {
    return english ? '${age.inHours}h' : '${age.inHours} giờ';
  }
  return english ? '${age.inDays}d' : '${age.inDays} ngày';
}
