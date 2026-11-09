import 'package:flutter/material.dart';

import '../../../design_system/design_system.dart';

class VoiceParticipant extends StatelessWidget {
  const VoiceParticipant({
    super.key,
    required this.author,
    this.speaking = false,
    this.muted = false,
  });

  final AuthorData author;
  final bool speaking;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final english = Localizations.localeOf(context).languageCode == 'en';
    return Semantics(
      label:
          '${author.displayName}, ${speaking
              ? (english ? 'speaking' : 'đang nói')
              : muted
              ? (english ? 'muted' : 'đã tắt mic')
              : (english ? 'listening' : 'đang nghe')}',
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(VnlfDimensions.radiusLg),
          border: Border.all(
            color: speaking ? colors.brand : colors.line,
            width: speaking ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: speaking
                      ? colors.brand.withValues(alpha: 0.4)
                      : colors.line,
                  width: 3,
                ),
                boxShadow: speaking
                    ? [
                        BoxShadow(
                          color: colors.brand.withValues(alpha: 0.16),
                          blurRadius: 16,
                          spreadRadius: 3,
                        ),
                      ]
                    : null,
              ),
              child: VnlfAvatar(author: author, size: 42),
            ),
            const SizedBox(height: 8),
            VnlfAuthorNameRow(author: author),
            const SizedBox(height: 4),
            Icon(
              muted
                  ? Icons.mic_off_outlined
                  : speaking
                  ? Icons.graphic_eq
                  : Icons.headphones,
              size: 18,
              color: speaking ? colors.brand : colors.muted,
            ),
          ],
        ),
      ),
    );
  }
}
