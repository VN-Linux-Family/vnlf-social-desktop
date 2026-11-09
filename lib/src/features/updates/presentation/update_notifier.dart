import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../i18n/vi.dart';
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              format(vi.app.updates.daCoVnlfSocial, {
                'version': update.version,
              }),
            ),
            duration: const Duration(seconds: 10),
            action: SnackBarAction(
              label: vi.app.updates.xem,
              onPressed: () => openUpdate(context, update),
            ),
          ),
        );
      });
    });
    return widget.child;
  }
}
