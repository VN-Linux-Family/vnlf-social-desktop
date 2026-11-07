import 'dart:convert';

/// Converts the server's tree to native editor lines. Unrepresentable blocks
/// remain structured embeds, so editing adjacent text cannot discard them.
abstract final class TipTapDeltaCodec {
  static List<Map<String, dynamic>> toDelta(Map<String, dynamic> document) {
    final result = <Map<String, dynamic>>[];
    String? previousGroup;
    for (final value in document['content'] as List? ?? const []) {
      final node = Map<String, dynamic>.from(value as Map);
      final group =
          const {
            'codeBlock',
            'blockquote',
            'bulletList',
            'orderedList',
          }.contains(node['type'])
          ? node['type'] as String
          : null;
      final operations = _block(node);
      // Consecutive independent lists/quotes/code blocks must keep their bounds.
      final lossless =
          operations != null &&
          (group == null || group != previousGroup) &&
          _same((fromDelta(operations)['content'] as List).singleOrNull, node);
      result.addAll(lossless ? operations : _embed('vnlf_raw', node));
      previousGroup = lossless ? group : null;
    }
    if (result.isEmpty) result.add({'insert': '\n'});
    return result;
  }

  static Map<String, dynamic> fromDelta(
    List<dynamic> delta, {
    Map<String, dynamic>? original,
  }) {
    final lines = <_Line>[];
    var content = <Map<String, dynamic>>[];
    for (final value in delta) {
      final op = Map<String, dynamic>.from(value as Map);
      final attrs = Map<String, dynamic>.from(
        op['attributes'] as Map? ?? const {},
      );
      final insert = op['insert'];
      if (insert is Map) {
        content.add({'embed': Map<String, dynamic>.from(insert)});
      } else if (insert is String) {
        final parts = insert.split('\n');
        for (var i = 0; i < parts.length; i++) {
          if (parts[i].isNotEmpty) {
            final hardLines = parts[i].split('\u2028');
            for (var j = 0; j < hardLines.length; j++) {
              if (j > 0) content.add({'type': 'hardBreak'});
              if (hardLines[j].isNotEmpty) {
                final marks = <Map<String, dynamic>>[
                  for (final entry in _marks.entries)
                    if (attrs[entry.value] == true) {'type': entry.key},
                  if (attrs['a'] is String)
                    {
                      'type': 'link',
                      'attrs': {'href': attrs['a']},
                    },
                ];
                final text = <String, dynamic>{
                  'type': 'text',
                  'text': hardLines[j],
                  if (marks.isNotEmpty) 'marks': marks,
                };
                if (content.isNotEmpty &&
                    content.last['type'] == 'text' &&
                    _same(content.last['marks'], text['marks'])) {
                  content.last['text'] =
                      '${content.last['text']}${text['text']}';
                } else {
                  content.add(text);
                }
              }
            }
          }
          if (i < parts.length - 1) {
            lines.add(_Line(content, attrs));
            content = [];
          }
        }
      } else {
        throw const FormatException('Invalid editor insertion');
      }
    }
    if (content.isNotEmpty) lines.add(_Line(content, const {}));
    final nodes = <Map<String, dynamic>>[];
    String? previousGroup;
    for (final line in lines) {
      if (line.content.length == 1 && line.content.single['embed'] is Map) {
        final embed = line.content.single['embed'] as Map;
        final node = embed['node'];
        if (!const {'vnlf_raw', 'vnlf_image', 'hr'}.contains(embed['_type']) ||
            node is! Map) {
          throw const FormatException('Unsupported editor embed');
        }
        nodes.add(_clone(Map<String, dynamic>.from(node)));
        previousGroup = null;
        continue;
      }
      final block = line.attrs['block'];
      final heading = line.attrs['heading'];
      final paragraph = <String, dynamic>{
        'type': 'paragraph',
        if (line.content.isNotEmpty) 'content': line.content,
      };
      if (block == 'code') {
        final text = line.content
            .map((n) => n['type'] == 'hardBreak' ? '\n' : n['text'] ?? '')
            .join();
        if (previousGroup == 'code') {
          final child = (nodes.last['content'] as List).single as Map;
          child['text'] = '${child['text']}\n$text';
        } else {
          nodes.add({
            'type': 'codeBlock',
            'content': [
              {'type': 'text', 'text': text},
            ],
          });
        }
      } else if (block == 'quote' || block == 'ul' || block == 'ol') {
        final type = block == 'quote'
            ? 'blockquote'
            : block == 'ul'
            ? 'bulletList'
            : 'orderedList';
        final child = block == 'quote'
            ? paragraph
            : {
                'type': 'listItem',
                'content': [paragraph],
              };
        if (previousGroup == block) {
          (nodes.last['content'] as List).add(child);
        } else {
          nodes.add({
            'type': type,
            'content': [child],
          });
        }
      } else if (heading == 2 || heading == 3) {
        nodes.add({
          'type': 'heading',
          'attrs': {'level': heading},
          if (line.content.isNotEmpty) 'content': line.content,
        });
      } else {
        nodes.add(paragraph);
      }
      previousGroup = block is String ? block : null;
    }
    return {...?original, 'type': 'doc', 'content': nodes};
  }

