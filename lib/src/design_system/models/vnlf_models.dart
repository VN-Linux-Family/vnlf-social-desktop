import 'package:flutter/material.dart';

/// Avatar frame types from `DESIGN_REFERENCE.md` and `API_NOTES.md`.
enum AvatarFrameType { none, matrix, neon, stars }

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

/// Renders an authentic Linux desktop + fastfetch/neofetch terminal preview.
@immutable
final class LinuxDesktopAttachment extends PostAttachment {
  const LinuxDesktopAttachment({
    required this.distroHeader,
    required this.terminalTitle,
    required this.userHost,
    required this.osLine,
    required this.kernelLine,
    required this.uptimeLine,
    required this.packagesLine,
    required this.shellLine,
    required this.deLine,
    required this.wmLine,
    required this.cpuLine,
    required this.memoryLine,
  });

  final String distroHeader;
  final String terminalTitle;
  final String userHost;
  final String osLine;
  final String kernelLine;
  final String uptimeLine;
  final String packagesLine;
  final String shellLine;
  final String deLine;
  final String wmLine;
  final String cpuLine;
  final String memoryLine;
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
    required this.summary,
    required this.category,
    required this.language,
    required this.stars,
    required this.forks,
    required this.rating,
    this.tags = const [],
  });

  final String id;
  final String name;
  final String summary;
  final String category;
  final String language;
  final int stars;
  final int forks;
  final double rating;
  final List<String> tags;
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
