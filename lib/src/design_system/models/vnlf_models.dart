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
  fedora;

  String get label => switch (this) {
    DistroBadgeType.none => '',
    DistroBadgeType.arch => 'arch',
    DistroBadgeType.debian => 'debian',
    DistroBadgeType.cachyos => 'cachyos',
    DistroBadgeType.caramos => 'caramos',
    DistroBadgeType.nixos => 'nixos',
    DistroBadgeType.fedora => 'fedora',
  };
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
    this.nameGradientLight,
    this.nameGradientDark,
    this.frame = AvatarFrameType.none,
    this.nameEffect = NameEffectType.none,
    this.distroBadge = DistroBadgeType.none,
    this.hasTerminalBadge = false,
    this.hasPartnerStar = false,
    this.hasPixelBadge = false,
  });

  final Color? nameColor;
  final List<Color>? nameGradientLight;
  final List<Color>? nameGradientDark;
  final AvatarFrameType frame;
  final NameEffectType nameEffect;
  final DistroBadgeType distroBadge;
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
    this.role = 'MEMBER',
    this.style = const AuthorStyleData(),
    this.avatarPreset = AvatarVisualPreset.tuxMascot,
  });

  final String id;
  final String username;
  final String displayName;
  final String role;
  final AuthorStyleData style;
  final AvatarVisualPreset avatarPreset;
}

/// Sealed attachment hierarchy for feed and thread cards.
sealed class PostAttachment {
  const PostAttachment();
}

/// Renders a neutral image placeholder attachment for offline previews.
@immutable
final class ImagePlaceholderAttachment extends PostAttachment {
  const ImagePlaceholderAttachment({
    this.aspectRatio = 16 / 9,
    this.label = 'Hình ảnh đính kèm',
  });

  final double aspectRatio;
  final String label;
}

/// Renders a dark forest-green terminal code snippet with a "Sao chép" pill.
@immutable
final class CodeBlockAttachment extends PostAttachment {
  const CodeBlockAttachment({
    required this.code,
    this.language = 'python',
    this.showHorizontalScrollbar = true,
  });

  final String code;
  final String language;
  final bool showHorizontalScrollbar;
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
