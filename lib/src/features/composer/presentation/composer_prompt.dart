import 'package:flutter/material.dart';

import '../../../design_system/tokens/vnlf_colors.dart';
import '../../../design_system/tokens/vnlf_dimensions.dart';
import '../../../design_system/tokens/vnlf_typography.dart';

class ComposerPrompt extends StatelessWidget {
  const ComposerPrompt({super.key, required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final isEn = Localizations.localeOf(context).languageCode == 'en';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(VnlfDimensions.radiusLg),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(VnlfDimensions.radiusLg),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(VnlfDimensions.radiusLg),
              border: Border.all(color: colors.line),
            ),
            child: Row(
              children: [
                Icon(Icons.edit_note_rounded, color: colors.brand, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surfaceSoft,
                      borderRadius: BorderRadius.circular(
                        VnlfDimensions.radiusFull,
                      ),
                      border: Border.all(color: colors.line),
                    ),
                    child: Text(
                      isEn ? 'What’s on your mind?' : 'Bạn đang nghĩ gì?',
                      style: VnlfTypography.caption(colors.muted),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  Icons.add_photo_alternate_outlined,
                  color: colors.muted,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
