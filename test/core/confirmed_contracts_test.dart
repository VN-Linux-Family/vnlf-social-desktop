import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/data/feed_dto.dart';
import 'package:vnlfsocialapp/src/data/fixture_repositories.dart';
import 'package:vnlfsocialapp/src/core/api_client.dart';
import 'package:vnlfsocialapp/src/data/leaderboard_dto.dart';
import 'package:vnlfsocialapp/src/data/projects_dto.dart';

Map<String, dynamic> fixture(String name) =>
    jsonDecode(File('test/fixtures/$name.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  test('maps recorded feed fields and author styling', () {
    final post = FeedPageDto.fromJson(fixture('feed')).toDomain().items.single;
    expect(post.title, 'Chào mừng đến với Vietnam Linux Family!');
    expect(post.author.style?.distroBadge, 'arch');
    expect(post.viewerVote, 1);
    expect(post.tagSlugs, contains('linux'));
    expect(post.contentJson?['type'], 'doc');
  });
  test('maps recorded leaderboard and project entries', () {
    final leaderboard = LeaderboardPageDto.fromJson(fixture('leaderboards'))
        .toDomain();
    expect(leaderboard.items.first.earnedPoints, 450);
    expect(leaderboard.items.first.style?.distroBadge, 'arch');
    final project = ProjectsPageDto.fromJson(fixture('projects'))
        .toDomain()
        .items
        .single;
    expect(project.name, 'vnlf-cli');
    expect(project.repo?['stars'], 128);
    expect(project.rating?['average'], 4.9);
  });
  test(
    'repositories decode fixture responses and propagate HTTP errors',
    () async {
      final client = ApiClient(
        hostKey: Object(),
        throttleInterval: Duration.zero,
        transport: (request) async {
          final name = request.path.endsWith('leaderboards')
              ? 'leaderboards'
              : 'projects';
          return ApiResponse(statusCode: 200, body: jsonEncode(fixture(name)));
        },
      );
      expect(
        (await FixtureLeaderboardRepository(
          client,
        ).getLeaderboard()).items.first.rank,
        1,
      );
      expect(
        (await FixtureProjectsRepository(
          client,
        ).getProjects()).items.single.owner?.username,
        'hoangnam',
      );
      final failing = ApiClient(
        hostKey: Object(),
        throttleInterval: Duration.zero,
        transport: (_) async => ApiResponse(statusCode: 404, body: '{}'),
      );
      await expectLater(
        FixtureProjectsRepository(failing).getProjects(),
        throwsA(isA<HttpFailure>()),
      );
    },
  );
  test('mapped JSON collections cannot be changed', () {
    final post = FeedPageDto.fromJson(fixture('feed')).toDomain().items.single;
    expect(() => post.tagSlugs.add('new'), throwsUnsupportedError);
    expect(() => post.contentJson!['type'] = 'other', throwsUnsupportedError);
  });
  test('malformed values produce typed failures', () {
    expect(
      () => FeedPostDto.fromJson({'id': 'p', 'viewerLiked': 'yes'}),
      throwsA(isA<ParseFailure>()),
    );
    expect(
      () => LeaderboardPageDto.fromJson({
        'items': [null],
      }),
      throwsA(isA<ParseFailure>()),
    );
    expect(
      () => ProjectsPageDto.fromJson({'items': 'bad'}),
      throwsA(isA<ParseFailure>()),
    );
  });
}
