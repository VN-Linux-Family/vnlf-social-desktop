import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../i18n/vi.dart';
import '../data/live_activity_repository.dart';
import '../domain/activity_uncertainty.dart';
import '../domain/activity_service.dart';
import 'activity_screen.dart';

final activityServiceProvider = Provider.autoDispose
    .family<ActivityService, String>((ref, ownerId) {
      return ActivityService(
        LiveActivityRepository(
          ref.watch(apiClientProvider),
          ownerId: ownerId,
          currentOwnerId: () => ref.read(sessionStateProvider)?.userId,
        ),
        uncertainty: ActivityUncertainty(
          ref.watch(sessionStorageProvider),
          ownerId,
        ),
      );
    });

class ActivityPage extends ConsumerWidget {
  const ActivityPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionStateProvider);
    if (session == null || session.userId.isEmpty) {
      return Center(
        child: FilledButton(
          onPressed: () => context.push('/login'),
          child: Text(vi.app.activity.dangNhapDeXem),
        ),
      );
    }
    return ActivityScreen(
      key: ValueKey(session.userId),
      service: ref.watch(activityServiceProvider(session.userId)),
    );
  }
}
