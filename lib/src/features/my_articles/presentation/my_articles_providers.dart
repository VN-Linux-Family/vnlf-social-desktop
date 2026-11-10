import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../domain/models.dart';
import '../data/live_my_articles_repository.dart';
import '../domain/my_articles.dart';

final myArticlesRepositoryProvider = Provider<MyArticlesRepository>(
  (ref) => LiveMyArticlesRepository(ref.watch(apiClientProvider)),
);

final myDraftsProvider = FutureProvider.autoDispose<List<FeedPost>>((ref) {
  if (ref.watch(sessionStateProvider.select((session) => session?.userId)) ==
      null) {
    return const [];
  }
  return ref.watch(myArticlesRepositoryProvider).drafts();
});

/// Published and archived posts; drafts and removed ones are left out.
final myPostsProvider = FutureProvider.autoDispose<List<FeedPost>>((ref) async {
  if (ref.watch(sessionStateProvider.select((session) => session?.userId)) ==
      null) {
    return const [];
  }
  final items = await ref.watch(myArticlesRepositoryProvider).all();
  return [
    for (final item in items)
      if (item.status == 'PUBLISHED' || item.status == 'ARCHIVED') item,
  ];
});
