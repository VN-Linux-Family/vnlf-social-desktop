import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/app/app_router.dart';
import 'package:vnlfsocialapp/src/design_system/design_system.dart';
import 'package:vnlfsocialapp/src/core/api_client.dart';
import 'package:vnlfsocialapp/src/core/session_storage.dart';
import 'package:vnlfsocialapp/src/data/feed_dto.dart';
import 'package:vnlfsocialapp/src/data/fixture_repositories.dart';

void main() {
  test('feed DTO maps missing optional values and ignores unknown fields', () {
    final post = FeedPostDto.fromJson({
      'id': 'post-1',
      'excerpt': 'Tiếng Việt: ặ ữ ờ ẫ ệ',
      'author': {'username': 'an', 'ignored': true},
      'unknown': 'ignored',
    }).toDomain();
    expect(post.id, 'post-1');
    expect(post.author.displayName, 'an');
    expect(post.voteScore, 0);
    expect(post.excerpt, 'Tiếng Việt: ặ ữ ờ ẫ ệ');
  });

  test('malformed required fixture data is a typed parse failure', () {
    expect(
      () => FeedPostDto.fromJson({'id': 42}),
      throwsA(isA<ParseFailure>()),
    );
  });

  test('fixture client retries transient failures and maps the feed', () async {
    var attempts = 0;
    final client = ApiClient(
      hostKey: Object(),
      transport: (request) async {
        attempts++;
        if (attempts == 1) return ApiResponse(statusCode: 503, body: '');
        return ApiResponse(
          statusCode: 200,
          body: jsonEncode({
            'items': [
              {'id': 'post-1'},
            ],
            'nextCursor': null,
          }),
        );
      },
      retryDelay: (_) async {},
    );
    final page = await FixtureFeedRepository(client).getFeed();
    expect(attempts, 2);
    expect(page.items.single.id, 'post-1');
  });

  test('unknown fixture path fails explicitly', () async {
    final client = ApiClient(hostKey: Object(), transport: fixtureTransport);
    await expectLater(
      client.get<Map<String, dynamic>>('/unknown'),
      throwsA(isA<HttpFailure>()),
    );
  });

  test('fixture auth and community have no implicit signed-in user', () async {
    expect(await FixtureAuthRepository().currentSession(), isNull);
    expect(await FixtureCommunityRepository().getChannels(), isEmpty);
    expect(
      (await FixtureFeedRepository(
        ApiClient(hostKey: Object(), transport: fixtureTransport),
      ).getFeed()).items,
      isNotEmpty,
    );
  });

  test('session interceptor reads explicitly configured headers', () async {
    final storage = _MemoryStorage({'csrf': 'fixture-value'});
    final client = ApiClient(
      hostKey: Object(),
      interceptors: [
        sessionHeadersInterceptor(storage, {'x-example-csrf': 'csrf'}),
      ],
      transport: (request) async => ApiResponse(
        statusCode: 200,
        body: jsonEncode({'header': request.headers['x-example-csrf']}),
      ),
    );
    final response = await client.get<Map<String, dynamic>>('/fixture');
    expect(response['header'], 'fixture-value');
  });

  test('transient errors stop after three attempts', () async {
    var attempts = 0;
    final client = ApiClient(
      hostKey: Object(),
      retryDelay: (_) async {},
      transport: (_) async {
        attempts++;
        return ApiResponse(statusCode: 503, body: '');
      },
    );
    await expectLater(
      client.get<Map<String, dynamic>>('/fixture'),
      throwsA(isA<HttpFailure>()),
    );
    expect(attempts, 3);
  });

  testWidgets('router switches destinations inside the adaptive shell', (
    tester,
  ) async {
    final router = createAppRouter(
      postScreen: (_, id) => Text(id),
      profileScreen: (_, username) => Text(username),
      screens: {
        for (final destination in VnlfNavDestination.values)
          destination: (_) => Text('screen ${destination.name}'),
      },
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    expect(find.text('screen feed'), findsOneWidget);
    router.go('/projects');
    await tester.pumpAndSettle();
    expect(find.text('screen projects'), findsOneWidget);
  });

  test('invalid optional field does not silently default', () {
    expect(
      () => FeedPostDto.fromJson({'id': 'one', 'voteScore': 'bad'}),
      throwsA(isA<ParseFailure>()),
    );
  });
}

final class _MemoryStorage implements SessionStorage {
  _MemoryStorage(this.values);
  final Map<String, String> values;
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }
}
