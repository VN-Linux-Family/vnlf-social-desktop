import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/api_client.dart';
import '../../shared/presentation/feature_samples.dart';
import '../data/live_profile_relationship_repository.dart';
import '../domain/profile_relationship.dart';
import '../domain/public_profile.dart';
import 'profile_data.dart';

sealed class ProfileRelationshipFailure {
  const ProfileRelationshipFailure();
}

/// The server refused: blocked either way, or a self-targeted request.
final class RelationshipRejected extends ProfileRelationshipFailure {
  const RelationshipRejected();
}

final class RelationshipUserMissing extends ProfileRelationshipFailure {
  const RelationshipUserMissing();
}

final class RelationshipSignedOut extends ProfileRelationshipFailure {
  const RelationshipSignedOut();
}

final class RelationshipRateLimited extends ProfileRelationshipFailure {
  const RelationshipRateLimited();
}

final class RelationshipNetworkFailure extends ProfileRelationshipFailure {
  const RelationshipNetworkFailure();
}

/// The outcome could not be proven by the acknowledgment and a fresh read.
final class RelationshipUnconfirmed extends ProfileRelationshipFailure {
  const RelationshipUnconfirmed();
}

final class ProfileRelationshipState {
  const ProfileRelationshipState({
    this.pending,
    this.failure,
    this.attempted,
    this.completed,
    this.revision = 0,
  });
  final ProfileRelationshipAction? pending;
  final ProfileRelationshipFailure? failure;

  /// The action the last announced outcome belongs to.
  final ProfileRelationshipAction? attempted;
  final ProfileRelationshipAction? completed;

  /// Increments with every announced outcome so identical ones still notify.
  final int revision;
}

typedef ProfileRefresh = Future<PublicProfile?> Function();

class ProfileRelationshipController
    extends StateNotifier<ProfileRelationshipState> {
  ProfileRelationshipController({
    required ProfileRelationshipRepository repository,
    required ProfileRefresh refresh,
    required bool Function() isViewerCurrent,
    required this.viewerId,
    required this.targetId,
  }) : _repository = repository,
       _refresh = refresh,
       _isViewerCurrent = isViewerCurrent,
       super(const ProfileRelationshipState());
  final ProfileRelationshipRepository _repository;
  final ProfileRefresh _refresh;
  final bool Function() _isViewerCurrent;
  final String viewerId;
  final String targetId;
  int _generation = 0;

  bool allows(ProfileRelationshipAction action, PublicProfile profile) {
    if (viewerId.isEmpty || targetId.isEmpty || viewerId == targetId) {
      return false;
    }
    return switch (action) {
      ProfileRelationshipAction.follow =>
        !profile.followedByViewer && !profile.blockedByViewer,
      ProfileRelationshipAction.unfollow => profile.followedByViewer,
      ProfileRelationshipAction.block => !profile.blockedByViewer,
      ProfileRelationshipAction.unblock => profile.blockedByViewer,
    };
  }

  /// Single flight. Never retries: a second attempt needs a new user action.
  Future<void> perform(
    ProfileRelationshipAction action,
    PublicProfile profile,
  ) async {
    if (state.pending != null || !_isViewerCurrent()) return;
    if (!allows(action, profile)) return;
    final generation = ++_generation;
    state = ProfileRelationshipState(
      pending: action,
      revision: state.revision,
    );
    try {
      await switch (action) {
        ProfileRelationshipAction.follow => _repository.setFollowing(
          targetId,
          following: true,
        ),
        ProfileRelationshipAction.unfollow => _repository.setFollowing(
          targetId,
          following: false,
        ),
        ProfileRelationshipAction.block => _repository.setBlocked(
          targetId,
          blocked: true,
        ),
        ProfileRelationshipAction.unblock => _repository.setBlocked(
          targetId,
          blocked: false,
        ),
      };
    } on Object catch (error) {
      if (!_live(generation)) return;
      final ambiguous = error is! HttpFailure && error is! RateLimited;
      if (ambiguous) await _reconcile();
      if (!_live(generation)) return;
      _finish(action, failure: _classify(error, ambiguous));
      return;
    }
    if (!_live(generation)) return;
    try {
      final fresh = await _refresh();
      if (!_live(generation)) return;
      _finish(
        action,
        failure: fresh != null && _matches(action, fresh)
            ? null
            : _unconfirmed,
        completed: action,
      );
    } on Object {
      if (!_live(generation)) return;
      _finish(action, failure: _unconfirmed);
    }
  }

  static const _unconfirmed = RelationshipUnconfirmed();

  bool _live(int generation) =>
      mounted && generation == _generation && _isViewerCurrent();

  Future<void> _reconcile() async {
    try {
      await _refresh();
    } on Object {
      // The failure that triggered reconciliation is the one reported.
    }
  }

  void _finish(
    ProfileRelationshipAction action, {
    ProfileRelationshipFailure? failure,
    ProfileRelationshipAction? completed,
  }) {
    state = ProfileRelationshipState(
      failure: failure,
      attempted: action,
      completed: failure == null ? completed : null,
      revision: state.revision + 1,
    );
  }

  bool _matches(ProfileRelationshipAction action, PublicProfile fresh) =>
      switch (action) {
        ProfileRelationshipAction.follow => fresh.followedByViewer,
        ProfileRelationshipAction.unfollow => !fresh.followedByViewer,
        ProfileRelationshipAction.block => fresh.blockedByViewer,
        ProfileRelationshipAction.unblock => !fresh.blockedByViewer,
      };

  ProfileRelationshipFailure _classify(Object error, bool ambiguous) {
    if (ambiguous) {
      return error is ParseFailure
          ? _unconfirmed
          : const RelationshipNetworkFailure();
    }
    if (error is RateLimited) return const RelationshipRateLimited();
    if (error is! HttpFailure) return const RelationshipNetworkFailure();
    return switch (error.statusCode) {
      401 => const RelationshipSignedOut(),
      400 || 403 => const RelationshipRejected(),
      404 => const RelationshipUserMissing(),
      429 => const RelationshipRateLimited(),
      _ => const RelationshipNetworkFailure(),
    };
  }

  @override
  void dispose() {
    _generation++;
    super.dispose();
  }
}

typedef ProfileRelationshipKey = ({
  String viewerId,
  String targetId,
  String username, // The profileProvider family key.
});

final profileRelationshipRepositoryProvider =
    Provider<ProfileRelationshipRepository?>((ref) {
      if (offlineFeatures) return null;
      return LiveProfileRelationshipRepository(ref.watch(apiClientProvider));
    });

/// Scoped to the signed-in account: a different viewer id is a new controller,
/// and the old one drops its late results.
final profileRelationshipProvider = StateNotifierProvider.autoDispose
    .family<
      ProfileRelationshipController,
      ProfileRelationshipState,
      ProfileRelationshipKey
    >((ref, key) {
      final repository = ref.watch(profileRelationshipRepositoryProvider)!;
      return ProfileRelationshipController(
        repository: repository,
        viewerId: key.viewerId,
        targetId: key.targetId,
        isViewerCurrent: () =>
            ref.read(sessionStateProvider)?.userId == key.viewerId,
        refresh: () {
          // A write may have happened without us seeing the answer.
          ref.read(apiClientProvider).clearCache();
          return ref.refresh(profileProvider(key.username).future);
        },
      );
    });
