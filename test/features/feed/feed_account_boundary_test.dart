import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/app/providers.dart';
import 'package:vnlfsocialapp/src/domain/models.dart';
import 'package:vnlfsocialapp/src/domain/repositories.dart';
import 'package:vnlfsocialapp/src/features/feed/presentation/feed_notifier.dart';

void main() {
  test('every feed tab reloads account-specific viewer state when the owner changes', () async {
    for (final tab in FeedTab.values) {
      final (container, repo) = _container();
      final provider = feedNotifierProvider(tab);
      final sub = container.listen(provider, (_, _) {});
      await container.read(provider.future);
      container.read(sessionStateProvider.notifier).state = const Session(
        userId: 'b',
        displayName: 'Hai',
      );
      final result = await container.read(provider.future);
      expect(result.posts.single.id, 'post-b', reason: tab.name);
      expect(result.posts.single.viewerVote, -1, reason: tab.name);
      expect(repo.owners, ['a', 'b'], reason: tab.name);
      container.read(sessionStateProvider.notifier).state = null;
      if (tab == FeedTab.following) {
        await expectLater(
          container.read(provider.future),
          throwsA(isA<HttpFailure>()),
        );
      } else {
        final guest = await container.read(provider.future);
        expect(guest.posts.single.id, 'post-guest', reason: tab.name);
        expect(guest.posts.single.viewerVote, 0, reason: tab.name);
      }

      sub.close();
      container.dispose();
    }
  });
  test(
    'a refresh started by the old account cannot replace the new account feed',
    () async {
      final (container, repo) = _container();
      addTearDown(container.dispose);
      final provider = feedNotifierProvider(FeedTab.latest);
      final sub = container.listen(provider, (_, _) {});
      addTearDown(sub.close);
      await container.read(provider.future);
      repo.pendingRefresh = Completer<FeedPage>();
      final refresh = container.read(provider.notifier).refresh();
      container.read(sessionStateProvider.notifier).state = const Session(
        userId: 'b',
        displayName: 'Hai',
      );
      await Future<void>.delayed(Duration.zero);
      repo.pendingRefresh!.complete(_page('a'));
      await refresh;
      final result = await container.read(provider.future);
      expect(result.posts.single.id, 'post-b');
    },
  );
}

(ProviderContainer, _Feeds) _container() {
  late final ProviderContainer container;
  final repo = _Feeds(
    () => container.read(sessionStateProvider)?.userId ?? 'guest',
  );
  container = ProviderContainer(
    overrides: [
      feedRepositoryProvider.overrideWithValue(repo),
      sessionStateProvider.overrideWith(
        (ref) => const Session(userId: 'a', displayName: 'Một'),
      ),
    ],
  );
  return (container, repo);
}

class _Feeds implements FeedRepository {
  _Feeds(this.owner);
  final String Function() owner;
  final owners = <String>[];
  Completer<FeedPage>? pendingRefresh;
  @override
  Future<FeedPage> getFeed({
    String? cursor,
    String? type,
    bool refresh = false,
  }) async {
    final active = owner();
    owners.add(active);
    if (refresh && pendingRefresh != null) return pendingRefresh!.future;
    return _page(active);
  }
}

FeedPage _page(String owner) => FeedPage(
  items: [
    FeedPost(
      id: 'post-$owner',
      author: const Author(
        id: 'author',
        username: 'nguoi',
        displayName: 'Người',
      ),
      excerpt: '',
      voteScore: 0,
      commentCount: 0,
      viewerVote: owner == 'a'
          ? 1
          : owner == 'b'
          ? -1
          : 0,
    ),
  ],
);
