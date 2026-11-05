import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../domain/article_comment.dart';
import 'comments_providers.dart';

Future<bool> confirmCommentDeletion(
  BuildContext context, {
  bool emptied = false,
}) async {
  final en = Localizations.localeOf(context).languageCode == 'en';
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(en ? 'Delete comment' : 'Xóa bình luận'),
          content: Text(
            emptied
                ? (en
                      ? 'This comment has no text or media left. Delete it?'
                      : 'Bình luận không còn nội dung hay ảnh. Xóa bình luận này?')
                : (en
                      ? 'Delete this comment? Its replies will remain.'
                      : 'Xóa bình luận này? Các câu trả lời vẫn được giữ.'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(en ? 'Cancel' : 'Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(en ? 'Delete comment' : 'Xóa bình luận'),
            ),
          ],
        ),
      ) ??
      false;
}

class CommentEditDialog extends ConsumerStatefulWidget {
  const CommentEditDialog({
    super.key,
    required this.articleId,
    required this.comment,
  });
  final String articleId;
  final ArticleComment comment;
  @override
  ConsumerState<CommentEditDialog> createState() => _CommentEditDialogState();
}

class _CommentEditDialogState extends ConsumerState<CommentEditDialog> {
  late final _text = TextEditingController(text: widget.comment.content);
  bool _confirming = false;
  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final account = ref.read(sessionStateProvider)?.userId;
    final actions = ref.read(commentActionsProvider(widget.articleId).notifier);
    final content = _text.text.trim();
    final emptied =
        content.isEmpty &&
        widget.comment.attachments.isEmpty &&
        widget.comment.gif == null;
    if (emptied) {
      setState(() => _confirming = true);
      final confirmed = await confirmCommentDeletion(context, emptied: true);
      if (!mounted) return;
      setState(() => _confirming = false);
      if (!confirmed || ref.read(sessionStateProvider)?.userId != account) {
        return;
      }
    }
    final saved = emptied
        ? await actions.delete(widget.comment)
        : await actions.edit(widget.comment, content);
    if (mounted && ref.read(sessionStateProvider)?.userId == account && saved) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final en = Localizations.localeOf(context).languageCode == 'en';
    ref.listen(sessionStateProvider, (before, after) {
      if (before?.userId != after?.userId && mounted) {
        Navigator.pop(context, false);
      }
    });
    final state = ref.watch(commentActionsProvider(widget.articleId));
    final busy = _confirming || state.pending.contains(widget.comment.id);
    return PopScope(
      canPop: !busy,
      child: AlertDialog(
        title: Text(en ? 'Edit comment' : 'Sửa bình luận'),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                key: const ValueKey('comment-edit-input'),
                controller: _text,
                enabled: !busy,
                autofocus: true,
                minLines: 3,
                maxLines: 8,
                maxLength: 4000,
              ),
              if (state.errors.containsKey(widget.comment.id))
                Semantics(
                  liveRegion: true,
                  child: Text(
                    en ? 'Could not save. Your draft is kept; try again.' : 'Chưa lưu được thay đổi. Bản nháp vẫn được giữ; vui lòng thử lại.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: busy ? null : () => Navigator.pop(context, false),
            child: Text(en ? 'Cancel' : 'Hủy'),
          ),
          FilledButton(
            onPressed: busy ? null : _save,
            child: Text(en ? 'Save' : 'Lưu'),
          ),
        ],
      ),
    );
  }
}
