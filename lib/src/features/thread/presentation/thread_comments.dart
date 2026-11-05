import 'package:flutter/material.dart';

import '../../../design_system/design_system.dart';
import '../../shared/presentation/feature_samples.dart';
import '../../shared/presentation/feature_widgets.dart';

class ThreadComments extends StatefulWidget {
  const ThreadComments({super.key, required this.focusNode});

  final FocusNode focusNode;

  @override
  State<ThreadComments> createState() => _ThreadCommentsState();
}

class _ThreadCommentsState extends State<ThreadComments> {
  final _input = TextEditingController();
  final _comments = List<CommentNodeData>.of(
    offlineFeatures ? sampleComments : [],
  );

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _addComment() {
    final body = _input.text.trim();
    if (body.isEmpty) return;
    setState(() {
      _comments.add(
        CommentNodeData(
          id: 'local-${_comments.length}',
          author: localCommentAuthor,
          relativeTime: '',
          body: body,
        ),
      );
      _input.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final english = Localizations.localeOf(context).languageCode == 'en';
    final colors = VnlfColors.of(context);
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
              onPressed: _input.text.trim().isNotEmpty ? _addComment : null,
              child: Text(english ? 'Add comment' : 'Thêm bình luận'),
            ),
          ),
          for (final comment in _comments) ...[
            const SizedBox(height: 16),
            VnlfCommentTree(comment: comment),
          ],
        ],
      ),
    );
  }
}
