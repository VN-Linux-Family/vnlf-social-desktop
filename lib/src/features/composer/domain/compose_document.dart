import 'package:markdown/markdown.dart' as md;

/// Converts editing syntax to the website's structured document, never raw HTML.
Map<String, dynamic> composeDocument(String source) {
  final parsed = md.Document(
    blockSyntaxes: [const md.FencedCodeBlockSyntax()],
    inlineSyntaxes: [md.StrikethroughSyntax()],
    encodeHtml: false,
  ).parseLines(source.replaceAll('\r\n', '\n').split('\n'));
  List<Map<String, dynamic>> inline(
    List<md.Node> nodes, [
    List<Map<String, dynamic>> marks = const [],
  ]) {
    final result = <Map<String, dynamic>>[];
    for (final node in nodes) {
      if (node is md.Text) {
        if (node.text.isNotEmpty) {
          result.add({
            'type': 'text',
            'text': node.text,
            if (marks.isNotEmpty) 'marks': marks,
          });
        }
        continue;
      }
      if (node is! md.Element) continue;
      if (node.tag == 'br') {
        result.add({'type': 'hardBreak'});
        continue;
      }
      if (node.tag == 'img') {
        result.add({'type': 'text', 'text': node.attributes['alt'] ?? ''});
        continue;
      }
      Map<String, dynamic>? mark;
      switch (node.tag) {
        case 'strong':
          mark = {'type': 'bold'};
        case 'em':
          mark = {'type': 'italic'};
        case 'del':
          mark = {'type': 'strike'};
        case 'code':
          mark = {'type': 'code'};
        case 'a':
          final href = node.attributes['href'] ?? '';
          final uri = Uri.tryParse(href);
          if (uri != null &&
              ({'http', 'https'}.contains(uri.scheme) && uri.host.isNotEmpty ||
                  uri.scheme == 'mailto')) {
            mark = {
              'type': 'link',
              'attrs': {'href': href},
            };
          }
      }
      result.addAll(inline(node.children ?? [], [...marks, ?mark]));
    }
    return result;
  }

  List<Map<String, dynamic>> blocks(List<md.Node> nodes) {
    final result = <Map<String, dynamic>>[];
    for (final node in nodes) {
      if (node is md.Text) {
        if (node.text.trim().isNotEmpty) {
          result.add({
            'type': 'paragraph',
            'content': inline([node]),
          });
        }
        continue;
      }
      if (node is! md.Element) continue;
      final children = node.children ?? <md.Node>[];
      switch (node.tag) {
        case 'p':
          result.add({'type': 'paragraph', 'content': inline(children)});
        case 'h1':
        case 'h2':
        case 'h3':
        case 'h4':
        case 'h5':
        case 'h6':
          result.add({
            'type': 'heading',
            'attrs': {'level': node.tag == 'h1' || node.tag == 'h2' ? 2 : 3},
            'content': inline(children),
          });
        case 'blockquote':
          result.add({'type': 'blockquote', 'content': blocks(children)});
        case 'ul':
        case 'ol':
          result.add({
            'type': node.tag == 'ul' ? 'bulletList' : 'orderedList',
            if (node.tag == 'ol')
              'attrs': {
                'start': int.tryParse(node.attributes['start'] ?? '1') ?? 1,
              },
            'content': blocks(children),
          });
        case 'li':
          final blockChildren = children.any(
            (n) =>
                n is md.Element &&
                {'p', 'ul', 'ol', 'blockquote', 'pre'}.contains(n.tag),
          );
          result.add({
            'type': 'listItem',
            'content': blockChildren
                ? blocks(children)
                : [
                    {'type': 'paragraph', 'content': inline(children)},
                  ],
          });
        case 'pre':
          result.add({
            'type': 'codeBlock',
            'content': [
              {'type': 'text', 'text': node.textContent},
            ],
          });
        case 'hr':
          result.add({'type': 'horizontalRule'});
        default:
          result.addAll(blocks(children));
      }
    }
    return result;
  }

  return {'type': 'doc', 'content': blocks(parsed)};
}

String documentPlainText(Map<String, dynamic> doc) {
  String text(Map<String, dynamic> node) {
    if (node['type'] == 'text') return node['text'] as String? ?? '';
    if (node['type'] == 'hardBreak') return '\n';
    final content = (node['content'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(text)
        .join();
    return content +
        ({
              'paragraph',
              'heading',
              'codeBlock',
              'listItem',
            }.contains(node['type'])
            ? '\n'
            : '');
  }

  return text(doc).trim();
}
