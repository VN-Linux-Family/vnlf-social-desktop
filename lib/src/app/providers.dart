import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../core/session_storage.dart';
import '../data/fixture_repositories.dart';
import '../domain/models.dart';
import '../domain/repositories.dart';

final sessionStorageProvider = Provider<SessionStorage>(
  (ref) => const SecureSessionStorage(),
);

/// No network transport is installed by default.
final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(transport: fixtureTransport),
);
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => const FixtureAuthRepository(),
);
final feedRepositoryProvider = Provider<FeedRepository>(
  (ref) => FixtureFeedRepository(ref.watch(apiClientProvider)),
);
final communityRepositoryProvider = Provider<CommunityRepository>(
  (ref) => const FixtureCommunityRepository(),
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
