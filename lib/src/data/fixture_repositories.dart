import '../core/api_client.dart';
import '../domain/models.dart';
import '../domain/repositories.dart';
import 'feed_dto.dart';

/// Synthetic content using the confirmed public feed response shape.
Future<Map<String, dynamic>> fixtureTransport(ApiRequest request) async {
  if (request.path == '/api/v1/projects') {
    return {
      'items': <Object>[],
      'nextCursor': null,
      'facets': <String, Object>{},
    };
  }
  if (request.path == '/api/v1/leaderboards') {
    return {
      'period': 'weekly',
      'periodStart': null,
      'periodEnd': null,
      'computedAt': null,
      'items': <Object>[],
    };
  }
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
final class FixtureCommunityRepository implements ChannelsRepository {
  const FixtureCommunityRepository();
  @override
  Future<List<CommunityChannel>> getChannels() async => const [];
}

/// A feed summary is all that is known locally; no detail endpoint is assumed.
final class FixturePostRepository implements PostRepository {
  const FixturePostRepository(this._feed);
  final FeedRepository _feed;
  @override
  Future<FeedPost?> getPost(String id) async {
    final page = await _feed.getFeed();
    for (final post in page.items) {
      if (post.id == id) return post;
    }
    return null;
  }
}

final class FixtureDiscoverRepository implements DiscoverRepository {
  const FixtureDiscoverRepository(this._client);
  final ApiClient _client;
  @override
  Future<DiscoverPage> getProjects() => _client.get(
    '/api/v1/projects',
    decode: (json) {
      if (json['items'] is! List || (json['items'] as List).isNotEmpty) {
        throw const ParseFailure('items');
      }
      final cursor = json['nextCursor'];
      if (cursor != null && cursor is! String) {
        throw const ParseFailure('nextCursor');
      }
      return DiscoverPage(items: const [], nextCursor: cursor as String?);
    },
  );
}

final class FixtureLeaderboardsRepository implements LeaderboardsRepository {
  const FixtureLeaderboardsRepository(this._client);
  final ApiClient _client;
  @override
  Future<Leaderboard> getLeaderboard() => _client.get(
    '/api/v1/leaderboards',
    decode: (json) {
      if (json['items'] is! List || (json['items'] as List).isNotEmpty) {
        throw const ParseFailure('items');
      }
      if (json['period'] is! String) throw const ParseFailure('period');
      return Leaderboard(period: json['period'] as String, items: const []);
    },
  );
}
