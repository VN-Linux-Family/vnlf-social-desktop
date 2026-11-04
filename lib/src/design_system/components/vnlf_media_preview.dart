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
    this.aspectRatio = 16 / 9,
    this.label = 'Hình ảnh đính kèm',
    this.icon = Icons.image_outlined,
  });

  final double aspectRatio;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);

    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Container(
        decoration: BoxDecoration(
          color: colors.surfaceSoft,
          borderRadius: BorderRadius.circular(VnlfDimensions.radiusMd),
          border: Border.all(color: colors.line),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 36, color: colors.muted),
              const SizedBox(height: 8),
              Text(label, style: VnlfTypography.caption(colors.muted)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Embedded project showcase card for posts and profile showcases.
class VnlfProjectPreviewCard extends StatelessWidget {
  const VnlfProjectPreviewCard({super.key, required this.project});

  final ProjectShowcaseData project;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);

    return Container(
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
              Row(
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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.call_split_rounded, size: 14, color: colors.muted),
                  const SizedBox(width: 3),
                  Text(
                    '${project.forks}',
                    style: VnlfTypography.meta(colors.muted),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
