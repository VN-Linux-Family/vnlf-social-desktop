import '../core/api_client.dart';
import '../domain/models.dart';
import '../domain/repositories.dart';
import 'feed_dto.dart';

/// Synthetic content using the confirmed public feed response shape.
Future<Map<String, dynamic>> fixtureTransport(ApiRequest request) async {
  if (request.path != '/api/v1/feed') throw const HttpFailure(404);
  return {
    'items': request.query.containsKey('cursor')
        ? <Object>[]
        : [
            {
              'id': 'fixture-post-1',
              'excerpt': 'Chào cộng đồng! Tiếng Việt: ặ ữ ờ ẫ ệ',
              'voteScore': 3,
              'commentCount': 0,
              'author': {'username': 'thanhvien', 'displayName': 'Thành viên'},
            },
          ],
    'nextCursor': null,
  };
}

final class FixtureFeedRepository implements FeedRepository {
  const FixtureFeedRepository(this._client);
  final ApiClient _client;
  @override
  Future<FeedPage> getFeed({String? cursor}) => _client.get(
    '/api/v1/feed',
    query: {'cursor': ?cursor},
    decode: (json) => FeedPageDto.fromJson(json).toDomain(),
  );
}

/// The authenticated response shape is unknown, so no session is fabricated.
final class FixtureAuthRepository implements AuthRepository {
  const FixtureAuthRepository();
  @override
  Future<Session?> currentSession() async => null;
}

/// Community server payloads have not been captured.
final class FixtureCommunityRepository implements CommunityRepository {
  const FixtureCommunityRepository();
  @override
  Future<List<CommunityChannel>> getChannels() async => const [];
}
