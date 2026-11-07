import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/domain/models.dart';
import 'package:vnlfsocialapp/src/features/composer/domain/composer_draft.dart';
import 'package:vnlfsocialapp/src/features/composer/domain/composer_format.dart';

void main() {
  test(
    'switching a post to ARTICLE moves image attachments into document nodes',
    () {
      final article = asArticle(
        const ComposerDraft(
          id: 'draft',
          version: 3,
          media: [
            DraftMedia(
              id: 'photo',
              url: 'https://example.invalid/photo.webp',
              mime: 'image/webp',
              alt: 'Ảnh được giữ',
            ),
          ],
          document: {
            'type': 'doc',
            'content': [
              {
                'type': 'paragraph',
                'content': [
                  {'type': 'text', 'text': 'Nội dung'},
                ],
              },
            ],
          },
        ),
      );
      expect(article.format, 'ARTICLE');
      expect(article.media, isEmpty);
      expect(
        article.assets['photo']!.url,
        'https://example.invalid/photo.webp',
      );
      expect((article.document['content'] as List).last, {
        'type': 'image',
        'attrs': {
          'assetId': 'photo',
          'src': 'https://example.invalid/photo.webp',
          'alt': 'Ảnh được giữ',
          'layout': 'normal',
        },
      });
    },
  );
  test('video cannot be converted into an article image', () {
    expect(
      () => asArticle(
        const ComposerDraft(
          id: 'draft',
          version: 3,
          media: [
            DraftMedia(
              id: 'video',
              url: 'https://example.invalid/clip.mp4',
              mime: 'video/mp4',
            ),
          ],
        ),
      ),
      throwsA(isA<ParseFailure>()),
    );
  });
  test('article conversion moves asset-backed images into attachments and keeps text', () {
    final post = asRegularPost(
      const ComposerDraft(
        id: 'draft',
        version: 7,
        format: 'ARTICLE',
        title: 'Tiêu đề',
        coverAssetId: 'cover',
        assets: {
          'image': DraftMedia(
            id: 'image',
            url: 'https://example.invalid/image.webp',
            mime: 'image/webp',
          ),
        },
        document: {
          'type': 'doc',
          'content': [
            {
              'type': 'paragraph',
              'content': [
                {'type': 'text', 'text': 'Giữ nguyên văn bản'},
              ],
            },
            {
              'type': 'image',
              'attrs': {'assetId': 'image', 'alt': 'Ảnh đính kèm'},
            },
            {
              'type': 'futureNode',
              'attrs': {'preserve': true},
            },
          ],
        },
      ),
    );
    expect(post.format, 'POST');
    expect(post.coverAssetId, isNull);
    expect(post.media.single.alt, 'Ảnh đính kèm');
    expect(post.version, 7);
    expect((post.document['content'] as List).last['type'], 'futureNode');
    expect((post.document['content'] as List).length, 2);
  });
  test(
    'unresolved images block conversion instead of silently dropping media',
    () {
      expect(
        () => asRegularPost(
          const ComposerDraft(
            id: 'draft',
            version: 1,
            format: 'ARTICLE',
            document: {
              'type': 'doc',
              'content': [
                {
                  'type': 'image',
                  'attrs': {'src': 'https://example.invalid/external.webp'},
                },
              ],
            },
          ),
        ),
        throwsA(isA<ParseFailure>()),
      );
    },
  );
}
