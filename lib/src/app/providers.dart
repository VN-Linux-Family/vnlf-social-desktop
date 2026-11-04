import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../core/io_api_transport.dart';
import '../core/session_storage.dart';
import '../data/fixture_repositories.dart';
import '../domain/models.dart';
import '../domain/repositories.dart';

final sessionStorageProvider = Provider<SessionStorage>(
  (ref) => const SecureSessionStorage(),
);

/// Live requests are enabled only by an explicit build-time opt-in.
final apiClientProvider = Provider<ApiClient>((ref) {
  if (!const bool.fromEnvironment('VNLF_LIVE')) {
    return ApiClient(transport: fixtureTransport);
  }
  final uri = Uri.parse('https://vietnamlinuxfamily.net');
  final transport = IoApiTransport(uri);
  ref.onDispose(transport.close);
  return ApiClient(transport: transport.call);
});
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => const FixtureAuthRepository(),
);
final feedRepositoryProvider = Provider<FeedRepository>(
  (ref) => FixtureFeedRepository(ref.watch(apiClientProvider)),
);
final communityRepositoryProvider = Provider<CommunityRepository>(
  (ref) => const FixtureCommunityRepository(),
);
final channelsRepositoryProvider = Provider<ChannelsRepository>(
  (ref) => const FixtureCommunityRepository(),
);
final postRepositoryProvider = Provider<PostRepository>(
  (ref) => FixturePostRepository(ref.watch(feedRepositoryProvider)),
);
final discoverRepositoryProvider = Provider<DiscoverRepository>(
  (ref) => FixtureDiscoverRepository(ref.watch(apiClientProvider)),
);
final leaderboardsRepositoryProvider = Provider<LeaderboardsRepository>(
  (ref) => FixtureLeaderboardsRepository(ref.watch(apiClientProvider)),
);

final sessionProvider = FutureProvider<Session?>(
  (ref) => ref.watch(authRepositoryProvider).currentSession(),
);
final feedProvider = FutureProvider.family<FeedPage, String?>(
  (ref, cursor) => ref.watch(feedRepositoryProvider).getFeed(cursor: cursor),
);
final communityChannelsProvider = FutureProvider<List<CommunityChannel>>(
  (ref) => ref.watch(communityRepositoryProvider).getChannels(),
);
