import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/presentation/feature_samples.dart';
import '../domain/app_update.dart';
import 'update_panel.dart';
import 'update_providers.dart';

/// One bounded release check at launch; navigation never starts a polling loop.
class AppUpdateNotifier extends ConsumerStatefulWidget {
  const AppUpdateNotifier({super.key, required this.child});
  final Widget child;
  @override
  ConsumerState<AppUpdateNotifier> createState() => _AppUpdateNotifierState();
}

class _AppUpdateNotifierState extends ConsumerState<AppUpdateNotifier> {
  @override
  void initState() {
    super.initState();
    if (!offlineFeatures) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(
            ref.read(updateControllerProvider.notifier).check(automatic: true),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(updateControllerProvider, (before, after) {
      final update = after.asData?.value;
      if (update is! UpdateAvailable) return;
      final english = Localizations.localeOf(context).languageCode == 'en';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              english
                  ? 'VNLF Social ${update.version} is available.'
                  : 'Đã có VNLF Social ${update.version}.',
            ),
            duration: const Duration(seconds: 10),
            action: SnackBarAction(
              label: english ? 'View' : 'Xem',
              onPressed: () => openUpdate(context, update),
            ),
          ),
        );
      });
    });
    return widget.child;
  }
}
