import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../data/live_activity_repository.dart';
import '../domain/activity_uncertainty.dart';
import '../domain/activity_service.dart';
import 'activity_screen.dart';

final _activityServiceProvider = Provider.autoDispose
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
      final english = Localizations.localeOf(context).languageCode == 'en';
      return Center(
        child: FilledButton(
          onPressed: () => context.push('/login'),
          child: Text(
            english ? 'Sign in to view activity' : 'Đăng nhập để xem hoạt động',
          ),
        ),
      );
    }
    return ActivityScreen(
      key: ValueKey(session.userId),
      service: ref.watch(_activityServiceProvider(session.userId)),
    );
  }
}
