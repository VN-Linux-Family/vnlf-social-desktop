import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/core/api_client.dart';
import 'package:vnlfsocialapp/src/core/preferences_storage.dart';
import 'package:vnlfsocialapp/src/features/stickers/data/stickers_repository.dart';
import 'package:vnlfsocialapp/src/features/stickers/domain/stickers.dart';
import 'package:vnlfsocialapp/src/features/thread/data/comments_repository.dart';

Map<String, Object?> sticker(String id, {String status = 'READY'}) => {
  'id': id,
  'emoji': '😀',
  'status': status,
  'url': status == 'READY' ? 'https://cdn.example/$id.webp' : null,
  'width': 160,
  'height': 160,
  'animated': false,
  'error': null,
};

ApiClient client(List<ApiRequest> requests, Object body) => ApiClient(
  hostKey: Object(),
  throttleInterval: Duration.zero,
  transport: (request) async {
    requests.add(request);
    return ApiResponse(statusCode: 200, body: jsonEncode(body));
  },
);

void main() {
  test('the tray keeps only finished stickers', () async {
    final requests = <ApiRequest>[];
    final repository = LiveStickersRepository(
      client(requests, {
        'packs': [
          {
            'id': 'pack-1',
            'slug': 'meo',
            'title': 'Mèo',
            'stickers': [sticker('a'), sticker('b', status: 'PROCESSING')],
          },
        ],
      }),
    );
    final packs = await repository.tray();
    expect(requests.single.path, '/api/v1/stickers/tray');
    expect(packs.single.stickers.map((s) => s.id), ['a']);
    expect(packs.single.ref.choice(packs.single.stickers.single).toJson(), {
      'provider': 'VNLF',
      'kind': 'sticker',
      'id': 'a',
      'packId': 'pack-1',
      'packSlug': 'meo',
      'title': 'Mèo',
      'url': 'https://cdn.example/a.webp',
      'width': 160,
      'height': 160,
    });
  });

  test('saved stickers read their pack and unsave deletes', () async {
    final requests = <ApiRequest>[];
    final repository = LiveStickersRepository(
      client(requests, {
        'items': [
          {
            'sticker': sticker('a'),
            'pack': {'id': 'pack-1', 'slug': 'meo', 'title': 'Mèo'},
            'savedAt': '2026-11-09T00:00:00.000Z',
          },
        ],
      }),
    );
    final saved = await repository.saved();
    expect(saved.single.pack.slug, 'meo');
    await repository.unsave('a');
    expect(requests.last.method, 'DELETE');
    expect(requests.last.path, '/api/v1/stickers/a/save');
  });

  test(
    'recent stickers are kept per account, newest first, sixteen at most',
    () async {
      final storage = _MemoryStorage();
      final store = RecentStickersStore(storage);
      for (var i = 0; i < 20; i++) {
        await store.remember(
          'owner',
          GifChoice.klipy(
            id: '$i',
            slug: 's$i',
            title: 't',
            url: 'https://static1.klipy.com/ii/$i.webp',
            width: 1,
            height: 1,
            sticker: true,
          ),
        );
      }
      final recent = await store.read('owner');
      expect(recent, hasLength(16));
      expect(recent.first.id, '19');
      expect(await store.read('other'), isEmpty);
    },
  );

  test('a comment sends its GIF payload', () async {
    final requests = <ApiRequest>[];
    final repository = LiveCommentsRepository(
      ApiClient(
        hostKey: Object(),
        throttleInterval: Duration.zero,
        transport: (request) async {
          requests.add(request);
          return ApiResponse(
            statusCode: 200,
            body: jsonEncode({
              'id': 'c1',
              'content': '',
              'author': {'id': 'u', 'username': 'u', 'displayName': 'U'},
              'gif': {
                'provider': 'KLIPY',
                'id': '1',
                'slug': 's',
                'kind': 'sticker',
                'title': 't',
                'url': 'https://static1.klipy.com/ii/1.webp',
                'width': 1,
                'height': 1,
              },
            }),
          );
        },
      ),
    );
    const gif = {
      'provider': 'KLIPY',
      'id': '1',
      'slug': 's',
      'kind': 'sticker',
      'title': 't',
      'url': 'https://static1.klipy.com/ii/1.webp',
      'width': 1,
      'height': 1,
    };
    final comment = await repository.create('article', '', gif: gif);
    expect(jsonDecode(requests.single.body!)['gif'], gif);
    expect(comment.gif?.isSticker, isTrue);
  });
}

class _MemoryStorage implements PreferencesStorage {
  final values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}
