import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../domain/models.dart';
import '../../shared/presentation/feature_samples.dart';

final threadPostProvider = FutureProvider.autoDispose.family<FeedPost?, String>(
  (ref, id) async {
    ref.watch(sessionStateProvider.select((session) => session?.userId));
    return await ref.watch(postRepositoryProvider).getPost(id) ??
        (offlineFeatures ? samplePost : null);
  },
);
