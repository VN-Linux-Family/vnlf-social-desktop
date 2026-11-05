import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/external_uri.dart';
import '../tokens/vnlf_colors.dart';
import '../tokens/vnlf_typography.dart';
import 'vnlf_code_block.dart';
import 'vnlf_media_gallery.dart';
import '../models/vnlf_models.dart';

/// Native rendering of the structured document used by the website editor.
class VnlfRichContent extends StatefulWidget {
  const VnlfRichContent({
    super.key,
    required this.document,
    this.showImages = false,
    this.selectable = false,
  });
  final Map<String, dynamic> document;
  final bool showImages;
  final bool selectable;
  @override
  State<VnlfRichContent> createState() => _VnlfRichContentState();
}

class _VnlfRichContentState extends State<VnlfRichContent> {
  final _links = <TapGestureRecognizer>[];
  List<Map<String, dynamic>> _children(Map<String, dynamic> node) =>
      (node['content'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .toList();
  Map<String, dynamic> _attrs(Map<String, dynamic> node) =>
      node['attrs'] as Map<String, dynamic>? ?? {};
  String _text(Map<String, dynamic> node) => node['type'] == 'text'
      ? node['text'] as String? ?? ''
      : _children(node).map(_text).join();

  void _clearLinks() {
    for (final link in _links) {
      link.dispose();
    }
    _links.clear();
  }

  @override
  void dispose() {
    _clearLinks();
    super.dispose();
  }

  Future<void> _open(Uri uri) async {
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    } catch (_) {
      /* A visible message below covers platform launcher failures. */
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          Localizations.localeOf(context).languageCode == 'en'
              ? 'Could not open link'
              : 'Không mở được liên kết',
        ),
      ),
    );
  }

  InlineSpan _inline(Map<String, dynamic> node) {
    if (node['type'] == 'hardBreak') return const TextSpan(text: '\n');
    final colors = VnlfColors.of(context);
    TextStyle style = const TextStyle();
    TapGestureRecognizer? recognizer;
    for (final mark
        in (node['marks'] as List? ?? []).whereType<Map<String, dynamic>>()) {
      switch (mark['type']) {
        case 'bold':
          style = style.copyWith(fontWeight: FontWeight.w700);
        case 'italic':
          style = style.copyWith(fontStyle: FontStyle.italic);
        case 'strike':
          style = style.copyWith(decoration: TextDecoration.lineThrough);
        case 'code':
          style = style.copyWith(
            fontFamily: 'monospace',
            backgroundColor: colors.surfaceSoft,
          );
        case 'link':
          final uri = externalWebUri(_attrs(mark)['href'] as String?);
          if (uri != null) {
            style = style.copyWith(
              color: colors.blue,
              decoration: TextDecoration.underline,
            );
            recognizer = TapGestureRecognizer()..onTap = () => _open(uri);
            _links.add(recognizer);
          }
      }
    }
    return TextSpan(
      text: node['text'] as String?,
      style: style,
      recognizer: recognizer,
      children: _children(node).map(_inline).toList(),
    );
  }

  Widget _node(Map<String, dynamic> node, {int depth = 0}) {
    final colors = VnlfColors.of(context);
    final children = _children(node);
    final english = Localizations.localeOf(context).languageCode == 'en';
    Widget blocks() => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [for (final child in children) _node(child, depth: depth + 1)],
    );
    switch (node['type']) {
      case 'text':
      case 'hardBreak':
        return Text.rich(_inline(node), style: VnlfTypography.body(colors.ink));
      case 'paragraph':
      case 'heading':
        final heading = node['type'] == 'heading';
        final style = heading
            ? (_attrs(node)['level'] == 3
                  ? VnlfTypography.h3(colors.ink)
                  : VnlfTypography.h2(colors.ink))
            : VnlfTypography.body(colors.ink);
        return Padding(
          padding: EdgeInsets.only(top: heading ? 10 : 0, bottom: 8),
          child: Semantics(
            header: heading,
            child: Text.rich(
              TextSpan(
                children: children.isEmpty
                    ? [const TextSpan(text: '\n')]
                    : children.map(_inline).toList(),
              ),
              style: style,
            ),
          ),
        );
      case 'blockquote':
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.only(left: 12),
          decoration: BoxDecoration(
            border: Border(left: BorderSide(width: 3, color: colors.line)),
          ),
          child: blocks(),
        );
      case 'bulletList':
      case 'orderedList':
        final start = _attrs(node)['start'] is int
            ? _attrs(node)['start'] as int
            : 1;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: depth > 8 ? 14 : 24,
                      child: Text(
                        node['type'] == 'orderedList' ? '${start + i}.' : '•',
                        style: VnlfTypography.body(colors.ink),
                      ),
                    ),
                    Expanded(child: _node(children[i], depth: depth + 1)),
                  ],
                ),
            ],
          ),
        );
      case 'codeBlock':
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: VnlfCodeBlock(
            code: _text(node),
            copyLabel: english ? 'Copy' : 'Sao chép',
            copiedLabel: english ? 'Copied' : 'Đã chép',
          ),
        );
      case 'horizontalRule':
        return Divider(color: colors.line, height: 24);
      case 'image':
        if (!widget.showImages) return const SizedBox.shrink();
        final attrs = _attrs(node);
        final url = attrs['src'] as String?;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (externalWebUri(url) != null)
                VnlfMediaGallery(
                  items: [
                    PostMediaData(
                      url: url!,
                      alt: attrs['alt'] as String? ?? '',
                      width: attrs['width'] as int?,
                      height: attrs['height'] as int?,
                    ),
                  ],
                )
              else
                Text(
                  english ? 'Image unavailable' : 'Ảnh không còn trong bộ',
                  style: VnlfTypography.meta(colors.muted),
                ),
              if (attrs['caption'] is String &&
                  (attrs['caption'] as String).isNotEmpty)
                Text(
                  attrs['caption'] as String,
                  style: VnlfTypography.meta(colors.muted),
                ),
            ],
          ),
        );
      default:
        return blocks();
    }
  }

  @override
  Widget build(BuildContext context) {
    _clearLinks();
    final content = _node(widget.document);
    return widget.selectable ? SelectionArea(child: content) : content;
  }
}
