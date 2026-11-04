import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/core/api_client.dart';
import 'package:vnlfsocialapp/src/data/fixture_repositories.dart';

Map<String, dynamic> _fixture(String name) =>
    jsonDecode(File('test/fixtures/$name.json').readAsStringSync())
        as Map<String, dynamic>;

ApiClient _client({required ApiTransport transport}) => ApiClient(
  hostKey: Object(),
  throttleInterval: Duration.zero,
  transport: transport,
);

void main() {
  group('FixtureFeedRepository pagination and cache', () {
    test(
      'returns nextCursor and sends it as the next page query parameter',
      () async {
        final requests = <ApiRequest>[];
        final client = _client(
          transport: (request) async {
            requests.add(request);
            if (request.query['cursor'] == 'cursor-page-2') {
              return ApiResponse(
                statusCode: 200,
                body: jsonEncode({
                  'items': [
                    {
                      'id': 'post-page-2',
                      'excerpt': 'Second page',
                      'author': {'username': 'member'},
                    },
                  ],
                  'nextCursor': null,
                }),
              );
            }
            return ApiResponse(
              statusCode: 200,
              body: jsonEncode({
                'items': [
                  {
                    'id': 'post-page-1',
                    'excerpt': 'First page',
                    'author': {'username': 'member'},
                  },
                ],
                'nextCursor': 'cursor-page-2',
              }),
            );
          },
        );
        final feed = FixtureFeedRepository(client);

        final firstPage = await feed.getFeed();
        expect(firstPage.items.single.id, 'post-page-1');
        expect(firstPage.nextCursor, 'cursor-page-2');
        expect(requests.first.query, isEmpty);

        final secondPage = await feed.getFeed(cursor: firstPage.nextCursor);
        expect(secondPage.items.single.id, 'post-page-2');
        expect(secondPage.nextCursor, isNull);
        expect(requests.last.path, '/api/v1/feed');
        expect(requests.last.query, {'cursor': 'cursor-page-2'});
        expect(requests, hasLength(2));
      },
    );

    test('an empty page with no nextCursor terminates pagination', () async {
      var requestCount = 0;
      final feed = FixtureFeedRepository(
        _client(
          transport: (_) async {
            requestCount++;
            return ApiResponse(
              statusCode: 200,
              body: '{"items":[],"nextCursor":null}',
            );
          },
        ),
      );

      final page = await feed.getFeed(cursor: 'last-cursor');
      expect(page.items, isEmpty);
      expect(page.nextCursor, isNull);
      if (page.nextCursor != null) {
        await feed.getFeed(cursor: page.nextCursor);
      }
      expect(requestCount, 1);
    });

    test(
      'caches the same cursor page and separates distinct cursors',
      () async {
        final requests = <ApiRequest>[];
        final feed = FixtureFeedRepository(
          _client(
            transport: (request) async {
              requests.add(request);
              return ApiResponse(
                statusCode: 200,
                body: jsonEncode({
                  'items': [
                    {
                      'id': 'post-${request.query['cursor'] ?? 'first'}',
                      'excerpt': 'Cached page',
                      'author': {'username': 'member'},
                    },
                  ],
                  'nextCursor': null,
                }),
              );
            },
          ),
        );

        expect((await feed.getFeed()).items.single.id, 'post-first');
        expect((await feed.getFeed()).items.single.id, 'post-first');
        expect(
          (await feed.getFeed(cursor: 'cursor-page-2')).items.single.id,
          'post-cursor-page-2',
        );
        expect(requests, hasLength(2));
        expect(requests.map((request) => request.query).toList(), [
          <String, String>{},
          {'cursor': 'cursor-page-2'},
        ]);
      },
    );
  });

  group('fixture repository domain mappings', () {
    test(
      'FixtureLeaderboardRepository maps the recorded leaderboard',
      () async {
        final repository = FixtureLeaderboardRepository(
          _client(
            transport: (_) async => ApiResponse(
              statusCode: 200,
              body: jsonEncode(_fixture('leaderboards')),
            ),
          ),
        );

        final page = await repository.getLeaderboard();
        expect(page.period, 'week');
        expect(page.periodStart, DateTime.utc(2026, 11, 1));
        expect(page.periodEnd, DateTime.utc(2026, 11, 7, 23, 59, 59, 999));
        expect(page.computedAt, DateTime.utc(2026, 11, 4, 12));
        expect(page.items, hasLength(3));
        expect(page.items.first.userId, 'user-synth-1');
        expect(page.items.first.username, 'hoangnam');
        expect(page.items.first.earnedPoints, 450);
        expect(page.items.first.rank, 1);
        expect(page.items.first.style?.distroBadge, 'arch');
      },
    );

    test('FixtureProjectsRepository maps the recorded projects', () async {
      final repository = FixtureProjectsRepository(
        _client(
          transport: (_) async => ApiResponse(
            statusCode: 200,
            body: jsonEncode(_fixture('projects')),
          ),
        ),
      );

      final page = await repository.getProjects();
      expect(page.nextCursor, isNull);
      expect(page.items, hasLength(1));
      final project = page.items.single;
      expect(project.id, 'proj-synth-1');
      expect(project.name, 'vnlf-cli');
      expect(project.slug, 'vnlf-cli');
      expect(project.type, 'tool');
      expect(project.tier, 'community');
      expect(project.featured, isTrue);
      expect(project.owner?.username, 'hoangnam');
      expect(project.repo?['provider'], 'github');
      expect(project.repo?['stars'], 128);
      expect(project.rating, {'average': 4.9, 'count': 35});
      expect(project.commentCount, 12);
      expect(project.approvedAt, DateTime.utc(2026, 10, 15, 8));
    });
  });
}
