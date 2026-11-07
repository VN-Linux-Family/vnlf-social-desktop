import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../shared/presentation/feature_samples.dart';
import '../data/fixture_search_repository.dart';
import '../data/live_search_repository.dart';
import '../domain/search_results.dart';
import 'search_index.dart';

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  if (offlineFeatures) {
    return FixtureSearchRepository(() => ref.read(searchIndexProvider.future));
  }
  return LiveSearchRepository(ref.watch(apiClientProvider));
});

final searchResultsProvider = FutureProvider.autoDispose
    .family<SearchResults, String>(
      (ref, query) => ref.watch(searchRepositoryProvider).search(query),
    );

final popularTopicsProvider = FutureProvider<List<SearchTopic>>(
  (ref) => ref.watch(searchRepositoryProvider).popularTopics(),
);
