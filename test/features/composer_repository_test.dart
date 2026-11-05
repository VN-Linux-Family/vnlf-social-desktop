import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/core/api_client.dart';
import 'package:vnlfsocialapp/src/features/composer/data/composer_repository.dart';
import 'package:vnlfsocialapp/src/features/composer/domain/composer_draft.dart';
import 'package:vnlfsocialapp/src/features/composer/domain/compose_document.dart';

void main() {
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
      final client = ApiClient(
        throttleInterval: Duration.zero,
        hostKey: Object(),
        transport: (r) async {
          requests.add(r);
          return ApiResponse(
            statusCode: 200,
            body: jsonEncode({
              'id': 'draft-id',
              'version': r.method == 'PATCH' ? 2 : 1,
              'status': r.path.endsWith('/publish') ? 'PUBLISHED' : 'DRAFT',
              'slug': 'bai-thu',
              'author': <String, dynamic>{},
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
