import 'package:flutter/material.dart';

/// Avatar frame types: neutral generic ring in core design system.
/// Unconfirmed site cosmetic effects (matrix, neon, stars) are isolated in unconfirmed_avatar_frames.dart.
enum AvatarFrameType { none, ring }

/// Name effect types from `DESIGN_REFERENCE.md` and `API_NOTES.md`.
enum NameEffectType { none, rainbow, glitch, cursor }

/// Linux distribution badges displayed next to author names.
enum DistroBadgeType {
  none,
  arch,
  debian,
  cachyos,
  caramos,
  nixos,
  fedora,
  ubuntu,
  kali,
  gentoo,
  mint,
  linux,
  opensuse,
}

/// Offline vector illustration preset for user avatars (zero network calls).
enum AvatarVisualPreset {
  workspaceCoder,
  retroChef,
  matrixHacker,
  pastelSakura,
  tuxMascot,
  nixosflake,
}

/// Voting capsule state.
enum VoteState {
  neutral(0),
  upvoted(1),
  downvoted(-1);

  const VoteState(this.value);
  final int value;
}

/// Custom author wardrobe styling (`style` object in Post entity schema).
@immutable
class AuthorStyleData {
  const AuthorStyleData({
    this.nameColor,
    this.nameDarkColor,
    this.nameGradientLight,
    this.nameGradientDark,
    this.frame = AvatarFrameType.none,
    this.frameColor,
    this.frameDarkColor,
    this.nameplateId,
    this.nameplateColor,
    this.nameplateDarkColor,
    this.nameEffect = NameEffectType.none,
    this.distroBadge = DistroBadgeType.none,
    this.distroBadgeLabel,
    this.hasTerminalBadge = false,
    this.hasPartnerStar = false,
    this.hasPixelBadge = false,
    this.iconUrl,
    this.iconName,
  });

  final Color? nameColor;
  final Color? nameDarkColor;
  final List<Color>? nameGradientLight;
  final List<Color>? nameGradientDark;
  final AvatarFrameType frame;
  final Color? frameColor;
  final Color? frameDarkColor;
  final String? nameplateId;
  final Color? nameplateColor;
  final Color? nameplateDarkColor;
  final NameEffectType nameEffect;
  final DistroBadgeType distroBadge;
  final String? distroBadgeLabel;
  final bool hasTerminalBadge;
  final bool hasPartnerStar;
  final bool hasPixelBadge;
  final String? iconUrl;
  final String? iconName;
}

/// Immutable author identity model.
@immutable
class AuthorData {
  const AuthorData({
    required this.id,
    required this.username,
    required this.displayName,
    this.role = '',
    this.style = const AuthorStyleData(),
    this.avatarPreset = AvatarVisualPreset.tuxMascot,
    this.avatarUrl = '',
    this.loadNetworkAvatar = false,
  });

  final String id;
  final String username;
  final String displayName;
  final String role;
  final AuthorStyleData style;
  final AvatarVisualPreset avatarPreset;
  final String avatarUrl;
  final bool loadNetworkAvatar;
}

/// Sealed attachment hierarchy for feed and thread cards.
sealed class PostAttachment {
  const PostAttachment();
}

/// Renders an image attachment with optional network loading or neutral fallback.
@immutable
final class ImagePlaceholderAttachment extends PostAttachment {
  const ImagePlaceholderAttachment({
    this.imageUrl,
    this.aspectRatio = 16 / 9,
    this.label = '',
    this.semanticLabel,
  });

  final String? imageUrl;
  final double aspectRatio;
  final String label;
  final String? semanticLabel;
}

@immutable
final class MediaGalleryAttachment extends PostAttachment {
  const MediaGalleryAttachment(this.items);
  final List<PostMediaData> items;
}

@immutable
final class PostMediaData {
  const PostMediaData({
    required this.url,
    this.mime = '',
    this.alt = '',
    this.width,
    this.height,
    this.posterUrl,
    this.durationMs,
    this.state,
  });
  final String url;
  final String mime;
  final String alt;
  final int? width;
  final int? height;
  final String? posterUrl;
  final int? durationMs;
  final String? state;
  bool get isVideo => mime.startsWith('video/');
  double get aspectRatio =>
      width != null && width! > 0 && height != null && height! > 0
      ? width! / height!
      : 16 / 9;
}

/// Renders a dark forest-green terminal code snippet with a copy action pill.
@immutable
final class CodeBlockAttachment extends PostAttachment {
  const CodeBlockAttachment({
    required this.code,
    this.language = '',
    this.showHorizontalScrollbar = true,
    this.copyLabel = '',
    this.copiedLabel = '',
    this.semanticLabel,
    this.copyButtonSemanticLabel,
  });

  final String code;
  final String language;
  final bool showHorizontalScrollbar;
  final String copyLabel;
  final String copiedLabel;
  final String? semanticLabel;
  final String? copyButtonSemanticLabel;
}

