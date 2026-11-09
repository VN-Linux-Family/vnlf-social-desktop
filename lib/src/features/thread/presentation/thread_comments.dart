import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/models.dart';
import '../../../i18n/vi.dart';
import '../../feed/presentation/feed_notifier.dart';
import '../../shared/presentation/feature_samples.dart';
import '../../shared/presentation/feature_widgets.dart';
import '../domain/article_comment.dart';
import '../data/comment_attachment_controller.dart';
import '../mention/mention_candidates.dart';
import '../mention/mention_controller.dart';
import '../mention/mention_suggestions.dart';
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
  late MentionController _mentions;

  @override
  void initState() {
    super.initState();
    _mentions = _createMentionController();
  }

  MentionController _createMentionController() {
    final client = ref.read(apiClientProvider);
    return MentionController(
      input: _input,
      focusNode: widget.focusNode,
      repository: ref.read(mentionCandidatesRepositoryProvider),
      client: client,
      articleId: widget.postId,
      authenticated:
          ref.read(mentionSuggestionsEnabledProvider) &&
          widget.postId.isNotEmpty &&
          ref.read(sessionStateProvider) != null,
    );
  }

  @override
  void didUpdateWidget(covariant ThreadComments oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      _mentions.dispose();
      _mentions = _createMentionController();
    } else if (oldWidget.postId != widget.postId) {
      _mentions.updateContext(
        articleId: widget.postId,
        authenticated:
            ref.read(mentionSuggestionsEnabledProvider) &&
            widget.postId.isNotEmpty &&
            ref.read(sessionStateProvider) != null,
      );
    }
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
    _mentions.dispose();
    _input.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final content = _input.text.trim();
    final draft = ref.read(commentAttachmentControllerProvider(widget.postId));
    if ((content.isEmpty && draft.readyIds.isEmpty) ||
        content.length > 4000 ||
        _submitting) {
      return;
    }
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
        if (!draft.confirmed && _input.text.trim() == content) _input.clear();
        _replyTo = null;
      });
      ref.invalidate(articleCommentsProvider(widget.postId));
      ref.invalidate(feedNotifierProvider);
    } on AppFailure catch (error) {
      if (mounted &&
          revision == _revision &&
          ref.read(sessionStateProvider)?.userId == sessionId) {
        setState(() => _failure = error);
      }
    } catch (_) {
      if (mounted &&
          revision == _revision &&
          ref.read(sessionStateProvider)?.userId == sessionId) {
        setState(() => _failure = const TransportFailure());
      }
    } finally {
      if (mounted && revision == _revision) setState(() => _submitting = false);
    }
  }

  Future<void> _dismissConfirmation() async {
    final revision = _revision;
    final draft = ref.read(commentAttachmentControllerProvider(widget.postId));
    final owner = ref.read(sessionStateProvider)?.userId;
    try {
      await draft.dismissConfirmation();
      if (!mounted ||
          revision != _revision ||
          ref.read(sessionStateProvider)?.userId != owner ||
          !identical(
            draft,
            ref.read(commentAttachmentControllerProvider(widget.postId)),
          )) {
        return;
      }
      setState(() {
        _input.clear();
        _failure = null;
      });
    } catch (_) {
      if (mounted &&
          revision == _revision &&
          ref.read(sessionStateProvider)?.userId == owner) {
        setState(() => _failure = const TransportFailure());
      }
    }
  }

  Future<void> _pickAttachments() async {
    if (_selecting || !_authorized()) return;
    final revision = _revision;
    final owner = ref.read(sessionStateProvider)?.userId;
    final draft = ref.read(commentAttachmentControllerProvider(widget.postId));
    bool current() =>
        mounted &&
        revision == _revision &&
        ref.read(sessionStateProvider)?.userId == owner &&
        identical(
          draft,
          ref.read(commentAttachmentControllerProvider(widget.postId)),
        );
    void refresh() {
      if (current()) setState(() {});
    }

    setState(() {
      _selecting = true;
      _attachmentError = null;
    });
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
        try {
          await draft.upload(item, onChange: refresh);
        } catch (_) {
          refresh();
        }
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
    void refresh() {
      if (mounted && revision == _revision) setState(() {});
    }

    try {
      await draft.retryCompletion(item, onChange: refresh);
    } catch (_) {
      refresh();
    }
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
    final colors = VnlfColors.of(context);
    ref.listen(sessionStateProvider, (before, after) {
      if (before?.userId == after?.userId) return;
      _revision++;
      _mentions.updateContext(
        articleId: widget.postId,
        authenticated:
            ref.read(mentionSuggestionsEnabledProvider) &&
            widget.postId.isNotEmpty &&
            after != null,
      );
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
      pending: actions.pending,
      errors: actions.errors,
    );
    final draft = ref.watch(commentAttachmentControllerProvider(widget.postId));
    final recovery = ref.watch(
      commentAttachmentRecoveryProvider(widget.postId),
    );
    if (recovery.hasValue &&
        draft.pending != null &&
        _input.text != draft.pending!.content) {
      _input.text = draft.pending!.content;
    }
    ref.listen(commentAttachmentRecoveryProvider(widget.postId), (
      before,
      after,
    ) {
      if (after.hasValue) {
        final pending = ref
            .read(commentAttachmentControllerProvider(widget.postId))
            .pending;
        if (pending != null) setState(() => _input.text = pending.content);
      }
    });
    final signedIn = offlineFeatures || ref.watch(sessionStateProvider) != null;
    return FeatureSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(vi.common.binhLuan, style: VnlfTypography.h2(colors.ink)),
          const SizedBox(height: 12),
          if (!signedIn)
            TextButton(
              onPressed: () => context.push('/login'),
              child: Text(vi.commentsPanel.dangNhapDeBinhLuan),
            ),
          if (signedIn) ...[
            if (_replyTo != null)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${vi.commentsPanel.traLoi2} @${_replyTo!.author.username}',
                    ),
                  ),
                  IconButton(
                    tooltip: vi.commentsPanel.huyTraLoi,
                    onPressed: draft.submissionPending || _submitting
                        ? null
                        : () => setState(() => _replyTo = null),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            if (recovery.hasError)
              Text(
                vi.app.thread.khongKhoiPhucDuoc,
                style: VnlfTypography.meta(colors.red),
              ),
            if (draft.confirmed)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vi.app.thread.binhLuanDaDuoc,
                    key: const ValueKey('comment-confirmed'),
                  ),
                  TextButton(
                    key: const ValueKey('comment-confirmation-dismiss'),
                    onPressed: _dismissConfirmation,
                    child: Text(vi.app.thread.daHieu),
                  ),
                ],
              ),
            if (draft.pending != null &&
                draft.pending!.attachmentIds.isNotEmpty)
              Text(
                format(vi.app.thread.anhDaTaiLen, {
                  'attachmentIds': draft.pending!.attachmentIds.length,
                }),
              ),
            if (!draft.submissionPending)
              MentionSuggestions(controller: _mentions),
            Focus(
              onKeyEvent: (_, event) => _mentions.handleKey(event)
                  ? KeyEventResult.handled
                  : KeyEventResult.ignored,
              child: TextField(
                key: const ValueKey('comment-input'),
                controller: _input,
                readOnly:
                    recovery.isLoading ||
                    recovery.hasError ||
                    draft.submissionPending ||
                    _submitting,
                focusNode: widget.focusNode,
                minLines: 2,
                maxLines: 5,
                maxLength: 4000,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: vi.app.thread.vietBinhLuan,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            Text(
              vi.app.thread.anhDuocTaiLen,
              style: VnlfTypography.meta(colors.muted),
            ),
            Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                OutlinedButton.icon(
                  key: const ValueKey('comment-add-photos'),
                  onPressed:
                      recovery.isLoading ||
                          recovery.hasError ||
                          _selecting ||
                          _submitting ||
                          draft.submissionPending ||
                          draft.attachments.length >= 10
                      ? null
                      : _pickAttachments,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: Text(vi.app.thread.themAnh),
                ),
                Text('${draft.attachments.length}/10'),
              ],
            ),
            if (_attachmentError != null)
              Text(
                _attachmentError == 'limit'
                    ? vi.app.thread.moiBinhLuanCo
                    : vi.app.thread.khongMoDuocAnh,
                style: VnlfTypography.meta(colors.red),
              ),
            for (final item in draft.attachments)
              ListTile(
                key: ValueKey(item),
                leading:
                    item.state == CommentAttachmentState.presigning ||
                        item.state == CommentAttachmentState.uploading ||
                        item.state == CommentAttachmentState.completing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        item.state == CommentAttachmentState.ready
                            ? Icons.image_outlined
                            : Icons.error_outline,
                      ),
                title: Text(item.file.name, overflow: TextOverflow.ellipsis),
                subtitle: Text(switch (item.state) {
                  CommentAttachmentState.selected => vi.app.common.daChon,
                  CommentAttachmentState.presigning =>
                    vi.app.thread.dangChuanBi,
                  CommentAttachmentState.uploading => vi.app.thread.dangTaiLen,
                  CommentAttachmentState.completing =>
                    vi.app.thread.dangXacNhan,
                  CommentAttachmentState.ready => vi.app.thread.sanSang,
                  CommentAttachmentState.presignFailed ||
                  CommentAttachmentState.uploadFailed =>
                    vi.app.thread.taiLenThatBai,
                  CommentAttachmentState.completeFailed =>
                    vi.app.thread.xacNhanThatBai,
                }),
                trailing: Wrap(
                  children: [
                    if (item.state == CommentAttachmentState.completeFailed)
                      IconButton(
                        tooltip: vi.app.thread.thuXacNhanLai,
                        onPressed: _submitting
                            ? null
                            : () => _retryAttachment(item),
                        icon: const Icon(Icons.refresh),
                      ),
                    IconButton(
                      tooltip: vi.app.common.xoaAnh,
                      onPressed:
                          _submitting ||
                              draft.submissionPending ||
                              item.state == CommentAttachmentState.presigning ||
                              item.state == CommentAttachmentState.uploading ||
                              item.state == CommentAttachmentState.completing
                          ? null
                          : () => setState(() => draft.remove(item)),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
            if (draft.submissionPending && !draft.confirmed && !_submitting)
              Text(
                vi.app.thread.binhLuanTruocCo,
                style: VnlfTypography.meta(colors.muted),
              ),
            if (_failure != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _failure is HttpFailure &&
                          [
                            401,
                            403,
                          ].contains((_failure as HttpFailure).statusCode)
                      ? vi.app.thread.dangNhapLaiDe
                      : vi.app.thread.khongGuiDuocBinh,
                  style: VnlfTypography.meta(colors.red),
                ),
              ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed:
                    recovery.isLoading ||
                        recovery.hasError ||
                        draft.confirmed ||
                        (_input.text.trim().isEmpty &&
                            draft.readyIds.isEmpty) ||
                        draft.attachments.any(
                          (item) => item.state != CommentAttachmentState.ready,
                        ) ||
                        _input.text.length > 4000 ||
                        _selecting ||
                        _submitting
                    ? null
                    : _submit,
                child: _submitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(vi.app.thread.themBinhLuan),
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
                  vi.app.thread.khongTaiDuocBinh,
                  style: VnlfTypography.meta(colors.red),
                ),
                TextButton(
                  onPressed: () =>
                      ref.invalidate(articleCommentsProvider(widget.postId)),
                  child: Text(vi.common.thuLai),
                ),
              ],
            ),
          if (!remote.isLoading && !remote.hasError && comments.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                vi.commentsPanel.chuaCoBinhLuan,
                style: VnlfTypography.meta(colors.muted),
              ),
            ),
          for (final comment in comments) ...[
            const SizedBox(height: 16),
            VnlfCommentTree(
              comment: comment,
              replyLabel: vi.commentsPanel.traLoi2,
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
                if (recovery.isLoading ||
                    recovery.hasError ||
                    draft.submissionPending ||
                    _submitting ||
                    !_authorized()) {
                  return;
                }
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
