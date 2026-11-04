import 'dart:convert';

import '../core/api_client.dart';
import '../domain/models.dart';
import '../domain/repositories.dart';
import 'feed_dto.dart';

/// Synthetic content using the confirmed public feed response shape.
Future<ApiResponse> fixtureTransport(ApiRequest request) async {
  if (request.method != 'GET') {
    return ApiResponse(statusCode: 405, body: '{"error":"method_not_allowed"}');
  }
  final fixture = _fixture(request);
  return ApiResponse(
    statusCode: fixture == null ? 404 : 200,
    body: jsonEncode(fixture ?? {'error': 'fixture_not_found'}),
  );
}

Map<String, dynamic>? _fixture(ApiRequest request) {
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
  if (request.path != '/api/v1/feed') return null;
  return {
    'items': request.query.containsKey('cursor')
        ? <Object>[]
        : [
            {
              'id': 'fixture-post-1',
              'authorId': 'user-synth-1',
              'slug': 'chao-mung-cong-dong-linux-viet-nam',
              'title': 'Chào mừng đến với Vietnam Linux Family!',
              'excerpt': 'Chào cộng đồng! Tiếng Việt: ặ ữ ờ ẫ ệ',
              'contentText':
                  'Vietnam Linux Family là nơi chia sẻ kiến thức, kinh nghiệm cài đặt, tối ưu hóa các bản phân phối Linux và phát triển phần mềm mã nguồn mở. Tiếng Việt: ặ ữ ờ ẫ ệ.',
              'contentHtml':
                  '<p>Vietnam Linux Family là nơi chia sẻ kiến thức, kinh nghiệm cài đặt, tối ưu hóa các bản phân phối Linux và phát triển phần mềm mã nguồn mở. Tiếng Việt: ặ ữ ờ ẫ ệ.</p>',
              'contentJson': {
                'type': 'doc',
                'content': [
                  {
                    'type': 'paragraph',
                    'content': [
                      {
                        'type': 'text',
                        'text':
                            'Vietnam Linux Family là nơi chia sẻ kiến thức. Tiếng Việt: ặ ữ ờ ẫ ệ.',
                      },
                    ],
                  },
                ],
              },
              'coverUrl': null,
              'coverAssetId': null,
              'coverAlt': '',
              'format': 'post',
              'status': 'published',
              'version': 1,
              'likeCount': 12,
              'commentCount': 0,
              'bookmarkCount': 8,
              'viewCount': 150,
              'voteScore': 3,
              'viewerVote': 1,
              'viewerLiked': true,
              'viewerBookmarked': false,
              'canEdit': false,
              'poll': null,
              'tagSlugs': ['linux', 'gioi-thieu', 'cong-dong'],
              'tags': ['Linux', 'Giới thiệu', 'Cộng đồng'],
              'publishedAt': '2026-11-04T12:00:00.000Z',
              'updatedAt': '2026-11-04T12:30:00.000Z',
              'assets': <Object>[],
              'attachments': <Object>[],
              'author': {
                'id': 'user-synth-1',
                'username': 'thanhvien',
                'displayName': 'Thành viên',
                'avatarUrl':
                    'https://vietnamlinuxfamily.net/assets/avatars/default.png',
                'role': 'member',
                'style': {
                  'avatarAnimatedUrl': null,
                  'distroBadge': 'arch',
                  'frame': {
                    'id': 'frame-terminal',
                    'color': {'light': '#2563EB', 'dark': '#60A5FA'},
                    'color2': null,
                  },
                  'icon': {
                    'name': 'tux',
                    'url':
                        'https://vietnamlinuxfamily.net/assets/icons/tux.png',
                    'pixelArt': true,
                  },
                  'nameColor': null,
                  'nameEffect': 'none',
                  'nameGradient': null,
                  'nameplate': {
                    'id': 'np-default',
                    'color': null,
                    'name': null,
                    'name2': null,
                  },
                  'status': {'emoji': '🐧', 'text': 'Đang dùng Arch Linux'},
                },
              },
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
