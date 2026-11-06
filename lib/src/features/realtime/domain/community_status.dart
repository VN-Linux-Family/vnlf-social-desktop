import '../../../domain/models.dart';
import 'community_topic.dart';

enum CommunityConnectionPhase {
  idle,
  connecting,
  connected,
  reconnecting,
  suspended,
  failed,
  revoked,
  disposed,
}

final class CommunitySocketStatus {
  CommunitySocketStatus(
    this.phase, {
    this.failure,
    this.failureCount = 0,
    Iterable<CommunityTopic> joinedTopics = const [],
  }) : joinedTopics = Set.unmodifiable(joinedTopics);
  final CommunityConnectionPhase phase;
  final AppFailure? failure;
  final int failureCount;
  final Set<CommunityTopic> joinedTopics;
}

final class CommunitySocketIssue {
  const CommunitySocketIssue(this.failure, {this.topic});
  final AppFailure failure;
  final CommunityTopic? topic;
}
