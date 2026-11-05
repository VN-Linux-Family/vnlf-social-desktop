import 'dart:convert';

import '../core/api_client.dart';
import '../domain/models.dart';
import '../domain/repositories.dart';
import 'feed_dto.dart';
import 'field_reader.dart';
import 'leaderboard_dto.dart';
import 'projects_dto.dart';

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
  if (request.path == '/api/v1/discover') {
    return {
      'articles': [
        {
          'id': 'post-synth-1',
          'authorId': 'user-synth-1',
          'slug': 'trai-nghiem-arch-linux-va-wayland',
          'title': 'Trải nghiệm Arch Linux và Wayland',
          'excerpt': 'Chia sẻ kinh nghiệm cấu hình Arch Linux với Hyprland và Wayland mượt mà trên laptop. Tiếng Việt: ặ ữ ờ ẫ ệ',
          'publishedAt': '2026-11-03T14:30:00.000Z',
          'username': 'hoangnam',
          'displayName': 'Hoàng Nam',
          'avatarUrl':
              'https://vietnamlinuxfamily.net/assets/avatars/user1.png',
          'voteScore': 42,
          'commentCount': 8,
          'style': null,
        },
      ],
      'users': [
        {
          'id': 'user-synth-1',
          'username': 'hoangnam',
          'displayName': 'Hoàng Nam',
          'bio': 'Yêu thích Linux, chia sẻ công cụ mã nguồn mở.',
          'role': 'MEMBER',
          'followerCount': 15,
          'avatarUrl':
              'https://vietnamlinuxfamily.net/assets/avatars/user1.png',
          'style': null,
        },
      ],
      'tags': [
        {'id': 't1', 'slug': 'arch-linux', 'name': 'Arch Linux'},
        {'id': 't2', 'slug': 'wayland', 'name': 'Wayland'},
        {'id': 't3', 'slug': 'cachyos', 'name': 'CachyOS'},
        {'id': 't4', 'slug': 'debian', 'name': 'Debian'},
        {'id': 't5', 'slug': 'ubuntu', 'name': 'Ubuntu'},
        {'id': 't6', 'slug': 'hyprland', 'name': 'Hyprland'},
      ],
      'projects': [
        {'id': 'proj-synth-1', 'name': 'vnlf-cli'},
      ],
      'hasMore': false,
    };
  }
  if (request.path == '/api/v1/projects') {
    return {
      'items': [
        {
          'id': 'proj-synth-1',
          'name': 'vnlf-cli',
          'slug': 'vnlf-cli',
          'tagline': 'Công cụ dòng lệnh quản lý gói và cấu hình Linux cộng đồng: ặ ữ ờ ẫ ệ',
          'type': 'tool',
          'tier': 'community',
          'relation': 'owner',
          'seeking': false,
          'featured': true,
          'status': 'active',
          'logoUrl':
              'https://vietnamlinuxfamily.net/assets/projects/vnlf-cli.png',
          'accentColor': '#2563EB',
          'owner': {
            'id': 'user-synth-1',
            'username': 'hoangnam',
            'displayName': 'Hoàng Nam',
            'avatarUrl':
                'https://vietnamlinuxfamily.net/assets/avatars/user1.png',
            'style': null,
          },
          'repo': {
            'provider': 'github',
            'owner': 'vietnamlinuxfamily',
            'name': 'vnlf-cli',
            'url': 'https://github.com/vietnamlinuxfamily/vnlf-cli',
            'stars': 128,
            'forks': 24,
            'language': 'Dart',
            'languageColor': '#00B4AB',
            'archived': false,
            'fork': false,
            'pushedAt': '2026-11-03T18:00:00.000Z',
            'starsWeek': null,
            'unavailable': false,
          },
          'rating': {'average': 4.9, 'count': 35},
          'commentCount': 12,
          'approvedAt': '2026-10-15T08:00:00.000Z',
        },
      ],
      'facets': {
        'languages': [
          {'name': 'Dart', 'color': '#00B4AB', 'count': 1},
        ],
        'types': [
          {'type': 'tool', 'count': 1},
        ],
      },
      'nextCursor': null,
    };
  }
  if (request.path == '/api/v1/leaderboards') {
    return {
      'period': 'week',
      'periodStart': '2026-11-01T00:00:00.000Z',
      'periodEnd': '2026-11-07T23:59:59.999Z',
      'computedAt': '2026-11-04T12:00:00.000Z',
      'items': [
        {
          'userId': 'user-synth-1',
          'username': 'hoangnam',
          'displayName': 'Hoàng Nam',
          'avatarUrl':
              'https://vietnamlinuxfamily.net/assets/avatars/user1.png',
          'earnedPoints': 450,
          'rank': 1,
          'style': {
            'avatarAnimatedUrl': null,
            'distroBadge': 'arch',
            'frame': {
              'id': 'frame-gold',
              'color': {'light': '#D97706', 'dark': '#F59E0B'},
              'color2': null,
            },
            'icon': {
              'name': 'trophy',
              'url': 'https://vietnamlinuxfamily.net/assets/icons/trophy.png',
              'pixelArt': true,
            },
            'nameColor': null,
            'nameEffect': 'none',
            'nameGradient': null,
            'nameplate': {
              'id': 'np-gold',
              'color': null,
              'name': null,
              'name2': null,
            },
            'status': {'emoji': '👑', 'text': 'Top Contributor'},
          },
        },
        {
          'userId': 'user-synth-2',
          'username': 'minhtri',
          'displayName': 'Minh Trí',
          'avatarUrl':
              'https://vietnamlinuxfamily.net/assets/avatars/user2.png',
          'earnedPoints': 320,
          'rank': 2,
          'style': {
            'avatarAnimatedUrl': null,
            'distroBadge': 'cachyos',
            'frame': {
              'id': 'frame-silver',
              'color': {'light': '#4B5563', 'dark': '#9CA3AF'},
              'color2': null,
            },
            'icon': null,
            'nameColor': null,
            'nameEffect': 'none',
            'nameGradient': null,
            'nameplate': null,
            'status': {'emoji': '⚡', 'text': 'Active Builder'},
          },
        },
        {
          'userId': 'user-synth-3',
          'username': 'linhdan',
          'displayName': 'Linh Đan',
          'avatarUrl':
              'https://vietnamlinuxfamily.net/assets/avatars/user3.png',
          'earnedPoints': 280,
          'rank': 3,
          'style': {
            'avatarAnimatedUrl': null,
            'distroBadge': 'debian',
            'frame': null,
            'icon': null,
            'nameColor': null,
            'nameEffect': 'none',
            'nameGradient': null,
            'nameplate': null,
            'status': null,
          },
        },
      ],
    };
  }
  if (request.path != '/api/v1/feed') return null;
  final type = request.query['type'];
  final isArticles = type == 'article' || type == 'articles';
  return {
    'items': request.query.containsKey('cursor')
        ? <Object>[]
        : [
            {
              'id': 'fixture-post-1',
              'authorId': 'user-synth-1',
              'slug': 'chao-mung-cong-dong-linux-viet-nam',
              'title': isArticles
                  ? 'Hướng dẫn Linux từ cộng đồng'
                  : 'Chào mừng đến với Vietnam Linux Family!',
              'excerpt': 'Chào cộng đồng! Tiếng Việt: ặ ữ ờ ẫ ệ',
              'contentText': 'Vietnam Linux Family là nơi chia sẻ kiến thức, kinh nghiệm cài đặt, tối ưu hóa các bản phân phối Linux và phát triển phần mềm mã nguồn mở. Tiếng Việt: ặ ữ ờ ẫ ệ.',
              'contentHtml': '<p>Vietnam Linux Family là nơi chia sẻ kiến thức, kinh nghiệm cài đặt, tối ưu hóa các bản phân phối Linux và phát triển phần mềm mã nguồn mở. Tiếng Việt: ặ ữ ờ ẫ ệ.</p>',
              'contentJson': {
                'type': 'doc',
                'content': [
                  {
                    'type': 'paragraph',
                    'content': [
                      {
                        'type': 'text',
                        'text': 'Vietnam Linux Family là nơi chia sẻ kiến thức. Tiếng Việt: ặ ữ ờ ẫ ệ.',
                      },
                    ],
                  },
                ],
              },
              'coverUrl': null,
              'coverAssetId': null,
              'coverAlt': '',
              'format': isArticles ? 'article' : 'post',
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
  Future<FeedPage> getFeed({
    String? cursor,
    String? type,
    bool refresh = false,
  }) {
    if (refresh) _client.clearCache();
    return _client.get(
      '/api/v1/feed',
      query: {'cursor': ?cursor, 'type': ?type},
      decode: (json) => FeedPageDto.fromJson(json).toDomain(),
    );
  }
}

/// The authenticated response shape is unknown, so no session is fabricated.
final class FixtureAuthRepository implements AuthRepository {
  const FixtureAuthRepository();
  @override
  Future<Session?> currentSession() async => null;

  @override
  Future<Session> login(String login, String password) async {
    return Session(
      userId: 'user-synth-1',
      displayName: login.isNotEmpty ? login : 'Hoàng Nam',
      username: login.isNotEmpty ? login : 'hoangnam',
    );
  }

  @override
  Future<Session> register(
    String email,
    String username,
    String password,
  ) async {
    return Session(
      userId: 'user-synth-1',
      displayName: username,
      username: username,
      email: email,
    );
  }

  @override
  Future<void> logout() async {}
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
      final page = ProjectsPageDto.fromJson(json).toDomain();
      return DiscoverPage(
        items: page.items
            .map((item) => ProjectSummary(id: item.id, name: item.name))
            .toList(),
        nextCursor: page.nextCursor,
      );
    },
  );

  @override
  Future<DiscoverData> getDiscoverData() => _client.get(
    '/api/v1/discover',
    decode: (json) {
      final rawArticles = json['articles'] as List<dynamic>? ?? const [];
      final rawUsers = json['users'] as List<dynamic>? ?? const [];
      final rawTags = json['tags'] as List<dynamic>? ?? const [];
      final rawProjects = json['projects'] as List<dynamic>? ?? const [];

      final articles = rawArticles.whereType<Map<String, dynamic>>().map((
        item,
      ) {
        final authorMap = item['author'] is Map<String, dynamic>
            ? item['author'] as Map<String, dynamic>
            : null;
        return FeedPost(
          id: item['id'] as String? ?? '',
          excerpt: item['excerpt'] as String? ?? item['title'] as String? ?? '',
          title: item['title'] as String?,
          voteScore: item['voteScore'] as int? ?? 0,
          commentCount: item['commentCount'] as int? ?? 0,
          author: Author(
            id:
                authorMap?['id'] as String? ??
                item['authorId'] as String? ??
                '',
            username:
                authorMap?['username'] as String? ??
                item['username'] as String? ??
                '',
            displayName:
                authorMap?['displayName'] as String? ??
                item['displayName'] as String? ??
                item['username'] as String? ??
                '',
            avatarUrl:
                authorMap?['avatarUrl'] as String? ??
                item['avatarUrl'] as String? ??
                '',
            style: styleValue(
              authorMap?['style'] ?? item['style'],
              'article.style',
            ),
          ),
        );
      }).toList();

      final users = rawUsers.whereType<Map<String, dynamic>>().map((item) {
        return Author(
          id: item['id'] as String? ?? '',
          username: item['username'] as String? ?? '',
          displayName:
              item['displayName'] as String? ??
              item['username'] as String? ??
              '',
          avatarUrl: item['avatarUrl'] as String? ?? '',
          role: item['role'] as String? ?? '',
          style: styleValue(item['style'], 'user.style'),
        );
      }).toList();

      final tags = rawTags.whereType<Map<String, dynamic>>().map((item) {
        return DiscoverTag(
          id: item['id'] as String? ?? '',
          slug: item['slug'] as String? ?? '',
          name: item['name'] as String? ?? item['slug'] as String? ?? '',
        );
      }).toList();

      final projects = rawProjects.whereType<Map<String, dynamic>>().map((
        item,
      ) {
        return ProjectSummary(
          id: item['id'] as String? ?? '',
          name: item['name'] as String? ?? '',
        );
      }).toList();

      final hasMoreRaw = json['hasMore'];
      final hasMore = hasMoreRaw is bool
          ? hasMoreRaw
          : hasMoreRaw is Map
          ? hasMoreRaw.values.any((v) => v == true)
          : false;

      return DiscoverData(
        articles: articles,
        users: users,
        tags: tags,
        projects: projects,
        hasMore: hasMore,
      );
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
      final page = LeaderboardPageDto.fromJson(json).toDomain();
      return Leaderboard(
        period: page.period,
        items: page.items
            .map(
              (item) => LeaderboardEntry(
                username: item.username,
                points: item.earnedPoints,
              ),
            )
            .toList(),
      );
    },
  );
}

final class FixtureLeaderboardRepository implements LeaderboardRepository {
  const FixtureLeaderboardRepository(this._client);
  final ApiClient _client;
  @override
  Future<LeaderboardPage> getLeaderboard() => _client.get(
    '/api/v1/leaderboards',
    decode: (json) => LeaderboardPageDto.fromJson(json).toDomain(),
  );
}

final class FixtureProjectsRepository implements ProjectsRepository {
  const FixtureProjectsRepository(this._client);
  final ApiClient _client;
  @override
  Future<ProjectsPage> getProjects() => _client.get(
    '/api/v1/projects',
    decode: (json) => ProjectsPageDto.fromJson(json).toDomain(),
  );
}
