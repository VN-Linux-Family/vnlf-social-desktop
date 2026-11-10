import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../data/live_tag_articles_repository.dart';
import '../domain/tag_articles.dart';

final tagArticlesRepositoryProvider = Provider<TagArticlesRepository>(
  (ref) => LiveTagArticlesRepository(ref.watch(apiClientProvider)),
);

/// One page of a topic, read again per account like the website, which
/// personalises the posts for a signed-in member.
final tagArticlesProvider = FutureProvider.autoDispose
    .family<TagArticlesPage?, ({String slug, String? cursor})>((ref, query) {
      ref.watch(sessionStateProvider.select((session) => session?.userId));
      return ref
          .watch(tagArticlesRepositoryProvider)
          .page(query.slug, cursor: query.cursor);
    });