  static List<Map<String, dynamic>>? _block(Map<String, dynamic> node) {
    final type = node['type'];
    if (type == 'image') return _embed('vnlf_image', node);
    if (type == 'horizontalRule') return _embed('hr', node);
    if (type == 'paragraph' || type == 'heading') {
      final inline = _inline(node['content'] as List? ?? const []);
      if (inline == null) return null;
      return [
        ...inline,
        {
          'insert': '\n',
          if (type == 'heading')
            'attributes': {'heading': (node['attrs'] as Map?)?['level']},
        },
      ];
    }
    if (type == 'codeBlock') {
      final children = node['content'] as List? ?? const [];
      if (children.any((n) => n is! Map || n['type'] != 'text')) return null;
      final text = children.map((n) => n['text'] as String? ?? '').join();
      return [
        for (final line in text.split('\n')) ...[
          if (line.isNotEmpty) {'insert': line},
          {
            'insert': '\n',
            'attributes': {'block': 'code'},
          },
        ],
      ];
    }
    if (type == 'blockquote' || type == 'bulletList' || type == 'orderedList') {
      final operations = <Map<String, dynamic>>[];
      for (final item in node['content'] as List? ?? const []) {
        Map<dynamic, dynamic> paragraph;
        if (type == 'blockquote') {
          if (item is! Map || item['type'] != 'paragraph') return null;
          paragraph = item;
        } else {
          if (item is! Map || item['type'] != 'listItem') return null;
          final children = item['content'];
          if (children is! List ||
              children.length != 1 ||
              children.single is! Map ||
              children.single['type'] != 'paragraph') {
            return null;
          }
          paragraph = children.single as Map;
        }
        final inline = _inline(paragraph['content'] as List? ?? const []);
        if (inline == null) return null;
        operations.addAll([
          ...inline,
          {
            'insert': '\n',
            'attributes': {
              'block': type == 'blockquote'
                  ? 'quote'
                  : type == 'bulletList'
                  ? 'ul'
                  : 'ol',
            },
          },
        ]);
      }
      return operations.isEmpty ? null : operations;
    }
    return null;
  }

  static List<Map<String, dynamic>>? _inline(List<dynamic> children) {
    final ops = <Map<String, dynamic>>[];
    for (final node in children) {
      if (node is! Map) return null;
      if (node['type'] == 'hardBreak') {
        ops.add({'insert': '\u2028'});
        continue;
      }
      if (node['type'] != 'text' || node['text'] is! String) return null;
      final text = node['text'] as String;
      if (text.contains('\n') || text.contains('\u2028')) return null;
      final attrs = <String, dynamic>{};
      for (final mark in node['marks'] as List? ?? const []) {
        if (mark is! Map) return null;
        if (_marks.containsKey(mark['type'])) {
          attrs[_marks[mark['type']]!] = true;
        } else if (mark['type'] == 'link' &&
            mark['attrs'] is Map &&
            (mark['attrs'] as Map)['href'] is String) {
          attrs['a'] = (mark['attrs'] as Map)['href'];
        } else {
          return null;
        }
      }
      if (text.isNotEmpty) {
        ops.add({'insert': text, if (attrs.isNotEmpty) 'attributes': attrs});
      }
    }
    return ops;
  }

  static List<Map<String, dynamic>> _embed(
    String type,
    Map<String, dynamic> node,
  ) => [
    {
      'insert': {'_type': type, '_inline': false, 'node': _clone(node)},
    },
    {'insert': '\n'},
  ];
}

const _marks = {'bold': 'b', 'italic': 'i', 'strike': 's', 'code': 'c'};
Map<String, dynamic> _clone(Map<String, dynamic> node) =>
    jsonDecode(jsonEncode(node)) as Map<String, dynamic>;
bool _same(Object? a, Object? b) =>
    jsonEncode(_sorted(a)) == jsonEncode(_sorted(b));
Object? _sorted(Object? value) {
  if (value is Map) {
    return {
      for (final key in value.keys.map((k) => k as String).toList()..sort())
        key: _sorted(value[key]),
    };
  }
  if (value is List) return value.map(_sorted).toList();
  return value;
}

final class _Line {
  const _Line(this.content, this.attrs);
  final List<Map<String, dynamic>> content;
  final Map<String, dynamic> attrs;
}
