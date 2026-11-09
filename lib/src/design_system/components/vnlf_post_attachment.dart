import 'package:flutter/material.dart';

import '../../i18n/vi.dart';
import '../models/vnlf_models.dart';
import 'vnlf_code_block.dart';
import 'vnlf_media_gallery.dart';
import 'vnlf_media_preview.dart';

/// The media under a post: gallery or video, an image placeholder, a code
/// block or a project card.
class VnlfPostAttachmentView extends StatelessWidget {
  const VnlfPostAttachmentView({
    super.key,
    required this.attachment,
    this.codeCopyLabel = '',
    this.codeCopiedLabel = '',
    this.codeBlockSemanticLabel,
  });

  final PostAttachment attachment;
  final String codeCopyLabel;
  final String codeCopiedLabel;
  final String? codeBlockSemanticLabel;

  @override
  Widget build(BuildContext context) => switch (attachment) {
    final MediaGalleryAttachment gallery => VnlfMediaGallery(
      items: gallery.items,
    ),
    final ImagePlaceholderAttachment image => VnlfImagePlaceholder(
      imageUrl: image.imageUrl,
      aspectRatio: image.aspectRatio,
      label: image.label,
      semanticLabel: image.semanticLabel,
    ),
    final CodeBlockAttachment code => VnlfCodeBlock(
      code: code.code,
      showHorizontalScrollbar: code.showHorizontalScrollbar,
      copyLabel: code.copyLabel.isNotEmpty
          ? code.copyLabel
          : codeCopyLabel.isNotEmpty
          ? codeCopyLabel
          : vi.articleRenderer.saoChep,
      copiedLabel: code.copiedLabel.isNotEmpty
          ? code.copiedLabel
          : codeCopiedLabel.isNotEmpty
          ? codeCopiedLabel
          : vi.articleRenderer.daChep,
      semanticLabel: code.semanticLabel ?? codeBlockSemanticLabel,
      copyButtonSemanticLabel: code.copyButtonSemanticLabel,
    ),
    final ProjectPreviewAttachment project => VnlfProjectPreviewCard(
      project: project.project,
    ),
  };
}
