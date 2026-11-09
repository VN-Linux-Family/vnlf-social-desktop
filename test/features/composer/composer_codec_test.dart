import 'package:fleather/fleather.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/features/composer/domain/tiptap_delta_codec.dart';

void main() {
  for (final node in <Map<String, dynamic>>[
    {
      'type': 'paragraph',
      'content': [
        {
          'type': 'text',
          'text': 'Tiếng Việt: ặ ữ ờ ẫ ệ',
          'marks': [
            {'type': 'bold'},
            {'type': 'italic'},
          ],
        },
        {'type': 'hardBreak'},
        {
          'type': 'text',
          'text': 'Dòng tiếp theo',
          'marks': [
            {
              'type': 'link',
              'attrs': {'href': 'https://example.invalid'},
            },
          ],
        },
      ],
    },
    {
      'type': 'heading',
      'attrs': {'level': 2},
      'content': [
        {'type': 'text', 'text': 'Tiêu đề'},
      ],
    },
    {
      'type': 'codeBlock',
      'content': [
        {'type': 'text', 'text': 'printf hello\nprintf goodbye\n'},
      ],
    },
    {
      'type': 'blockquote',
      'content': [
        {
          'type': 'paragraph',
          'content': [
            {'type': 'text', 'text': 'Một'},
          ],
        },
        {
          'type': 'paragraph',
          'content': [
            {'type': 'text', 'text': 'Hai'},
          ],
        },
      ],
    },
    {
      'type': 'bulletList',
      'content': [
        {
          'type': 'listItem',
          'content': [
            {
              'type': 'paragraph',
              'content': [
                {'type': 'text', 'text': 'Một'},
              ],
            },
          ],
        },
        {
          'type': 'listItem',
          'content': [
            {
              'type': 'paragraph',
              'content': [
                {'type': 'text', 'text': 'Hai'},
              ],
            },
          ],
        },
      ],
    },
    {
      'type': 'image',
      'attrs': {
        'assetId': 'synthetic-asset',
        'src': 'https://example.invalid/photo.webp',
        'alt': 'Ảnh',
        'caption': 'Chú thích',
        'layout': 'wide',
        'width': 600,
        'height': 400,
      },
    },
    {'type': 'horizontalRule'},
    {
      'type': 'futureBlock',
      'attrs': {'futureOption': true},
      'content': [
        {'type': 'text', 'text': 'Giữ nguyên'},
      ],
    },
    {
      'type': 'paragraph',
      'content': [
        {
          'type': 'text',
          'text': 'Nội dung mới',
          'marks': [
            {
              'type': 'futureMark',
              'attrs': {'data': 1},
            },
          ],
        },
      ],
    },
    {
      'type': 'orderedList',
      'attrs': {'start': 5},
      'content': [
        {
          'type': 'listItem',
          'content': [
            {
              'type': 'paragraph',
              'content': [
                {'type': 'text', 'text': 'Bước 5'},
              ],
            },
          ],
        },
      ],
    },
  ]) {
    test(
      'native editor preserves ${node['type']} through its real document model: $node',
      () {
        final source = {
          'type': 'doc',
          'content': [node],
        };
        final document = ParchmentDocument.fromJson(
          TipTapDeltaCodec.toDelta(source),
        );
        final result = TipTapDeltaCodec.fromDelta(
          document.toDelta().toJson().map((op) => op.toJson()).toList(),
        );
        expect(result, source);
      },
    );
  }
  test('editing a known paragraph preserves neighboring unknown content', () {
    final unknown = {
      'type': 'futureBlock',
      'attrs': {'setting': 'keep'},
    };
    final document = ParchmentDocument.fromJson(
      TipTapDeltaCodec.toDelta({
        'type': 'doc',
        'content': [
          {
            'type': 'paragraph',
            'content': [
              {'type': 'text', 'text': 'Cũ'},
            ],
          },
          unknown,
        ],
      }),
    );
    document.insert(2, ' mới');
    final result = TipTapDeltaCodec.fromDelta(
      document.toDelta().toJson().map((op) => op.toJson()).toList(),
    );
    expect((result['content'] as List).last, unknown);
    expect((result['content'] as List).first['content'][0]['text'], 'Cũ mới');
  });
}
