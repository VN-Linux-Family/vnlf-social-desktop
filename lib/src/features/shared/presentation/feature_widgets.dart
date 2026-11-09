import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/design_system.dart';
import '../../../i18n/vi.dart';

class FeatureHeader extends StatelessWidget {
  const FeatureHeader({
    super.key,
    required this.title,
    this.showSettings = false,
  });

  final String title;
  final bool showSettings;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          IconButton(
            tooltip: vi.app.common.quayLai,
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.canPop() ? context.pop() : context.go('/'),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(title, style: VnlfTypography.pageTitle(colors.ink)),
          ),
          if (showSettings)
            IconButton(
              tooltip: vi.common.caiDat,
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => context.push('/settings'),
            ),
        ],
      ),
    );
  }
}

class FeatureSurface extends StatelessWidget {
  const FeatureSurface({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(VnlfDimensions.radiusLg),
        side: BorderSide(color: colors.line),
      ),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}

class FeatureLoadError extends StatelessWidget {
  const FeatureLoadError({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return VnlfStateCard(
      icon: Icons.error_outline,
      title: vi.app.shared.khongTaiDuocNoi,
      message: vi.app.common.vuiLongThuLai,
      actionLabel: vi.common.thuLai,
      onAction: onRetry,
    );
  }
}
