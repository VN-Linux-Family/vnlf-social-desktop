import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/core/api_client.dart';
import 'package:vnlfsocialapp/src/features/stickers/data/klipy_repository.dart';
import 'package:vnlfsocialapp/src/features/stickers/domain/stickers.dart';

const config = KlipyConfig(
  enabled: true,
  apiKey: 'test-key',
  customerId: 'pseudonym',
);

Map<String, Object?> item({
  Object id = 123,
  String type = 'gif',
  Map<String, Object?>? file,
}) => {
  'id': id,
  'slug': 'meo-cuoi',
  'title': 'Mèo cười',
  'type': type,
  'file':
      file ??
      {
        'sm': {
          'gif': {
            'url': 'https://static1.klipy.com/ii/abc/meo.gif',
            'width': 220,
            'height': 160,
          },
          'webp': {
            'url': 'https://static1.klipy.com/ii/abc/meo.webp',
            'width': 220,
            'height': 160,
          },
        },
      },
};

String page(List<Map<String, Object?>> items, {int current = 1}) => jsonEncode({
  'result': true,
  'data': {'data': items, 'current_page': current, 'has_next': true},
});

void main() {
  test('a page keeps GIFs, prefers gif for GIFs and webp for stickers', () {
    final gifs = parseKlipyPage(page([item()]), 1, stickers: false);
    expect(gifs.items.single.url, endsWith('meo.gif'));
    expect(gifs.items.single.toJson(), {
      'provider': 'KLIPY',
      'id': '123',
      'slug': 'meo-cuoi',
      'title': 'Mèo cười',
      'url': 'https://static1.klipy.com/ii/abc/meo.gif',
      'width': 220,
      'height': 160,
    });
    expect(gifs.hasNext, isTrue);
    final stickers = parseKlipyPage(page([item()]), 1, stickers: true);
    expect(stickers.items.single.url, endsWith('meo.webp'));
    expect(stickers.items.single.toJson()['kind'], 'sticker');
  });

  test('large ids stay exact', () {
    final json = page([item()])
        .replaceFirst('"id":123', '"id":12345678901234567890');
    final parsed = parseKlipyPage(json, 1, stickers: false);
    expect(parsed.items.single.id, '12345678901234567890');
  });

  test('ads, foreign hosts and page mismatches are refused', () {
    expect(
      () => parseKlipyPage(page([item(type: 'ad')]), 1, stickers: false),
      throwsA(
        isA<KlipyException>().having(
          (e) => e.message,
          'message',
          contains('quảng cáo'),
        ),
      ),
    );
    final foreign = item(
      file: {
        'sm': {
          'gif': {
            'url': 'https://example.com/ii/abc/meo.gif',
            'width': 1,
            'height': 1,
          },
        },
      },
    );
    expect(
      () => parseKlipyPage(page([foreign]), 1, stickers: false),
      throwsA(isA<KlipyException>()),
    );
    expect(
      () => parseKlipyPage(page([item()], current: 2), 1, stickers: false),
      throwsA(isA<KlipyException>()),
    );
  });

  test('search calls KLIPY directly and maps its errors', () async {
    final requests = <Uri>[];
    var status = 200;
    final repository = LiveKlipyRepository(
      ApiClient(
        hostKey: Object(),
        throttleInterval: Duration.zero,
        transport: (request) async => ApiResponse(statusCode: 500, body: '{}'),
      ),
      transport: (method, uri, {body}) async {
        requests.add(uri);
        return (status: status, body: page([item()]));
      },
    );
    final result = await repository.search(
      config,
      query: 'mèo',
      page: 1,
      stickers: true,
    );
    expect(result.items, hasLength(1));
    expect(
      requests.single.toString(),
      'https://api.klipy.com/api/v1/test-key/stickers/search?page=1&per_page=24'
      '&customer_id=pseudonym&locale=vn&format_filter=gif%2Cwebp'
      '&content_filter=high&q=m%C3%A8o',
    );
    status = 429;
    await expectLater(
      repository.search(config, query: '', page: 1, stickers: false),
      throwsA(
        isA<KlipyException>().having(
          (e) => e.message,
          'message',
          contains('100'),
        ),
      ),
    );
    expect(requests.last.path, '/api/v1/test-key/gifs/trending');
  });

  test('share reports the chosen GIF once, without blocking', () async {
    final calls = <(String, Uri, String?)>[];
    final repository = LiveKlipyRepository(
      ApiClient(
        hostKey: Object(),
        throttleInterval: Duration.zero,
        transport: (request) async => ApiResponse(statusCode: 500, body: '{}'),
      ),
      transport: (method, uri, {body}) async {
        calls.add((method, uri, body));
        throw Exception('offline');
      },
    );
    final choice = parseKlipyPage(
      page([item()]),
      1,
      stickers: false,
    ).items.single;
    await repository.share(config, choice, 'mèo');
    expect(calls.single.$1, 'POST');
    expect(
      calls.single.$2.toString(),
      'https://api.klipy.com/api/v1/test-key/gifs/share/meo-cuoi',
    );
    expect(jsonDecode(calls.single.$3!), {
      'customer_id': 'pseudonym',
      'q': 'mèo',
    });
  });

  test('emoji tags are found like the website does', () {
    expect(firstEmoji('mèo 😀 vui'), '😀');
    expect(firstEmoji('👍🏽 ok'), '👍🏽');
    expect(firstEmoji('🇻🇳'), '🇻🇳');
    expect(firstEmoji('1️⃣'), '1️⃣');
    expect(firstEmoji('👨‍👩‍👧 gia đình'), '👨‍👩‍👧');
    expect(firstEmoji('không có'), isNull);
  });
}
