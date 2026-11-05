import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/core/api_client.dart';
import 'package:vnlfsocialapp/src/features/composer/data/composer_repository.dart';
import 'package:vnlfsocialapp/src/features/composer/domain/composer_draft.dart';
import 'package:vnlfsocialapp/src/features/composer/domain/compose_document.dart';

void main() {
  test('empty publication is rejected without a network request', () async {
    var calls = 0;
    final repository = LiveComposerRepository(
      ApiClient(
        hostKey: Object(),
        throttleInterval: Duration.zero,
        transport: (_) async {
          calls++;
          return ApiResponse(statusCode: 200, body: '{"id":"draft-id"}');
        },
      ),
    );
    await expectLater(
      repository.publish(
        const ComposerDraft(id: 'draft-id', version: 1),
        idempotencyKey: 'empty-attempt',
      ),
      throwsA(isA<ParseFailure>()),
    );
    expect(calls, 0);
  });
  test(
    'cover and inline asset catalog survive loading and explicit cover removal',
    () {
      final draft = draftFromJson({
        'id': 'draft-id',
        'format': 'ARTICLE',
        'version': 4,
        'coverAssetId': 'cover',
        'coverUrl': 'https://example.invalid/cover.webp',
        'coverAlt': 'Ảnh bìa',
        'assets': [
          {
            'id': 'inline',
            'url': 'https://example.invalid/inline.webp',
            'mime': 'image/webp',
            'width': 600,
            'height': 400,
          },
        ],
      });
      expect(draft.assets['inline']!.width, 600);
      expect(draft.copyWith(title: 'Đổi tiêu đề').coverAssetId, 'cover');
      final removed = draft.copyWith(
        coverAssetId: null,
        coverUrl: null,
        coverAlt: '',
      );
      expect(removed.coverAssetId, isNull);
      expect(removed.coverUrl, isNull);
      expect(removed.coverAlt, '');
      expect(removed.assets.keys, ['inline']);
    },
  );
  test(
    'completed video remains processing until a fresh asset read reports ready',
    () async {
      var reads = 0;
      final requests = <ApiRequest>[];
      final repository = LiveComposerRepository(
        ApiClient(
          throttleInterval: Duration.zero,
          hostKey: Object(),
          transport: (request) async {
            requests.add(request);
            if (request.path.endsWith('/presign')) {
              return ApiResponse(
                statusCode: 200,
                body: '{"assetId":"video","uploadUrl":"https://example.invalid/upload"}',
              );
            }
            if (request.path.endsWith('/complete')) {
              return ApiResponse(
                statusCode: 200,
                body: '{"assetId":"video","status":"PENDING","url":null}',
              );
            }
            reads++;
            return ApiResponse(
              statusCode: 200,
              body: jsonEncode({
                'id': 'video',
                'mime': 'video/mp4',
                'status': reads == 1 ? 'PENDING' : 'READY',
                'url': reads == 1 ? null : 'https://example.invalid/ready.mp4',
                'durationMs': 12000,
              }),
            );
          },
        ),
        upload: (_, _) async {},
      );
      final pending = await repository.upload(
        'draft-id',
        ComposerUpload(
          name: 'clip.mp4',
          mime: 'video/mp4',
          length: 10,
          openRead: () => const Stream.empty(),
        ),
      );
      expect(pending.isProcessing, isTrue);
      expect(pending.isReady, isFalse);
      expect(
        (await repository.refreshMedia('draft-id', pending)).isReady,
        isFalse,
      );
      final ready = await repository.refreshMedia('draft-id', pending);
      expect(ready.isReady, isTrue);
      expect(ready.durationMs, 12000);
      expect(reads, 2);
      expect(requests.map((r) => r.method), ['POST', 'POST', 'GET', 'GET']);
    },
  );
  test('oversize image is rejected before any upload request', () async {
    var calls = 0;
    final repository = LiveComposerRepository(
      ApiClient(
        throttleInterval: Duration.zero,
        hostKey: Object(),
        transport: (_) async {
          calls++;
          return ApiResponse(statusCode: 400, body: '{}');
        },
      ),
    );
    await expectLater(
      repository.upload(
        'draft-id',
        ComposerUpload(
          name: 'large.png',
          mime: 'image/png',
          length: 11 * 1024 * 1024,
          openRead: () => const Stream.empty(),
        ),
      ),
      throwsA(isA<ParseFailure>()),
    );
    expect(calls, 0);
  });
  test('processing video cannot be published', () async {
    var calls = 0;
    final repository = LiveComposerRepository(
      ApiClient(
        throttleInterval: Duration.zero,
        hostKey: Object(),
        transport: (_) async {
          calls++;
          return ApiResponse(statusCode: 200, body: '{"id":"draft-id"}');
        },
      ),
    );
    final draft = draftFromJson({
      'id': 'draft-id',
      'version': 1,
      'attachments': [
        {
          'id': 'pending-video',
          'mime': 'video/mp4',
          'url': null,
          'state': 'PROCESSING',
        },
      ],
    });
    await expectLater(
      repository.publish(draft, idempotencyKey: 'same-attempt'),
      throwsA(isA<ParseFailure>()),
    );
    expect(calls, 0);
  });
  test('ARTICLE rejects video attachments before saving', () async {
    var calls = 0;
    final repository = LiveComposerRepository(
      ApiClient(
        throttleInterval: Duration.zero,
        hostKey: Object(),
        transport: (_) async {
          calls++;
          return ApiResponse(statusCode: 200, body: '{"id":"draft-id"}');
        },
      ),
    );
    await expectLater(
      repository.save(
        const ComposerDraft(
          id: 'draft-id',
          version: 0,
          format: 'ARTICLE',
          media: [
            DraftMedia(
              id: 'video',
              url: 'https://example.invalid/video.mp4',
              mime: 'video/mp4',
            ),
          ],
        ),
      ),
      throwsA(isA<ParseFailure>()),
    );
    expect(calls, 0);
  });
  test(
    'formatted Vietnamese composition becomes the observed document schema',
    () {
      final doc = composeDocument(
        '## Tiếng Việt: ặ ữ ờ ẫ ệ\n\n**Đậm** và *nghiêng*\n\n- Một\n- Hai\n\n```bash\nprintf hello\n```',
      );
      final nodes = doc['content'] as List;
      expect(nodes.map((n) => (n as Map)['type']), [
        'heading',
        'paragraph',
        'bulletList',
        'codeBlock',
      ]);
      expect((nodes[0] as Map)['attrs'], {'level': 2});
      expect((((nodes[1] as Map)['content'] as List).first as Map)['marks'], [
        {'type': 'bold'},
      ]);
      expect((nodes.last as Map)['content'], [
        {'type': 'text', 'text': 'printf hello\n'},
      ]);
    },
  );

  test(
    'draft save uses version and publish includes an idempotency key',
    () async {
      final requests = <ApiRequest>[];
      Map<String, dynamic>? savedDocument;
      final client = ApiClient(
        throttleInterval: Duration.zero,
        hostKey: Object(),
        transport: (r) async {
          requests.add(r);
          if (r.method == 'PATCH') {
            savedDocument =
                (jsonDecode(r.body!) as Map<String, dynamic>)['contentJson']
                    as Map<String, dynamic>;
          }
          return ApiResponse(
            statusCode: 200,
            body: jsonEncode({
              'id': 'draft-id',
              'version': r.method == 'PATCH' ? 2 : 1,
              'status': r.path.endsWith('/publish') ? 'PUBLISHED' : 'DRAFT',
              'slug': 'bai-thu',
              'author': <String, dynamic>{},
              'contentJson': savedDocument,
            }),
          );
        },
      );
      final repository = LiveComposerRepository(client);
      final draft = await repository.create();
      final saved = await repository.save(
        draft.copyWith(document: composeDocument('Bài mới'), format: 'POST'),
      );
      final published = await repository.publish(
        saved,
        idempotencyKey: 'publish-test-key',
      );
      expect(published.status, 'PUBLISHED');
      expect(requests.map((r) => r.method), ['POST', 'PATCH', 'POST']);
      final patch = jsonDecode(requests[1].body!) as Map;
      expect(patch['version'], 1);
      expect(patch['contentJson'], {
        'type': 'doc',
        'content': [
          {
            'type': 'paragraph',
            'content': [
              {'type': 'text', 'text': 'Bài mới'},
            ],
          },
        ],
      });
      expect(requests.last.headers['idempotency-key'], 'publish-test-key');
    },
  );

  test('unsuccessful draft saves do not publish or retry the write', () async {
    var calls = 0;
    final client = ApiClient(
      throttleInterval: Duration.zero,
      hostKey: Object(),
      transport: (r) async {
        calls++;
        return ApiResponse(statusCode: 409, body: '{}');
      },
    );
    final repository = LiveComposerRepository(client);
    await expectLater(
      repository.save(const ComposerDraft(id: 'draft-id', version: 3)),
      throwsA(isA<HttpFailure>()),
    );
    expect(calls, 1);
  });
}
