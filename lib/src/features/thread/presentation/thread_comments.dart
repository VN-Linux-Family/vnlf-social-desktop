import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/models.dart';
import '../../feed/presentation/feed_notifier.dart';
import '../../shared/presentation/feature_samples.dart';
import '../../shared/presentation/feature_widgets.dart';
import '../domain/article_comment.dart';
import '../data/comment_attachment_controller.dart';
import 'comment_attachment_picker.dart';
import 'comments_providers.dart';
import 'comment_edit_dialog.dart';
import 'thread_post_provider.dart';

export 'comments_providers.dart' show articleCommentsProvider;

class ThreadComments extends ConsumerStatefulWidget {
  const ThreadComments({super.key, required this.focusNode, this.postId = ''});
  final FocusNode focusNode;
  final String postId;
  @override
  ConsumerState<ThreadComments> createState() => _ThreadCommentsState();
}

class _ThreadCommentsState extends ConsumerState<ThreadComments> {
  final _input = TextEditingController();
  final _confirmed = <String, ArticleComment>{};
  bool _submitting = false;
  AppFailure? _failure;
  ArticleComment? _replyTo;
  int _revision = 0;
  bool _selecting = false;
  String? _attachmentError;

  @override
  void didUpdateWidget(covariant ThreadComments oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.postId != widget.postId) {
      _revision++;
      _confirmed.clear();
      _replyTo = null;
      _failure = null;
      _submitting = false;
      _selecting = false;
      _attachmentError = null;
      _input.clear();
    }
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final content = _input.text.trim();
    final draft = ref.read(commentAttachmentControllerProvider(widget.postId));
    if ((content.isEmpty && draft.readyIds.isEmpty) || content.length > 4000 || _submitting) return;
    final sessionId = ref.read(sessionStateProvider)?.userId;
    if (!offlineFeatures && sessionId == null) {
      context.push('/login');
      return;
    }
    final revision = _revision;
    final visible = ref
        .read(commentActionsProvider(widget.postId))
        .apply(
          {
            for (final c
                in ref
                        .read(articleCommentsProvider(widget.postId))
                        .valueOrNull ??
                    <ArticleComment>[])
              c.id: c,
            ..._confirmed,
          }.values,
        );
    final parentId = draft.pending != null
        ? draft.pending!.parentId
        : (_replyTo == null ? null : commentReplyParent(_replyTo!, visible));
    setState(() {
      _submitting = true;
      _failure = null;
    });
    try {
      final comment = await draft.submit(content, parentId: parentId);
      if (!mounted || revision != _revision) return;
      if (!offlineFeatures &&
          ref.read(sessionStateProvider)?.userId != sessionId) {
        return;
      }
      setState(() {
        _confirmed[comment.id] = comment;
        if (_input.text.trim() == content) _input.clear();
        _replyTo = null;
      });
      ref.invalidate(articleCommentsProvider(widget.postId));
      ref.invalidate(feedNotifierProvider);
    } on AppFailure catch (error) {
      if (mounted && revision == _revision) setState(() => _failure = error);
    } catch (_) {
      if (mounted && revision == _revision) {
        setState(() => _failure = const TransportFailure());
      }
    } finally {
      if (mounted && revision == _revision) setState(() => _submitting = false);
    }
  }

  Future<void> _pickAttachments() async {
    if (_selecting || !_authorized()) return;
    final revision = _revision;
    final owner = ref.read(sessionStateProvider)?.userId;
    final draft = ref.read(commentAttachmentControllerProvider(widget.postId));
    bool current() => mounted && revision == _revision && ref.read(sessionStateProvider)?.userId == owner && identical(draft, ref.read(commentAttachmentControllerProvider(widget.postId)));
    void refresh() { if (current()) setState(() {}); }
    setState(() { _selecting = true; _attachmentError = null; });
    try {
      final files = await ref.read(commentAttachmentPickerProvider)();
      if (!current()) return;
      if (files.length + draft.attachments.length > 10) {
        setState(() => _attachmentError = 'limit');
        return;
      }
      for (final file in files) {
        if (!current()) return;
        final item = draft.add(file);
        refresh();
        try { await draft.upload(item, onChange: refresh); } catch (_) { refresh(); }
      }
    } catch (_) {
      if (current()) setState(() => _attachmentError = 'picker');
    } finally {
      if (current()) setState(() => _selecting = false);
    }
  }

  Future<void> _retryAttachment(CommentAttachment item) async {
    final revision = _revision;
    final draft = ref.read(commentAttachmentControllerProvider(widget.postId));
    void refresh() { if (mounted && revision == _revision) setState(() {}); }
    try { await draft.retryCompletion(item, onChange: refresh); } catch (_) { refresh(); }
  }

  bool _authorized() {
    if (offlineFeatures || ref.read(sessionStateProvider) != null) return true;
    context.push('/login');
    return false;
  }

  Future<void> _action(Future<bool> Function() write) async {
    if (!_authorized()) return;
    final revision = _revision;
    if (await write() && mounted && revision == _revision) {
      ref.invalidate(articleCommentsProvider(widget.postId));
      ref.invalidate(feedNotifierProvider);
      ref.invalidate(threadPostProvider(widget.postId));
    }
  }

  Future<void> _edit(ArticleComment comment) async {
    if (!_authorized()) return;
    final revision = _revision;
    final changed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          CommentEditDialog(articleId: widget.postId, comment: comment),
    );
    if (changed == true && mounted && revision == _revision) {
      _confirmed.remove(comment.id);
      ref.invalidate(articleCommentsProvider(widget.postId));
      ref.invalidate(feedNotifierProvider);
      ref.invalidate(threadPostProvider(widget.postId));
    }
  }

  Future<void> _delete(ArticleComment comment) async {
    if (!_authorized()) return;
    final revision = _revision;
    if (await confirmCommentDeletion(context) &&
        mounted &&
        revision == _revision) {
      await _action(
        () => ref
            .read(commentActionsProvider(widget.postId).notifier)
            .delete(comment),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final english = Localizations.localeOf(context).languageCode == 'en';
    final colors = VnlfColors.of(context);
    ref.listen(sessionStateProvider, (before, after) {
      if (before?.userId == after?.userId) return;
      _revision++;
      setState(() {
        _confirmed.clear();
        _replyTo = null;
        _failure = null;
        _submitting = false;
        _input.clear();
        _selecting = false;
        _attachmentError = null;
      });
    });
    ref.listen(articleCommentsProvider(widget.postId), (before, after) {
      if (after.hasValue && !after.isLoading && !after.hasError) {
        final confirmedIds = {for (final c in after.requireValue) c.id};
        _confirmed.removeWhere((id, _) => confirmedIds.contains(id));
      }
    });
    final remote = ref.watch(articleCommentsProvider(widget.postId));
    final actions = ref.watch(commentActionsProvider(widget.postId));
    final items = {
      for (final item in actions.apply(
        {
          for (final item in remote.valueOrNull ?? <ArticleComment>[])
            item.id: item,
          ..._confirmed,
        }.values,
      ))
        item.id: item,
    };
    final comments = presentComments(
      items.values.toList(),
      english: english,
      pending: actions.pending,
      errors: actions.errors,
    );
    final draft = ref.watch(commentAttachmentControllerProvider(widget.postId));
    final recovery = ref.watch(commentAttachmentRecoveryProvider(widget.postId));
    if (recovery.hasValue && draft.pending != null && _input.text != draft.pending!.content) {
      _input.text = draft.pending!.content;
    }
    ref.listen(commentAttachmentRecoveryProvider(widget.postId), (before, after) {
      if (after.hasValue) {
        final pending = ref.read(commentAttachmentControllerProvider(widget.postId)).pending;
        if (pending != null) setState(() => _input.text = pending.content);
      }
    });
    final signedIn = offlineFeatures || ref.watch(sessionStateProvider) != null;
    return FeatureSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            english ? 'Comments' : 'Bình luận',
            style: VnlfTypography.h2(colors.ink),
          ),
          const SizedBox(height: 12),
          if (!signedIn)
            TextButton(
              onPressed: () => context.push('/login'),
              child: Text(
                english ? 'Sign in to comment' : 'Đăng nhập để bình luận',
              ),
            ),
          if (signedIn) ...[
            if (_replyTo != null)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${english ? 'Reply to' : 'Trả lời'} @${_replyTo!.author.username}',
                    ),
                  ),
                  IconButton(
                    tooltip: english ? 'Cancel reply' : 'Hủy trả lời',
                    onPressed: draft.submissionPending || _submitting ? null : () => setState(() => _replyTo = null),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            if (recovery.hasError)
              Text(english ? 'Could not restore the pending comment. Sending is disabled.' : 'Không khôi phục được bình luận đang chờ. Chức năng gửi đã bị khóa.', style: VnlfTypography.meta(colors.red)),
            if (draft.pending != null && draft.pending!.attachmentIds.isNotEmpty)
              Text(english ? '${draft.pending!.attachmentIds.length} previously uploaded photos' : '${draft.pending!.attachmentIds.length} ảnh đã tải lên trước đó'),
            TextField(
              key: const ValueKey('comment-input'),
              controller: _input,
              readOnly: recovery.isLoading || recovery.hasError || draft.submissionPending || _submitting,
              focusNode: widget.focusNode,
              minLines: 2,
              maxLines: 5,
              maxLength: 4000,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: english ? 'Write a comment' : 'Viết bình luận',
                border: const OutlineInputBorder(),
              ),
            ),
            Text(
              english
                  ? 'Selected photos upload immediately and are publicly accessible. They may retain image metadata and remain on the server after removal.'
                  : 'Ảnh được tải lên và công khai ngay khi chọn, có thể giữ siêu dữ liệu và vẫn lưu trên máy chủ sau khi xóa khỏi bản nháp.',
              style: VnlfTypography.meta(colors.muted),
            ),
            Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                OutlinedButton.icon(
                  key: const ValueKey('comment-add-photos'),
                  onPressed: recovery.isLoading || recovery.hasError || _selecting || _submitting || draft.submissionPending || draft.attachments.length >= 10 ? null : _pickAttachments,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: Text(english ? 'Add photos' : 'Thêm ảnh'),
                ),
                Text('${draft.attachments.length}/10'),
              ],
            ),
            if (_attachmentError != null)
              Text(_attachmentError == 'limit'
                  ? (english ? 'A comment can have up to 10 photos.' : 'Mỗi bình luận có tối đa 10 ảnh.')
                  : (english ? 'Could not open selected photos.' : 'Không mở được ảnh đã chọn.'),
                style: VnlfTypography.meta(colors.red)),
            for (final item in draft.attachments)
              ListTile(
                key: ValueKey(item),
                leading: item.state == CommentAttachmentState.presigning || item.state == CommentAttachmentState.uploading || item.state == CommentAttachmentState.completing
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                    : Icon(item.state == CommentAttachmentState.ready ? Icons.image_outlined : Icons.error_outline),
                title: Text(item.file.name, overflow: TextOverflow.ellipsis),
                subtitle: Text(switch (item.state) {
                  CommentAttachmentState.selected => english ? 'Selected' : 'Đã chọn',
                  CommentAttachmentState.presigning => english ? 'Preparing' : 'Đang chuẩn bị',
                  CommentAttachmentState.uploading => english ? 'Uploading' : 'Đang tải lên',
                  CommentAttachmentState.completing => english ? 'Confirming' : 'Đang xác nhận',
                  CommentAttachmentState.ready => english ? 'Ready' : 'Sẵn sàng',
                  CommentAttachmentState.presignFailed || CommentAttachmentState.uploadFailed => english ? 'Upload failed; remove and select again.' : 'Tải lên thất bại; xóa và chọn lại.',
                  CommentAttachmentState.completeFailed => english ? 'Confirmation failed.' : 'Xác nhận thất bại.',
                }),
                trailing: Wrap(children: [
                  if (item.state == CommentAttachmentState.completeFailed)
                    IconButton(tooltip: english ? 'Retry confirmation' : 'Thử xác nhận lại', onPressed: _submitting ? null : () => _retryAttachment(item), icon: const Icon(Icons.refresh)),
                  IconButton(tooltip: english ? 'Remove photo' : 'Xóa ảnh',
                    onPressed: _submitting || draft.submissionPending || item.state == CommentAttachmentState.presigning || item.state == CommentAttachmentState.uploading || item.state == CommentAttachmentState.completing ? null : () => setState(() => draft.remove(item)),
                    icon: const Icon(Icons.close)),
                ]),
              ),
            if (draft.submissionPending && !_submitting)
              Text(english ? 'The previous submission may have been sent. Retry it unchanged to confirm.' : 'Bình luận trước có thể đã được gửi. Hãy thử lại nguyên nội dung để xác nhận.', style: VnlfTypography.meta(colors.muted)),
            if (_failure != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _failure is HttpFailure &&
                          [
                            401,
                            403,
                          ].contains((_failure as HttpFailure).statusCode)
                      ? (english
                            ? 'Sign in again to send your comment. Your draft is kept.'
                            : 'Đăng nhập lại để gửi bình luận. Bản nháp vẫn được giữ.')
                      : (english
                            ? 'Could not send comment. Your draft is kept; try again.'
                            : 'Không gửi được bình luận. Bản nháp vẫn được giữ; vui lòng thử lại.'),
                  style: VnlfTypography.meta(colors.red),
                ),
              ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed:
                    recovery.isLoading || recovery.hasError || (_input.text.trim().isEmpty && draft.readyIds.isEmpty) ||
                        draft.attachments.any((item) => item.state != CommentAttachmentState.ready) ||
                        _input.text.length > 4000 ||
                        _selecting || _submitting
                    ? null
                    : _submit,
                child: _submitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(english ? 'Add comment' : 'Thêm bình luận'),
              ),
            ),
          ],
          if (remote.isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (remote.hasError)
            Column(
              children: [
                Text(
                  english
                      ? 'Could not load comments'
                      : 'Không tải được bình luận',
                  style: VnlfTypography.meta(colors.red),
                ),
                TextButton(
                  onPressed: () =>
                      ref.invalidate(articleCommentsProvider(widget.postId)),
                  child: Text(english ? 'Retry' : 'Thử lại'),
                ),
              ],
            ),
          if (!remote.isLoading && !remote.hasError && comments.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                english ? 'No comments yet' : 'Chưa có bình luận',
                style: VnlfTypography.meta(colors.muted),
              ),
            ),
          for (final comment in comments) ...[
            const SizedBox(height: 16),
            VnlfCommentTree(
              comment: comment,
              replyLabel: english ? 'Reply' : 'Trả lời',
              onAuthor: (username) =>
                  context.push('/profile/${Uri.encodeComponent(username)}'),
              onVote: (id, value) => _action(
                () => ref
                    .read(commentActionsProvider(widget.postId).notifier)
                    .vote(items[id]!, switch (value) {
                      VoteState.upvoted => 1,
                      VoteState.downvoted => -1,
                      _ => 0,
                    }),
              ),
              onEdit: (id) => _edit(items[id]!),
              onDelete: (id) => _delete(items[id]!),
              onPin: (id) => _action(
                () => ref
                    .read(commentActionsProvider(widget.postId).notifier)
                    .pin(items[id]!),
              ),
              onReply: (id) {
                if (recovery.isLoading || recovery.hasError || draft.submissionPending || _submitting || !_authorized()) return;
                setState(() {
                  _replyTo = items[id];
                  if (_replyTo != null) {
                    final mention = '@${_replyTo!.author.username} ';
                    if (!_input.text.startsWith(mention)) {
                      _input.text = '$mention${_input.text}';
                      _input.selection = TextSelection.collapsed(
                        offset: _input.text.length,
                      );
                    }
                  }
                });
                widget.focusNode.requestFocus();
              },
            ),
          ],
        ],
      ),
    );
  }
}
