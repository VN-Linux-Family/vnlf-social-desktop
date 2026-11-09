import 'models.dart';

abstract interface class AuthRepository {
  Future<Session?> currentSession();
  Future<Session> login(String login, String password);
  Future<Session> register(String email, String username, String password);
  Future<void> logout();
}

abstract interface class FeedRepository {
  Future<FeedPage> getFeed({
    String? cursor,
    String? type,
    bool refresh = false,
  });
}

abstract interface class CommunityRepository {
  Future<List<CommunityChannel>> getChannels();
}

abstract interface class ChannelsRepository implements CommunityRepository {}

abstract interface class PostRepository {
  /// Reads one article by its UUID, or by the slug used in public `/a/` links.
  Future<FeedPost?> getPost(String idOrSlug);
}

abstract interface class DiscoverRepository {
  Future<DiscoverPage> getProjects();
  Future<DiscoverData> getDiscoverData();
}

abstract interface class LeaderboardsRepository {
  Future<Leaderboard> getLeaderboard();
}

abstract interface class LeaderboardRepository {
  Future<LeaderboardPage> getLeaderboard();
}

abstract interface class ProjectsRepository {
  Future<ProjectsPage> getProjects();
}
