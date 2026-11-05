import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/design_system.dart';

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
    final english = Localizations.localeOf(context).languageCode == 'en';
    final colors = VnlfColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          IconButton(
            tooltip: english ? 'Back' : 'Quay lại',
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.canPop() ? context.pop() : context.go('/'),
          ),
          const SizedBox(width: 4),
          Expanded(child: Text(title, style: VnlfTypography.h2(colors.ink))),
          if (showSettings)
            IconButton(
              tooltip: english ? 'Settings' : 'Cài đặt',
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
    final english = Localizations.localeOf(context).languageCode == 'en';
    return VnlfStateCard(
      icon: Icons.error_outline,
      title: english ? 'Unable to load content' : 'Không tải được nội dung',
      message: english ? 'Please try again.' : 'Vui lòng thử lại.',
      actionLabel: english ? 'Retry' : 'Thử lại',
      onAction: onRetry,
    );
  }
}
