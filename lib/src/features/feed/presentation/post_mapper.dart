import '../../../design_system/design_system.dart';
import '../../../domain/models.dart';
import '../../shared/presentation/author_mapper.dart';

PostData presentPost(FeedPost post, {required bool english}) {
  PostAttachment? attachment;
  if (post.attachments.isNotEmpty) {
    final first = post.attachments.first;
    double aspect = 16 / 9;
    if (first.width != null && first.height != null && first.height! > 0) {
      aspect = (first.width! / first.height!).clamp(0.75, 2.4);
    }
    attachment = ImagePlaceholderAttachment(
      imageUrl: first.url,
      aspectRatio: aspect,
      label: first.alt.isNotEmpty ? first.alt : (post.title ?? ''),
      semanticLabel: first.alt.isNotEmpty ? first.alt : (post.title ?? ''),
    );
  } else if (post.coverUrl != null && post.coverUrl!.isNotEmpty) {
    attachment = ImagePlaceholderAttachment(
      imageUrl: post.coverUrl,
      semanticLabel: post.coverAlt.isNotEmpty
          ? post.coverAlt
          : (post.title ?? ''),
    );
  }

  return PostData(
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
    attachment: attachment,
  );
}

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
