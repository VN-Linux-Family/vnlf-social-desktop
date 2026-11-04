import 'models.dart';

abstract interface class AuthRepository {
  Future<Session?> currentSession();
}

abstract interface class FeedRepository {
  Future<FeedPage> getFeed({String? cursor});
}

abstract interface class CommunityRepository {
  Future<List<CommunityChannel>> getChannels();
}
