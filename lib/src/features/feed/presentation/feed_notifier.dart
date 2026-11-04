import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../domain/models.dart';

final feedNotifierProvider = AsyncNotifierProvider.autoDispose
    .family<FeedNotifier, FeedState, FeedTab>(FeedNotifier.new);

enum FeedTab {
  latest('latest'),
  featured('trending'),
  article('article');

  const FeedTab(this.apiType);
  final String apiType;
}

class FeedState {
  FeedState({
    required List<FeedPost> posts,
    this.nextCursor,
    this.isLoadingMore = false,
    this.paginationError,
  }) : posts = List.unmodifiable(posts);

  final List<FeedPost> posts;
  final String? nextCursor;
  final bool isLoadingMore;
  final Object? paginationError;
}

class FeedNotifier extends AutoDisposeFamilyAsyncNotifier<FeedState, FeedTab> {
  int _generation = 0;
  bool _active = true;

  @override
  Future<FeedState> build(FeedTab arg) async {
    _active = true;
    ref.onDispose(() => _active = false);
    final page = await ref
        .watch(feedRepositoryProvider)
        .getFeed(type: arg.apiType);
    return FeedState(posts: page.items, nextCursor: page.nextCursor);
  }

  Future<void> refresh() async {
    final generation = ++_generation;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      final page = await ref
          .read(feedRepositoryProvider)
          .getFeed(type: arg.apiType, refresh: true);
      return FeedState(posts: page.items, nextCursor: page.nextCursor);
    });
    if (_active && generation == _generation) state = result;
  }

  Future<void> loadMore() async {
    final current = state.asData?.value;
    if (current == null ||
        current.isLoadingMore ||
        current.nextCursor == null) {
      return;
    }
    final generation = _generation;
    state = AsyncData(
      FeedState(
        posts: current.posts,
        nextCursor: current.nextCursor,
        isLoadingMore: true,
      ),
    );
    try {
      final page = await ref
          .read(feedRepositoryProvider)
          .getFeed(type: arg.apiType, cursor: current.nextCursor);
      if (!_active || generation != _generation) return;
      final ids = current.posts.map((post) => post.id).toSet();
      state = AsyncData(
        FeedState(
          posts: [
            ...current.posts,
            ...page.items.where((post) => ids.add(post.id)),
          ],
          nextCursor: page.nextCursor == current.nextCursor
              ? null
              : page.nextCursor,
        ),
      );
    } catch (error) {
      if (!_active || generation != _generation) return;
      state = AsyncData(
        FeedState(
          posts: current.posts,
          nextCursor: current.nextCursor,
          paginationError: error,
        ),
      );
    }
  }
}
