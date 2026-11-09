import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../i18n/vi.dart';
import '../domain/article_comment.dart';
import 'comments_providers.dart';

Future<bool> confirmCommentDeletion(
  BuildContext context, {
  bool emptied = false,
}) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(vi.commentsPanel.xoaBinhLuan2),
          content: Text(
            emptied
                ? vi.app.thread.binhLuanKhongCon
                : vi.app.thread.xoaBinhLuanNay,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(vi.common.huy),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(vi.commentsPanel.xoaBinhLuan2),
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
        title: Text(vi.commentsPanel.suaBinhLuan),
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
                    vi.app.thread.chuaLuuDuocThay,
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
            child: Text(vi.common.huy),
          ),
          FilledButton(
            onPressed: busy ? null : _save,
            child: Text(vi.common.luu),
          ),
        ],
      ),
    );
  }
}
