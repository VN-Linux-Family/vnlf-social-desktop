import 'package:flutter/material.dart';

import '../models/vnlf_models.dart';
import '../tokens/vnlf_colors.dart';
import '../tokens/vnlf_dimensions.dart';
import '../tokens/vnlf_typography.dart';

/// Neutral placeholder for post media attachments.
///
/// Specific post screenshots (such as the Debian desktop illustration) are not
/// bundled in the design system. Real post images load dynamically from the API
/// at runtime.
class VnlfImagePlaceholder extends StatelessWidget {
  const VnlfImagePlaceholder({
    super.key,
    this.imageUrl,
    this.aspectRatio = 16 / 9,
    this.label = '',
    this.icon = Icons.image_outlined,
    this.semanticLabel,
  });

  final String? imageUrl;
  final double aspectRatio;
  final String label;
  final IconData icon;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final effectiveSemantics =
        semanticLabel ?? (label.isNotEmpty ? label : null);

    Widget fallback() => Container(
      decoration: BoxDecoration(
        color: colors.surfaceSoft,
        borderRadius: BorderRadius.circular(VnlfDimensions.radiusMd),
        border: Border.all(color: colors.line),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 36, color: colors.muted),
              if (label.isNotEmpty) ...[
                const SizedBox(height: 8),
                // The box keeps its aspect ratio, so large text is truncated.
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: VnlfTypography.caption(colors.muted),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      // The website's article cover: the image's own proportions, at most
      // 480px tall (360px up to 520px wide), cropped to fill, in a 14px
      // rounded frame with a hairline.
      final maxHeight = MediaQuery.sizeOf(context).width <= 520 ? 360.0 : 480.0;
      return Semantics(
        label: effectiveSemantics,
        image: true,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: colors.surfaceSoft,
            border: Border.all(color: colors.line),
            borderRadius: BorderRadius.circular(VnlfDimensions.radiusLg),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: Image.network(
              imageUrl!,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  AspectRatio(aspectRatio: aspectRatio, child: fallback()),
            ),
          ),
        ),
      );
    }

    return Semantics(
      label: effectiveSemantics,
      image: true,
      child: AspectRatio(aspectRatio: aspectRatio, child: fallback()),
    );
  }
}

/// Embedded project showcase card for posts and profile showcases.
class VnlfProjectPreviewCard extends StatelessWidget {
  const VnlfProjectPreviewCard({
    super.key,
    required this.project,
    this.semanticLabel,
    this.starsSemanticLabel,
    this.forksSemanticLabel,
  });

  final ProjectShowcaseData project;
  final String? semanticLabel;
  final String? starsSemanticLabel;
  final String? forksSemanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);

    final card = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(VnlfDimensions.radiusMd),
        border: Border.all(color: colors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.folder_open_rounded, size: 16, color: colors.brand),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  project.name,
                  style: VnlfTypography.h3(colors.ink),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.brandSoft,
                  borderRadius: BorderRadius.circular(VnlfDimensions.radiusSm),
                ),
                child: Text(
                  project.tag,
                  style: VnlfTypography.caption(
                    colors.brand,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            project.description,
            style: VnlfTypography.body(colors.muted),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: colors.brand,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    project.primaryLanguage,
                    style: VnlfTypography.meta(colors.muted),
                  ),
                ],
              ),
              Semantics(
                label: starsSemanticLabel,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star_outline_rounded,
                      size: 14,
                      color: colors.muted,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${project.stars}',
                      style: VnlfTypography.meta(colors.muted),
                    ),
                  ],
                ),
              ),
              Semantics(
                label: forksSemanticLabel,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.call_split_rounded,
                      size: 14,
                      color: colors.muted,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${project.forks}',
                      style: VnlfTypography.meta(colors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (semanticLabel == null) {
      return card;
    }
    return Semantics(label: semanticLabel, container: true, child: card);
  }
}
