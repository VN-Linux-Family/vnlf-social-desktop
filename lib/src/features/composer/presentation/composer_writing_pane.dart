import 'package:flutter/material.dart';

import '../../../design_system/components/vnlf_rich_content.dart';
import '../../../i18n/vi.dart';
import '../domain/composer_draft.dart';
import 'composer_controller.dart';
import 'composer_editor.dart';
import 'composer_metadata.dart';
import 'composer_poll_editor.dart';

class ComposerWritingPane extends StatelessWidget {
  const ComposerWritingPane({
    super.key,
    required this.controller,
    required this.editorKey,
    required this.preview,
    required this.onPick,
  });
  final ComposerController controller;
  final GlobalKey<ComposerEditorState> editorKey;
  final bool preview;
  final Future<void> Function(String placement, bool video) onPick;
  @override
  Widget build(BuildContext context) {
    final draft = controller.draft;
    final locked = controller.publishUncertain;
    return LayoutBuilder(
      builder: (context, size) {
        final writing = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (draft.format == 'ARTICLE')
              Padding(
                padding: const EdgeInsets.all(16),
                child: ComposerTextField(
                  label: vi.app.composer.tieuDeArticle,
                  value: draft.title,
                  maxLength: 180,
                  disabled: locked,
                  onChanged: (value) =>
                      controller.edit(controller.draft.copyWith(title: value)),
                ),
              ),
            if (preview)
              Padding(
                padding: const EdgeInsets.all(16),
                child: VnlfRichContent(
                  document: _resolvedDocument(draft),
                  showImages: draft.format == 'ARTICLE',
                  postStyle: draft.format == 'POST',
                ),
              ),
            Offstage(
              offstage: preview,
              child: ComposerEditor(
                key: editorKey,
                document: draft.document,
                assets: draft.assets,
                readOnly: locked,
                postStyle: draft.format == 'POST',
                onChanged: (document) => controller.edit(
                  controller.draft.copyWith(document: document),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 8,
                children: [
                  TextButton.icon(
                    onPressed: controller.busy || locked
                        ? null
                        : () => onPick(
                            draft.format == 'ARTICLE' ? 'INLINE' : 'ATTACHMENT',
                            false,
                          ),
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: Text(vi.articleEditor.themAnh),
                  ),
                  if (draft.format == 'POST')
                    TextButton.icon(
                      onPressed:
                          controller.busy ||
                              locked ||
                              draft.media.any((m) => m.isVideo)
                          ? null
                          : () => onPick('ATTACHMENT', true),
                      icon: const Icon(Icons.video_library_outlined),
                      label: Text(vi.articleEditor.themVideo),
                    ),
                ],
              ),
            ),
            if (draft.format == 'POST')
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: ComposerPollEditor(
                  draft: draft,
                  disabled: locked,
                  onChanged: controller.edit,
                ),
              ),
            if (draft.media.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final media in draft.media)
                      SizedBox(
                        width: 180,
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (!media.isVideo && media.url.isNotEmpty)
                                  Image.network(
                                    media.url,
                                    height: 100,
                                    cacheWidth: 360,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, _, _) =>
                                        const Icon(Icons.broken_image_outlined),
                                  )
                                else
                                  const Icon(
                                    Icons.video_library_outlined,
                                    size: 40,
                                  ),
                                if (media.isProcessing)
                                  Text(vi.app.common.videoDangDuocXu),
                                if (media.state == 'FAILED')
                                  Text(vi.app.composer.xuLyVideoThat),
                                if (!media.isReady)
                                  TextButton(
                                    onPressed: controller.busy
                                        ? null
                                        : () => controller.refreshMedia(media),
                                    child: Text(
                                      vi.app.composer.kiemTraTrangThai,
                                    ),
                                  ),
                                ComposerTextField(
                                  label: vi.app.composer.vanBanThayThe,
                                  value: media.alt,
                                  maxLength: 300,
                                  disabled: locked,
                                  onChanged: (alt) => controller.edit(
                                    controller.draft.copyWith(
                                      media: [
                                        for (final item
                                            in controller.draft.media)
                                          if (item.id == media.id)
                                            item.copyWith(alt: alt)
                                          else
                                            item,
                                      ],
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: controller.busy || locked
                                      ? null
                                      : () => controller.removeMedia(media.id),
                                  child: Text(vi.articleEditor.go),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        );
        if (draft.format != 'ARTICLE') return writing;
        final metadata = ComposerMetadata(
          draft: draft,
          disabled: locked,
          onChanged: controller.edit,
          onCover: controller.busy || locked
              ? null
              : () => onPick('COVER', false),
          onRemoveCover: controller.busy || locked || draft.coverAssetId == null
              ? null
              : () => controller.removeMedia(draft.coverAssetId!),
        );
        return size.maxWidth > 850
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: writing),
                  SizedBox(width: 300, child: metadata),
                ],
              )
            : Column(children: [writing, metadata]);
      },
    );
  }
}

Map<String, dynamic> _resolvedDocument(ComposerDraft draft) {
  Map<String, dynamic> resolve(Map<String, dynamic> node) {
    final attrs = node['attrs'];
    final asset = attrs is Map ? draft.assets[attrs['assetId']] : null;
    return {
      ...node,
      if (asset != null) 'attrs': {...attrs as Map, 'src': asset.url},
      if (node['content'] is List)
        'content': [
          for (final child
              in (node['content'] as List).whereType<Map<String, dynamic>>())
            resolve(child),
        ],
    };
  }

  return resolve(draft.document);
}
