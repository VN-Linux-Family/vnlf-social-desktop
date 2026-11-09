import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../core/external_uri.dart';
import '../../core/vnlf_navigation_helper.dart';
import '../../i18n/vi.dart';
import '../tokens/vnlf_colors.dart';
import '../tokens/vnlf_dimensions.dart';
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
    this.postStyle = false,
    this.articleDetail = false,
  });
  final Map<String, dynamic> document;
  final bool showImages;
  final bool selectable;
  final bool postStyle;
  final bool articleDetail;
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
      if (await openVnlfLink(context, uri.toString())) return;
    } catch (_) {
      /* A visible message below covers platform launcher failures. */
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(vi.app.common.khongMoDuocLien)));
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
          // Posts tint inline code; articles keep the browser's plain mono.
          style = widget.articleDetail
              ? style.copyWith(fontFamily: 'monospace')
              : style.copyWith(
                  fontFamily: 'monospace',
                  color: widget.postStyle ? colors.brand : null,
                  backgroundColor: widget.postStyle
                      ? colors.brandSoft
                      : colors.surfaceSoft,
                );
        case 'link':
          final uri = externalWebUri(_attrs(mark)['href'] as String?);
          if (uri != null) {
            // Article links read as plain text on the website.
            if (!widget.articleDetail) {
              style = style.copyWith(
                color: widget.postStyle ? colors.brand : colors.blue,
                decoration: TextDecoration.underline,
              );
            }
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

  double _headingHeight(bool h3) {
    if (widget.postStyle) return 1.5;
    if (widget.articleDetail) return h3 ? 1.7 : 1.08;
    return h3 ? 1.2 : 1.14;
  }

  bool get _compact =>
      VnlfViewportSize.fromWidth(MediaQuery.sizeOf(context).width) ==
      VnlfViewportSize.mobile;

  /// Vertical margins of a block, from the website's `.post-rich-text`
  /// (posts), `.detail-copy` with browser defaults (articles) or the feed.
  EdgeInsets _blockSpacing(Map<String, dynamic> node) {
    final type = node['type'];
    final h3 = _attrs(node)['level'] == 3;
    if (widget.postStyle) {
      return switch (type) {
        'paragraph' ||
        'bulletList' ||
        'orderedList' => const EdgeInsets.only(bottom: 8),
        'heading' => const EdgeInsets.only(top: 12, bottom: 8),
        'blockquote' || 'image' => const EdgeInsets.symmetric(vertical: 8),
        'codeBlock' => const EdgeInsets.symmetric(vertical: 20),
        'horizontalRule' => const EdgeInsets.symmetric(vertical: 28),
        _ => EdgeInsets.zero,
      };
    }
    if (widget.articleDetail) {
      final compact = _compact;
      return switch (type) {
        'paragraph' => EdgeInsets.only(bottom: compact ? 12 : 18),
        'heading' when h3 => const EdgeInsets.only(top: 24, bottom: 7),
        'heading' => EdgeInsets.only(
          top: compact ? 12 : 19,
          bottom: compact ? 7 : 10,
        ),
        'blockquote' ||
        'bulletList' ||
        'orderedList' ||
        'codeBlock' => const EdgeInsets.symmetric(vertical: 13),
        'horizontalRule' => const EdgeInsets.symmetric(vertical: 6.5),
        'image' => const EdgeInsets.symmetric(vertical: 25),
        _ => EdgeInsets.zero,
      };
    }
    return switch (type) {
      'paragraph' => const EdgeInsets.only(bottom: 17),
      'heading' when h3 => const EdgeInsets.only(top: 24, bottom: 7),
      'heading' => const EdgeInsets.only(top: 29, bottom: 9),
      'blockquote' ||
      'codeBlock' ||
      'image' => const EdgeInsets.symmetric(vertical: 8),
      'bulletList' || 'orderedList' => const EdgeInsets.only(bottom: 8),
      'horizontalRule' => const EdgeInsets.symmetric(vertical: 12),
      _ => EdgeInsets.zero,
    };
  }

  Widget _node(
    Map<String, dynamic> node, {
    int depth = 0,
    TextStyle? inherited,
  }) {
    final colors = VnlfColors.of(context);
    final body =
        inherited ??
        VnlfTypography.body(colors.ink)
            .copyWith(height: widget.postStyle ? 1.6 : 1.7);
    // Empty article paragraphs have no CSS line box. POST keeps explicit breaks.
    final children = _children(node)
        .where(
          (child) =>
              widget.postStyle ||
              child['type'] != 'paragraph' ||
              _children(child).isNotEmpty,
        )
        .toList();
    Widget blocks({TextStyle? style}) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < children.length; i++)
          Padding(
            // Adjacent vertical margins collapse to the larger one, as in CSS;
            // the first block's top and the last block's bottom are dropped.
            padding: EdgeInsets.only(
              top: i == 0
                  ? 0
                  : (_blockSpacing(children[i]).top -
                            _blockSpacing(children[i - 1]).bottom)
                        .clamp(0, double.infinity)
                        .toDouble(),
              bottom: i == children.length - 1
                  ? 0
                  : _blockSpacing(children[i]).bottom,
            ),
            child: _node(children[i], depth: depth + 1, inherited: style),
          ),
      ],
    );
    switch (node['type']) {
      case 'text':
      case 'hardBreak':
        return Text.rich(_inline(node), style: body);
      case 'paragraph':
      case 'heading':
        final heading = node['type'] == 'heading';
        final h3 = _attrs(node)['level'] == 3;
        final style = body.copyWith(
          fontWeight: heading ? FontWeight.w700 : null,
          height: heading ? _headingHeight(h3) : body.height,
          letterSpacing: heading && !widget.postStyle
              ? (h3
                    ? (widget.articleDetail ? 0 : -.39)
                    : widget.articleDetail
                    ? -.65
                    : -.52)
              : null,
        );
        return Semantics(
          header: heading,
          child: Text.rich(
            TextSpan(
              children: children.isEmpty
                  // One empty line, like the website's <br> in an empty <p>.
                  ? [const TextSpan(text: '\u200B')]
                  : children.map(_inline).toList(),
            ),
            style: style,
          ),
        );
      case 'blockquote':
        if (widget.articleDetail) {
          // The browser's default: indented 40px on both sides, no rule.
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: blocks(style: inherited),
          );
        }
        return Container(
          padding: widget.postStyle
              ? const EdgeInsets.fromLTRB(12, 5, 0, 5)
              : const EdgeInsets.only(left: 12),
          decoration: BoxDecoration(
            border: Border(left: BorderSide(width: 3, color: colors.line)),
          ),
          child: blocks(
            style: widget.postStyle
                ? body.copyWith(
                    color: colors.muted,
                    fontStyle: FontStyle.italic,
                  )
                : inherited,
          ),
        );
      case 'bulletList':
      case 'orderedList':
        final ordered = node['type'] == 'orderedList';
        final start = _attrs(node)['start'] is int
            ? _attrs(node)['start'] as int
            : 1;
        final indent = widget.articleDetail ? 40.0 : (depth > 8 ? 14.0 : 24.0);
        final bullet = switch (depth ~/ 2) {
          0 => '•',
          1 => '◦',
          _ => '▪',
        };
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < children.length; i++)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: indent,
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: widget.articleDetail ? 6 : 0,
                      ),
                      child: Text(
                        ordered ? '${start + i}.' : bullet,
                        textAlign: widget.articleDetail
                            ? TextAlign.right
                            : TextAlign.start,
                        style: body,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _node(
                      children[i],
                      depth: depth + 1,
                      inherited: inherited,
                    ),
                  ),
                ],
              ),
          ],
        );
      case 'codeBlock':
        return VnlfCodeBlock(
          code: _text(node),
          copyLabel: vi.articleRenderer.saoChep,
          copiedLabel: vi.articleRenderer.daChep,
        );
      case 'horizontalRule':
        return Container(height: 1, color: colors.line);
      case 'image':
        if (!widget.showImages) return const SizedBox.shrink();
        final attrs = _attrs(node);
        final url = attrs['src'] as String?;
        final figure = Column(
          crossAxisAlignment: widget.articleDetail
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.stretch,
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
                vi.app.designSystem.anhKhongConTrong,
                style: VnlfTypography.meta(colors.muted),
              ),
            if (attrs['caption'] is String &&
                (attrs['caption'] as String).isNotEmpty)
              Text(
                attrs['caption'] as String,
                textAlign: widget.articleDetail
                    ? TextAlign.center
                    : TextAlign.start,
                style: VnlfTypography.meta(colors.muted),
              ),
          ],
        );
        return widget.articleDetail
            ? Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: figure,
                ),
              )
            : figure;
      default:
        return blocks(style: inherited);
    }
  }

  @override
  Widget build(BuildContext context) {
    _clearLinks();
    final content = _node(widget.document);
    return widget.selectable ? SelectionArea(child: content) : content;
  }
}
