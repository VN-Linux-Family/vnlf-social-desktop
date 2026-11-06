import '../../polls/presentation/poll_state.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../domain/models.dart';
import '../../shared/presentation/feature_samples.dart';
import '../data/fixture_public_profile_repository.dart';
import '../data/live_public_profile_repository.dart';
import '../domain/public_profile.dart';

final publicProfileRepositoryProvider = Provider<PublicProfileRepository>((
  ref,
) {
  if (!offlineFeatures) {
    return LivePublicProfileRepository(ref.watch(apiClientProvider));
  }
  return FixturePublicProfileRepository(
    feed: ref.watch(feedRepositoryProvider),
    rankings: ref.watch(leaderboardRepositoryProvider),
    projects: ref.watch(projectsRepositoryProvider),
    sampleAuthor: sampleAuthor,
    samplePost: samplePost,
  );
});

final profileProvider = FutureProvider.autoDispose
    .family<PublicProfile?, String>((ref, username) async {
      ref.watch(sessionStateProvider.select((session) => session?.userId));
      if (username == 'self') {
        username = ref.watch(sessionProvider).valueOrNull?.username ?? '';
        if (username.isEmpty) return null;
      }
      return ref.watch(publicProfileRepositoryProvider).getProfile(username);
    });

final profilePostsProvider = FutureProvider.autoDispose
    .family<FeedPage, String>((ref, username) async {
      ref.watch(sessionStateProvider.select((session) => session?.userId));
      final pollRead = ref.read(pollStoreProvider.notifier).beginRead();
      final page = await ref
          .watch(publicProfileRepositoryProvider)
          .getPosts(username);
      pollRead.acceptAll(page.items.map((post) => post.poll));
      return page;
    });
final profileCommentsProvider = FutureProvider.autoDispose
    .family<ProfileCommentsPage, String>((ref, username) {
      ref.watch(sessionStateProvider.select((session) => session?.userId));
      return ref.watch(publicProfileRepositoryProvider).getComments(username);
    });
final profileProjectsProvider = FutureProvider.autoDispose
    .family<ProjectsPage, String>((ref, username) {
      ref.watch(sessionStateProvider.select((session) => session?.userId));
      return ref.watch(publicProfileRepositoryProvider).getProjects(username);
    });
final profileGuestbookProvider = FutureProvider.autoDispose
    .family<GuestbookPage, String>((ref, username) {
      ref.watch(sessionStateProvider.select((session) => session?.userId));
      return ref.watch(publicProfileRepositoryProvider).getGuestbook(username);
    });
