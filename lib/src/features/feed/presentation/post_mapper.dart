import '../../../design_system/design_system.dart';
import '../../../domain/models.dart';
import '../../shared/presentation/author_mapper.dart';

PostData presentPost(
  FeedPost post, {
  required bool english,
  bool fullContent = false,
}) {
  final article = post.format.toUpperCase() == 'ARTICLE';
  PostAttachment? attachment;
  if (post.attachments.isNotEmpty) {
    attachment = MediaGalleryAttachment(
      List.unmodifiable(
        post.attachments.map(
          (item) => PostMediaData(
            url: item.url,
            mime: item.mime,
            alt: item.alt,
            width: item.width,
            height: item.height,
            posterUrl: item.posterUrl,
            durationMs: item.durationMs,
            state: item.state,
          ),
        ),
      ),
    );
  } else if (post.coverUrl != null &&
      post.coverUrl!.isNotEmpty &&
      !fullContent) {
    attachment = ImagePlaceholderAttachment(
      imageUrl: post.coverUrl,
      semanticLabel: post.coverAlt,
    );
  }

  return PostData(
    id: post.id,
    author: presentAuthor(post.author),
    relativeTime: _timestamp(post.publishedAt, english),
    paragraphs: [
      (fullContent || !article) && post.contentText.isNotEmpty
          ? post.contentText
          : post.excerpt,
    ],
    richContent: (!article || fullContent) ? post.contentJson : null,
    showInlineImages: article && fullContent,
    selectableContent: fullContent,
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
