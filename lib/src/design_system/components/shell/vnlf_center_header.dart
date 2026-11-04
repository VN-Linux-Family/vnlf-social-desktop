import 'package:flutter/material.dart';

import '../../tokens/vnlf_colors.dart';
import '../../tokens/vnlf_dimensions.dart';
import '../../tokens/vnlf_typography.dart';

/// Sticky / top header for the center content column across feed, thread, and profile.
class VnlfCenterPageHeader extends StatelessWidget {
  const VnlfCenterPageHeader({
    super.key,
    required this.title,
    this.leading,
    this.trailing,
    this.onProfileTap,
  });

  final String title;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onProfileTap;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(VnlfDimensions.radiusLg),
        border: Border.all(color: colors.line),
      ),
      child: Row(
        children: [
          if (leading case final leadingWidget?) ...[
            leadingWidget,
            const SizedBox(width: 10),
          ],
          Expanded(child: Text(title, style: VnlfTypography.h2(colors.ink))),
          ?trailing,
        ],
      ),
    );
  }
}
