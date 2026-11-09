import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/design_system.dart';
import '../../../domain/models.dart';
import '../../../i18n/vi.dart';
import '../../feed/presentation/post_mapper.dart';
import '../../shared/presentation/feature_widgets.dart';
import '../../shared/presentation/post_interactions.dart';
import 'article_detail_view.dart';
import 'post_detail_view.dart';
import 'thread_comments.dart';
import 'thread_post_provider.dart';

export 'thread_post_provider.dart' show threadPostProvider;

/// The website's `/a/:slug` page: a regular post or a long-form article,
/// then its comments.
class ThreadScreen extends ConsumerWidget {
  const ThreadScreen({super.key, required this.postId});

  final String postId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final post = ref.watch(threadPostProvider(postId));
    return _PageOverlay(
      child: ListView(
        padding: const EdgeInsets.only(bottom: 20),
        children: [
          post.when(
            loading: () =>
                const VnlfLoadingShimmer(child: VnlfPostCard.loading()),
            error: (error, stack) => FeatureLoadError(
              onRetry: () => ref.invalidate(threadPostProvider(postId)),
            ),
            data: (value) => value == null
                ? VnlfStateCard(
                    icon: Icons.article_outlined,
                    title: vi.app.thread.khongTimThayBai,
                    message: vi.app.thread.khongTimThayNoi,
                  )
                : ThreadContent(
                    key: ValueKey('$postId/${value.id}'),
                    post: value,
                  ),
          ),
        ],
      ),
    );
  }
}

/// An overlay covering only this page, so the phone comment composer can
/// float at its bottom without covering the drawer or the bottom bar.
class _PageOverlay extends StatefulWidget {
  const _PageOverlay({required this.child});
  final Widget child;

  @override
  State<_PageOverlay> createState() => _PageOverlayState();
}

class _PageOverlayState extends State<_PageOverlay> {
  late final _entry = OverlayEntry(builder: (_) => widget.child);

  @override
  void didUpdateWidget(_PageOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    _entry.markNeedsBuild();
  }

  @override
  void dispose() {
    _entry.remove();
    _entry.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Overlay(initialEntries: [_entry]);
}

class ThreadContent extends ConsumerStatefulWidget {
  const ThreadContent({super.key, required this.post});

  final FeedPost post;

  @override
  ConsumerState<ThreadContent> createState() => _ThreadContentState();
}

class _ThreadContentState extends ConsumerState<ThreadContent> {
  final _commentFocus = FocusNode();

  @override
  void dispose() {
    _commentFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final source = widget.post;
    final detail = ref
        .watch(postInteractionProvider(source.id))
        .apply(presentPost(source, fullContent: true));
    final comments = ThreadComments(
      postId: source.id,
      focusNode: _commentFocus,
    );
    return source.format == 'ARTICLE'
        ? ArticleDetailView(
            post: source,
            detail: detail,
            onComment: _commentFocus.requestFocus,
            comments: comments,
          )
        : PostDetailView(
            post: source,
            detail: detail,
            onComment: _commentFocus.requestFocus,
            comments: comments,
          );
  }
}