/// Renders an embedded open-source project card inside a post.
@immutable
final class ProjectPreviewAttachment extends PostAttachment {
  const ProjectPreviewAttachment({required this.project});

  final ProjectShowcaseData project;
}

/// Immutable post / article entity for presentation.
@immutable
class PostData {
  const PostData({
    required this.id,
    required this.author,
    required this.relativeTime,
    required this.paragraphs,
    this.title,
    this.tags = const [],
    this.attachment,
    this.voteScore = 0,
    this.viewerVote = VoteState.neutral,
    this.commentCount = 0,
    this.isBookmarked = false,
    this.isArticle = false,
    this.richContent,
    this.showInlineImages = false,
    this.selectableContent = false,
    this.actionPending = false,
    this.actionError,
    this.viewCount,
  });

  final Map<String, dynamic>? richContent;
  final bool showInlineImages;
  final bool selectableContent;
  final bool actionPending;
  final String? actionError;
  final String id;
  final AuthorData author;
  final String relativeTime;
  final String? title;
  final List<String> paragraphs;
  final List<String> tags;
  final PostAttachment? attachment;
  final int voteScore;
  final VoteState viewerVote;
  final int commentCount;
  final bool isBookmarked;
  final bool isArticle;

  /// Views, sent only to the author.
  final int? viewCount;

  PostData copyWith({
    int? voteScore,
    VoteState? viewerVote,
    bool? isBookmarked,
    bool? actionPending,
    String? actionError,
  }) {
    return PostData(
      id: id,
      author: author,
      relativeTime: relativeTime,
      title: title,
      paragraphs: paragraphs,
      tags: tags,
      attachment: attachment,
      voteScore: voteScore ?? this.voteScore,
      viewerVote: viewerVote ?? this.viewerVote,
      commentCount: commentCount,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      isArticle: isArticle,
      richContent: richContent,
      showInlineImages: showInlineImages,
      selectableContent: selectableContent,
      actionPending: actionPending ?? this.actionPending,
      actionError: actionError,
      viewCount: viewCount,
    );
  }
}

/// Weekly leaderboard entry (`Xếp hạng tuần`).
@immutable
class LeaderboardEntryData {
  const LeaderboardEntryData({
    required this.rank,
    required this.author,
    required this.points,
  });

  final int rank;
  final AuthorData author;
  final int points;
}

/// Hierarchical comment node for the Thread screen.
@immutable
class CommentNodeData {
  const CommentNodeData({
    required this.id,
    required this.author,
    required this.relativeTime,
    required this.body,
    this.inlineCode,
    this.voteScore = 0,
    this.viewerVote = VoteState.neutral,
    this.replies = const [],
    this.canEdit = false,
    this.canDelete = false,
    this.canPin = false,
    this.pinned = false,
    this.edited = false,
    this.pending = false,
    this.hiddenSticker = false,
    this.actionError,
    this.media = const [],
    this.gif,
    this.date = '',
    this.gifProvider,
    this.gifSticker = false,
    this.gifLink,
    this.mentions = const [],
  });

  final String id;
  final AuthorData author;
  final String relativeTime;

  /// The website's comment date, `d/m/yyyy`.
  final String date;

  /// Who served the GIF or sticker (`KLIPY`, `VNLF`).
  final String? gifProvider;

  /// Stickers have no frame and are smaller than GIFs.
  final bool gifSticker;

  /// Where a KLIPY GIF or sticker opens.
  final String? gifLink;

  /// Usernames that @mentions in [body] point to.
  final List<String> mentions;
  final String body;
  final String? inlineCode;
  final int voteScore;
  final VoteState viewerVote;
  final List<CommentNodeData> replies;
  final bool canEdit, canDelete, canPin, pinned, edited, pending, hiddenSticker;
  final String? actionError;
  final List<PostMediaData> media;
  final PostMediaData? gif;
}

/// Community project showcase item (`Dự án`).
@immutable
class ProjectShowcaseData {
  const ProjectShowcaseData({
    required this.id,
    required this.name,
    required this.description,
    required this.primaryLanguage,
    required this.tag,
    required this.stars,
    required this.forks,
    this.rating = 5.0,
  });

  final String id;
  final String name;
  final String description;
  final String primaryLanguage;
  final String tag;
  final int stars;
  final int forks;
  final double rating;

  String get summary => description;
  String get language => primaryLanguage;
  String get category => tag;
  List<String> get tags => [tag];
}

/// Direct message / channel chat message bubble data.
@immutable
class ChatMessageData {
  const ChatMessageData({
    required this.id,
    required this.author,
    required this.timestamp,
    required this.text,
    this.reactions = const {},
    this.stickerLabel,
  });

  final String id;
  final AuthorData author;
  final String timestamp;
  final String text;
  final Map<String, int> reactions;
  final String? stickerLabel;
}
