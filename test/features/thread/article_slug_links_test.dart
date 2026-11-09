import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/app/providers.dart';
import 'package:vnlfsocialapp/src/core/api_client.dart';
import 'package:vnlfsocialapp/src/core/vnlf_navigation_helper.dart';
import 'package:vnlfsocialapp/src/data/live_post_repository.dart';
import 'package:vnlfsocialapp/src/features/thread/presentation/thread_post_provider.dart';

const _articleId = '0194f1c2-7a3b-7c11-9e2d-5b6a7c8d9e0f';
const _slug = 'cai-dat-arch-linux-tren-may-ao';

Map<String, dynamic> _article() => {
  'id': _articleId,
  'slug': _slug,
  'format': 'POST',
  'author': {'username': 'thanhvien', 'displayName': 'Thành viên thử'},
  'excerpt': 'Tiếng Việt: ặ ữ ờ ẫ ệ',
};

ApiClient _client(List<String> paths, {int status = 200}) => ApiClient(
  transport: (request) async {
    paths.add(request.path);
    return ApiResponse(
      statusCode: status,
      body: status == 200
          ? jsonEncode(_article())
          : jsonEncode({
              'code': 'ARTICLE_NOT_FOUND',
              'message': 'Không tìm thấy bài viết.',
              'requestId': 'synthetic',
            }),
    );
  },
  throttleInterval: Duration.zero,
  hostKey: Object(),
);

void main() {
  test('article UUIDs use the id route', () async {
    final paths = <String>[];
    final post = await LivePostRepository(_client(paths)).getPost(_articleId);
    expect(paths, ['/api/v1/articles/$_articleId']);
    expect(post!.id, _articleId);
  });

  test(
    'public slugs use the slug route instead of the UUID-only id route',
    () async {
      final paths = <String>[];
      final post = await LivePostRepository(_client(paths)).getPost(_slug);
      expect(paths, ['/api/v1/articles/slug/$_slug']);
      expect(post!.id, _articleId, reason: 'later reads use the resolved id');
    },
  );

  test('a shared website link opens the thread through its slug', () async {
    final route = resolveInAppVnlfRoute(
      Uri.parse('https://vietnamlinuxfamily.net/a/$_slug'),
    );
    expect(route, '/thread/$_slug');
    final paths = <String>[];
    final container = ProviderContainer(
      overrides: [
        postRepositoryProvider.overrideWithValue(
          LivePostRepository(_client(paths)),
        ),
      ],
    );
    addTearDown(container.dispose);
    final key = Uri.parse(route!).pathSegments.last;
    final read = container.listen(threadPostProvider(key).future, (_, _) {});
    final post = await read.read();
    expect(paths, ['/api/v1/articles/slug/$_slug']);
    expect(post?.slug, _slug);
  });

  test(
    'a missing article is shown as absent, not as a retryable failure',
    () async {
      final paths = <String>[];
      final container = ProviderContainer(
        overrides: [
          postRepositoryProvider.overrideWithValue(
            LivePostRepository(_client(paths, status: 404)),
          ),
        ],
      );
      addTearDown(container.dispose);
      final read = container.listen(
        threadPostProvider(_slug).future,
        (_, _) {},
      );
      expect(await read.read(), isNull);
      expect(paths, hasLength(1));
    },
  );
}
