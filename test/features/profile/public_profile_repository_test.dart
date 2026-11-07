import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/core/api_client.dart';
import 'package:vnlfsocialapp/src/features/profile/data/live_public_profile_repository.dart';

void main() {
  test('public profile reads retain profile stats and scoped content without writes', () async {
    final paths = <String>[];
    final client = ApiClient(
      hostKey: Object(),
      throttleInterval: Duration.zero,
      transport: (request) async {
        expect(request.method, 'GET');
        paths.add(request.path);
        final value = switch (request.path) {
          '/api/v1/users/fixture' => <String, dynamic>{
            'username': 'fixture',
            'displayName': 'Nguyễn An',
            'totalPoints': 144,
            'level': 2,
            'currentStreak': 5,
            'followerCount': 8,
            'followingCount': 3,
            'bio': 'Tiếng Việt: ặ ữ ờ ẫ ệ',
            'unknown': true,
          },
          '/api/v1/users/fixture/articles' => <String, dynamic>{
            'items': [
              {
                'id': 'scoped-post',
                'slug': 'scoped',
                'author': {'username': 'fixture', 'displayName': 'Nguyễn An'},
              },
            ],
            'nextCursor': 'post-cursor',
          },
          '/api/v1/users/fixture/comments' => <String, dynamic>{
            'items': [
              {
                'id': 'comment-1',
                'articleId': 'scoped-post',
                'articleSlug': 'scoped',
                'content': 'Bình luận',
                'createdAt': '2026-11-04T10:00:00Z',
              },
            ],
            'nextCursor': null,
          },
          '/api/v1/users/fixture/projects' => <String, dynamic>{
            'items': [
              {'id': 'project-1', 'name': 'Công cụ Linux'},
            ],
          },
          '/api/v1/profiles/fixture/guestbook' => <String, dynamic>{
            'enabled': true,
            'total': 1,
            'items': [
              {
                'id': 'visible',
                'status': 'VISIBLE',
                'content': 'Chào bạn',
                'author': {'username': 'visitor', 'displayName': 'Khách'},
              },
              {
                'id': 'hidden',
                'status': 'HIDDEN',
                'content': 'Ẩn',
                'author': {'username': 'visitor', 'displayName': 'Khách'},
              },
            ],
            'nextCursor': 'next',
          },
          _ => throw StateError('Unexpected request ${request.path}'),
        };
        if (request.path.endsWith('/articles') ||
            request.path.endsWith('/comments')) {
          expect(request.query, {'limit': '50'});
        }
        if (request.path.endsWith('/guestbook')) {
          expect(request.query, {'cursor': 'next-page'});
        }
        return ApiResponse(statusCode: 200, body: jsonEncode(value));
      },
    );
    final repository = LivePublicProfileRepository(client);
    final profile = (await repository.getProfile('fixture'))!;
    expect(profile.totalPoints, 144);
    expect(profile.level, 2);
    expect(profile.currentStreak, 5);
    expect(profile.followingCount, 3);
    expect(profile.followerCount, 8);
    expect(
      (await repository.getPosts('fixture')).items.single.id,
      'scoped-post',
    );
    expect(
      (await repository.getComments('fixture')).items.single.articleId,
      'scoped-post',
    );
    expect(
      (await repository.getProjects('fixture')).items.single.name,
      'Công cụ Linux',
    );
    final guestbook = await repository.getGuestbook(
      'fixture',
      cursor: 'next-page',
    );
    expect(guestbook.items.map((entry) => entry.id), ['visible', 'hidden']);
    expect(guestbook.nextCursor, 'next');
    expect(paths, hasLength(5));
  });

  test(
    'missing profiles are absent but malformed or failed responses stay errors',
    () async {
      Future<Object?> load(int status, Map<String, dynamic> value) =>
          LivePublicProfileRepository(
            ApiClient(
              hostKey: Object(),
              throttleInterval: Duration.zero,
              transport: (_) async =>
                  ApiResponse(statusCode: status, body: jsonEncode(value)),
            ),
          ).getProfile('fixture');
      expect(await load(404, {}), isNull);
      await expectLater(
        load(200, {'username': 'fixture', 'totalPoints': 'bad'}),
        throwsA(isA<ParseFailure>()),
      );
      await expectLater(load(403, {}), throwsA(isA<HttpFailure>()));
    },
  );
}
