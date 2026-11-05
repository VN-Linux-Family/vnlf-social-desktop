import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/core/api_client.dart';
import 'package:vnlfsocialapp/src/features/leaderboard/data/live_weekly_leaderboard_repository.dart';
import 'package:vnlfsocialapp/src/features/leaderboard/domain/leaderboard_week.dart';
import 'package:vnlfsocialapp/src/features/search/data/live_search_repository.dart';
import 'package:vnlfsocialapp/src/features/search/domain/search_results.dart';

void main() {
  test(
    'server search uses q and maps flat authors, topics and group limits',
    () async {
      final requests = <ApiRequest>[];
      final repository = LiveSearchRepository(
        _client((request) async {
          requests.add(request);
          return _json({
            'articles': [
              {
                'id': 'article-1',
                'authorId': 'author-1',
                'slug': 'bai-tieng-viet',
                'title': null,
                'excerpt': 'Tiếng Việt: ặ ữ ờ ẫ ệ',
                'format': 'POST',
                'publishedAt': '2026-11-04T09:00:00Z',
                'username': 'thanhvien',
                'displayName': 'Thành Viên',
                'avatarUrl': null,
                'style': {'distroBadge': 'debian'},
              },
            ],
            'users': [
              {
                'id': 'author-1',
                'username': 'thanhvien',
                'displayName': null,
                'avatarUrl': null,
                'bio': 'Chia sẻ Linux',
                'role': 'MEMBER',
                'followerCount': 1,
                'followedByViewer': false,
                'style': null,
              },
            ],
            'projects': [
              {
                'id': 'project-1',
                'slug': 'linux-tool',
                'name': 'Linux Tool',
                'tagline': 'Công cụ',
                'owner': null,
                'repo': null,
                'rating': null,
              },
            ],
            'tags': [
              {'id': 'tag-1', 'name': 'Linux', 'slug': 'linux'},
            ],
            'hasMore': {
              'articles': true,
              'users': false,
              'projects': true,
              'tags': false,
            },
            'unknownFutureField': true,
          });
        }),
      );
      final results = await repository.search('  Linux  ');
      expect(requests.single.path, '/api/v1/search');
      expect(requests.single.query, {'q': 'Linux'});
      expect(requests.single.method, 'GET');
      expect(requests.single.headers['User-Agent'], contains('vlf-flutter'));
      expect(results.posts.single.author.id, 'author-1');
      expect(results.posts.single.author.username, 'thanhvien');
      expect(results.posts.single.author.style?.distroBadge, 'debian');
      expect(results.posts.single.excerpt, 'Tiếng Việt: ặ ữ ờ ẫ ệ');
      expect(results.users.single.displayName, 'thanhvien');
      expect(results.biographies['thanhvien'], 'Chia sẻ Linux');
      expect(results.projects.single.name, 'Linux Tool');
      expect(results.topics.single.slug, 'linux');
      expect(results.hasMore, {SearchScope.posts, SearchScope.projects});
      expect(() => results.posts.clear(), throwsUnsupportedError);
    },
  );

  test('short searches never reach the server', () async {
    var count = 0;
    final repository = LiveSearchRepository(
      _client((request) async {
        count++;
        return _json({});
      }),
    );
    expect((await repository.search(' a ')).posts, isEmpty);
    expect((await repository.search('  ')).users, isEmpty);
    expect(count, 0);
  });

  test(
    'search parsing failures remain typed instead of silently dropping rows',
    () async {
      final repository = LiveSearchRepository(
        _client(
          (_) async => _json({
            'articles': [
              {'id': 'article-1', 'username': 5},
            ],
          }),
        ),
      );
      await expectLater(
        repository.search('linux'),
        throwsA(isA<ParseFailure>()),
      );
    },
  );

  test(
    'suggestions use the website endpoint and omit topics without posts',
    () async {
      final requests = <ApiRequest>[];
      final repository = LiveSearchRepository(
        _client((request) async {
          requests.add(request);
          return _json({
            'items': [
              {'name': 'Wayland', 'slug': 'wayland', 'count': 4},
              {'name': 'Unused', 'slug': 'unused', 'count': 0},
            ],
          });
        }),
      );
      final topics = await repository.popularTopics();
      expect(requests.single.path, '/api/v1/tags/suggest');
      expect(requests.single.query, isEmpty);
      expect(topics.single.name, 'Wayland');
      expect(topics.single.count, 4);
    },
  );

  test('Vietnam Monday begins at Sunday 17:00 UTC across year boundary', () {
    expect(
      LeaderboardWeek.current(DateTime.utc(2026, 1, 4, 16, 59)).anchor,
      '2025-12-29',
    );
    final week = LeaderboardWeek.current(DateTime.utc(2026, 1, 4, 17));
    expect(week.anchor, '2026-01-05');
    expect(week.start, DateTime.utc(2026, 1, 4, 17));
    expect(week.end, DateTime.utc(2026, 1, 11, 17));
    expect(week.shift(-1).anchor, '2025-12-29');
  });

  test(
    'weekly archive sends the observed Monday anchor and parses actual ranking',
    () async {
      final requests = <ApiRequest>[];
      final repository = LiveWeeklyLeaderboardRepository(
        _client((request) async {
          requests.add(request);
          return _json({
            'period': 'week',
            'items': [
              {
                'userId': 'author-1',
                'username': 'thanhvien',
                'displayName': 'Thành Viên',
                'avatarUrl': null,
                'earnedPoints': 789,
                'rank': 1,
                'style': null,
              },
            ],
          });
        }),
      );
      final rankings = await repository.getWeek(
        week: LeaderboardWeek.current(DateTime.utc(2026, 11, 5)),
      );
      expect(requests.single.path, '/api/v1/leaderboards');
      expect(requests.single.query, {'period': 'week', 'week': '2026-11-02'});
      expect(rankings.items.single.earnedPoints, 789);
      await repository.getWeek();
      expect(requests.last.query, {'period': 'week'});
    },
  );
}

ApiClient _client(ApiTransport transport) => ApiClient(
  transport: transport,
  throttleInterval: Duration.zero,
  hostKey: Object(),
);
ApiResponse _json(Map<String, Object?> value) =>
    ApiResponse(statusCode: 200, body: jsonEncode(value));
