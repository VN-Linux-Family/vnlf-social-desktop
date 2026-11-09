import 'dart:async';
import 'dart:convert';

import 'package:fleather/fleather.dart';
import 'package:flutter/material.dart';

import '../../../core/external_uri.dart';
import '../../../design_system/components/vnlf_rich_content.dart';
import '../../../i18n/vi.dart';
import '../domain/composer_draft.dart';
import '../domain/tiptap_delta_codec.dart';
import 'composer_toolbar.dart';
import 'composer_editor_theme.dart';
import 'editor_localizations.dart';

class ComposerEditor extends StatefulWidget {
  const ComposerEditor({
    super.key,
    required this.document,
    required this.assets,
    required this.onChanged,
    this.readOnly = false,
    this.postStyle = false,
  });
  final Map<String, dynamic> document;
  final Map<String, DraftMedia> assets;
  final ValueChanged<Map<String, dynamic>> onChanged;
  final bool readOnly;
  final bool postStyle;
  @override
  State<ComposerEditor> createState() => ComposerEditorState();
}

class ComposerEditorState extends State<ComposerEditor> {
  late FleatherController _controller;
  StreamSubscription<ParchmentChange>? _changes;
  final _focus = FocusNode();
  Map<String, dynamic>? _emitted;
  @override
  void initState() {
    super.initState();
    _install(widget.document);
  }

  void _install(Map<String, dynamic> document) {
    _controller = FleatherController(
      document: ParchmentDocument.fromJson(TipTapDeltaCodec.toDelta(document)),
    );
    _changes = _controller.document.changes.listen((_) {
      if (!mounted) return;
      final delta = _controller.document
          .toDelta()
          .toJson()
          .map((op) => op.toJson())
          .toList();
      _emitted = TipTapDeltaCodec.fromDelta(delta, original: widget.document);
      widget.onChanged(_emitted!);
    });
  }

  @override
  void didUpdateWidget(covariant ComposerEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.document, _emitted) &&
        jsonEncode(widget.document) != jsonEncode(oldWidget.document)) {
      unawaited(_changes?.cancel());
      _controller.dispose();
      _install(widget.document);
    }
  }

  void insertImage(DraftMedia media) {
    if (widget.readOnly) return;
    final offset = _controller.selection.start.clamp(
      0,
      _controller.document.length - 1,
    );
    _controller.replaceText(
      offset,
      0,
      BlockEmbed(
        'vnlf_image',
        data: {
          'node': {
            'type': 'image',
            'attrs': {
              'assetId': media.id,
              'src': media.url,
              'alt': media.alt,
              'layout': 'normal',
              if (media.width != null) 'width': media.width,
              if (media.height != null) 'height': media.height,
            },
          },
        },
      ),
    );
  }

  @override
  void dispose() {
    unawaited(_changes?.cancel());
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Localizations.override(
    context: context,
    delegates: const [
      VietnameseEditorLocalizations.delegate,
      FleatherLocalizations.delegate,
    ],
    child: FleatherTheme(
      data: composerEditorTheme(context, postStyle: widget.postStyle),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          ComposerToolbar(controller: _controller, readOnly: widget.readOnly),
          const Divider(height: 1),
          FleatherEditor(
            controller: _controller,
            focusNode: _focus,
            readOnly: widget.readOnly,
            scrollable: false,
            minHeight: 180,
            padding: const EdgeInsets.all(16),
            embedBuilder: _embed,
            contextMenuBuilder: (context, editorState) =>
                AdaptiveTextSelectionToolbar.buttonItems(
                  buttonItems: editorState.contextMenuButtonItems,
                  anchors: editorState.contextMenuAnchors,
                ),
          ),
        ],
      ),
    ),
  );
  Widget _embed(BuildContext context, EmbedNode node) {
    final data = node.value.data['node'];
    if (data is! Map) return const SizedBox();
    final raw = Map<String, dynamic>.from(data);
    if (node.value.type == 'hr') return const Divider();
    if (node.value.type == 'vnlf_image') {
      final attrs = Map<String, dynamic>.from(raw['attrs'] as Map? ?? const {});
      final asset = widget.assets[attrs['assetId']];
      final url = asset?.url ?? attrs['src'] as String?;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (externalWebUri(url) != null)
            Image.network(
              url!,
              cacheWidth: 800,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) =>
                  const Icon(Icons.broken_image_outlined),
            )
          else
            const Icon(Icons.image_not_supported_outlined),
          if ((attrs['caption'] as String? ?? '').isNotEmpty)
            Text(attrs['caption'] as String),
          if (!widget.readOnly)
            TextButton.icon(
              onPressed: () => _imageSettings(node.documentOffset, raw),
              icon: const Icon(Icons.tune),
              label: Text(vi.app.composer.tuyChinhAnh),
            ),
        ],
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            VnlfRichContent(
              document: {
                'type': 'doc',
                'content': [raw],
              },
              showImages: true,
              postStyle: widget.postStyle,
            ),
            Text(
              vi.app.composer.noiDungNayDuoc,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _imageSettings(int offset, Map<String, dynamic> node) async {
    final attrs = Map<String, dynamic>.from(node['attrs'] as Map? ?? const {});
    final alt = TextEditingController(text: attrs['alt'] as String? ?? '');
    final caption = TextEditingController(
      text: attrs['caption'] as String? ?? '',
    );
    var layout = const {'normal', 'wide', 'full'}.contains(attrs['layout'])
        ? attrs['layout'] as String
        : 'normal';
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: Text(vi.app.composer.tuyChinhAnh),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: alt,
                  maxLength: 300,
                  decoration: InputDecoration(
                    labelText: vi.app.composer.vanBanThayThe,
                  ),
                ),
                TextField(
                  controller: caption,
                  decoration: InputDecoration(
                    labelText: vi.app.composer.chuThich,
                  ),
                ),
                DropdownButtonFormField<String>(
                  initialValue: layout,
                  items: [
                    DropdownMenuItem(
                      value: 'normal',
                      child: Text(vi.app.composer.binhThuong),
                    ),
                    DropdownMenuItem(
                      value: 'wide',
                      child: Text(vi.articleImageNode.rong),
                    ),
                    DropdownMenuItem(
                      value: 'full',
                      child: Text(vi.app.composer.toanChieuRong),
                    ),
                  ],
                  onChanged: (value) => update(() => layout = value!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(vi.common.huy),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, {
                ...node,
                'attrs': {
                  ...attrs,
                  'alt': alt.text,
                  'caption': caption.text,
                  'layout': layout,
                },
              }),
              child: Text(vi.articleEditor.apDung),
            ),
          ],
        ),
      ),
    );
    alt.dispose();
    caption.dispose();
    if (result != null && mounted && !widget.readOnly) {
      _controller.replaceText(
        offset,
        1,
        BlockEmbed('vnlf_image', data: {'node': result}),
      );
    }
  }
}
