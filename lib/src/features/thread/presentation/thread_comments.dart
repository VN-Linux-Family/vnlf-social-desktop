import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../design_system/design_system.dart';
import '../../shared/presentation/feature_samples.dart';
import '../../shared/presentation/feature_widgets.dart';

final articleCommentsProvider = FutureProvider.autoDispose
    .family<List<CommentNodeData>, String>((ref, articleId) async {
      if (articleId.isEmpty) {
        return offlineFeatures ? sampleComments : <CommentNodeData>[];
      }
      final client = ref.watch(apiClientProvider);
      try {
        final response = await client.get<Map<String, dynamic>>(
          '/api/v1/articles/$articleId/comments',
          decode: (json) => json,
        );
        final rawItems = response['items'] as List<dynamic>? ?? [];
        final comments = <CommentNodeData>[];
        for (final raw in rawItems) {
          if (raw is! Map<String, dynamic>) continue;
          final authorMap = raw['author'] is Map<String, dynamic>
              ? raw['author'] as Map<String, dynamic>
              : null;
          final author = AuthorData(
            id: authorMap?['id'] as String? ?? raw['authorId'] as String? ?? '',
            username: authorMap?['username'] as String? ?? '',
            displayName:
                authorMap?['displayName'] as String? ??
                authorMap?['username'] as String? ??
                '',
            avatarUrl: authorMap?['avatarUrl'] as String? ?? '',
            style: AuthorStyleData(
              distroBadge:
                  DistroBadgeType.values
                      .where(
                        (b) =>
                            b.name ==
                            (authorMap?['style']?['distroBadge'] as String?)
                                ?.toLowerCase(),
                      )
                      .firstOrNull ??
                  DistroBadgeType.none,
            ),
          );
          final content =
              raw['content'] as String? ?? raw['contentText'] as String? ?? '';
          final createdAt = raw['createdAt'] as String?;
          String timeStr = '';
          if (createdAt != null) {
            final dt = DateTime.tryParse(createdAt);
            if (dt != null) {
              final age = DateTime.now().difference(dt);
              if (age.inHours < 1) {
                timeStr = '${age.inMinutes}m';
              } else if (age.inDays < 1) {
                timeStr = '${age.inHours}h';
              } else {
                timeStr = '${age.inDays}d';
              }
            }
          }
          comments.add(
            CommentNodeData(
              id: raw['id'] as String? ?? '',
              author: author,
              relativeTime: timeStr,
              body: content,
            ),
          );
        }
        return comments;
      } catch (_) {
        return offlineFeatures ? sampleComments : <CommentNodeData>[];
      }
    });

class ThreadComments extends ConsumerStatefulWidget {
  const ThreadComments({super.key, required this.focusNode, this.postId = ''});

  final FocusNode focusNode;
  final String postId;

  @override
  ConsumerState<ThreadComments> createState() => _ThreadCommentsState();
}

class _ThreadCommentsState extends ConsumerState<ThreadComments> {
  final _input = TextEditingController();
  final _localComments = <CommentNodeData>[];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _addComment() async {
    final body = _input.text.trim();
    if (body.isEmpty || _isSubmitting) return;

    final newComment = CommentNodeData(
      id: 'local-${DateTime.now().millisecondsSinceEpoch}',
      author: localCommentAuthor,
      relativeTime: 'Vừa xong',
      body: body,
    );

    setState(() {
      _localComments.add(newComment);
      _input.clear();
      _isSubmitting = true;
    });

    if (widget.postId.isNotEmpty) {
      try {
        final client = ref.read(apiClientProvider);
        await client.request<Map<String, dynamic>>(
          'POST',
          '/api/v1/articles/${widget.postId}/comments',
          body: jsonEncode({'content': body, 'parentId': null}),
          decode: (json) => json,
        );
        ref.invalidate(articleCommentsProvider(widget.postId));
      } catch (_) {
        // Optimistic comment remains locally displayed
      }
    }

    if (mounted) {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final english = Localizations.localeOf(context).languageCode == 'en';
    final colors = VnlfColors.of(context);
    final remoteCommentsAsync = widget.postId.isNotEmpty
        ? ref.watch(articleCommentsProvider(widget.postId))
        : null;

    final displayComments = [
      if (remoteCommentsAsync != null)
        ...(remoteCommentsAsync.valueOrNull ??
            (offlineFeatures ? sampleComments : <CommentNodeData>[]))
      else if (offlineFeatures)
        ...sampleComments,
      ..._localComments,
    ];

    return FeatureSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            english ? 'Comments' : 'Bình luận',
            style: VnlfTypography.h2(colors.ink),
          ),
          const SizedBox(height: 8),
          Text(
            english
                ? 'Community discussion · Comments are active.'
                : 'Thảo luận cộng đồng · Bình luận đang hoạt động.',
            style: VnlfTypography.meta(colors.muted),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('comment-input'),
            controller: _input,
            focusNode: widget.focusNode,
            minLines: 2,
            maxLines: 5,
            decoration: InputDecoration(
              labelText: english ? 'Write a comment' : 'Viết bình luận',
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: _input.text.trim().isNotEmpty && !_isSubmitting
                  ? _addComment
                  : null,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(english ? 'Add comment' : 'Thêm bình luận'),
            ),
          ),
          if (remoteCommentsAsync != null && remoteCommentsAsync.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            ),
          for (final comment in displayComments) ...[
            const SizedBox(height: 16),
            VnlfCommentTree(comment: comment),
          ],
        ],
      ),
    );
  }
}
