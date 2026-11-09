import '../../polls/presentation/poll_state.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../domain/models.dart';
import '../../shared/presentation/feature_samples.dart';

/// Keyed by the route value: an article UUID or a public `/a/` slug.
final threadPostProvider = FutureProvider.autoDispose.family<FeedPost?, String>(
  (ref, idOrSlug) async {
    ref.watch(sessionStateProvider.select((session) => session?.userId));
    final pollRead = ref.read(pollStoreProvider.notifier).beginRead();
    final FeedPost? post;
    try {
      post =
          await ref.watch(postRepositoryProvider).getPost(idOrSlug) ??
          (offlineFeatures ? samplePost : null);
    } on HttpFailure catch (failure) {
      // Unknown, unpublished or removed articles are absent; retrying cannot help.
      if (failure.statusCode == 404) return null;
      rethrow;
    }
    pollRead.accept(post?.poll);
    return post;
  },
);
