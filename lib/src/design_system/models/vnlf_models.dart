import 'package:flutter/material.dart';

/// Avatar frame types: neutral generic ring in core design system.
/// Unconfirmed site cosmetic effects (matrix, neon, stars) are isolated in unconfirmed_avatar_frames.dart.
enum AvatarFrameType { none, ring }

/// Name effect types from `DESIGN_REFERENCE.md` and `API_NOTES.md`.
enum NameEffectType { none, rainbow, glitch, cursor }

/// Linux distribution badges displayed next to author names.
enum DistroBadgeType { none, arch, debian, cachyos, caramos, nixos, fedora }

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
  });

  final Color? nameColor;
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
  });

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

  PostData copyWith({
    int? voteScore,
    VoteState? viewerVote,
    bool? isBookmarked,
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
  });

  final String id;
  final AuthorData author;
  final String relativeTime;
  final String body;
  final String? inlineCode;
  final int voteScore;
  final VoteState viewerVote;
  final List<CommentNodeData> replies;
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
