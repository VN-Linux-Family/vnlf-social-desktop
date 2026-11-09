import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/vnlf_navigation_helper.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/models.dart';
import '../../../i18n/vi.dart';
import '../../feed/presentation/feed_notifier.dart';
import '../../shared/presentation/feature_samples.dart';
import '../../shared/presentation/session_avatar.dart';
import '../domain/article_comment.dart';
import '../data/comment_attachment_controller.dart';
import '../mention/mention_candidates.dart';
import '../mention/mention_controller.dart';
import '../mention/mention_suggestions.dart';
import 'comment_attachment_picker.dart';
import 'comments_providers.dart';
import 'detail_parts.dart';
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
  final _portal = OverlayPortalController();
  double _composerHeight = 64;

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
    final phone = isPhoneLayout(context);
    final composer = _composer(
      context,
      draft: draft,
      recovery: recovery,
      phone: phone,
    );
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: colors.line)),
          ),
          child: Semantics(
            header: true,
            child: Text(
              format(vi.commentsPanel.binhLuan, {'count': items.length}),
              style: VnlfTypography.body(colors.ink)
                  .copyWith(fontWeight: FontWeight.w800),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 12),
          child: _list(context, remote, comments, items, draft, recovery),
        ),
      ],
    );
    // The composer spans the card's full width under a hairline, as the
    // website's sticky `.comment-composer-wrap` does.
    final section = Container(
      padding: phone
          ? const EdgeInsets.fromLTRB(16, 12, 16, 0)
          : const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: colors.surface,
        border: phone ? null : Border.all(color: colors.line),
        borderRadius: phone
            ? null
            : BorderRadius.circular(VnlfDimensions.radiusLg),
      ),
      child: phone
          ? body
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: body,
                ),
                composer,
              ],
            ),
    );
    if (!phone) return section;
    if (!_portal.isShowing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_portal.isShowing) _portal.show();
      });
    }
    return OverlayPortal(
      controller: _portal,
      overlayChildBuilder: (context) => Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        child: _ReportHeight(
          onHeight: (height) {
            if ((height - _composerHeight).abs() > .5) {
              setState(() => _composerHeight = height);
            }
          },
          child: composer,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: _composerHeight),
        child: section,
      ),
    );
  }

  Widget _list(
    BuildContext context,
    AsyncValue<List<ArticleComment>> remote,
    List<CommentNodeData> comments,
    Map<String, ArticleComment> items,
    CommentAttachmentController draft,
    AsyncValue<void> recovery,
  ) {
    final colors = VnlfColors.of(context);
    final muted = VnlfTypography.body(colors.muted);
    if (remote.isLoading && comments.isEmpty) {
      return Semantics(
        liveRegion: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Text(vi.commentsPanel.dangTaiBinhLuan, style: muted),
        ),
      );
    }
    if (remote.hasError && comments.isEmpty) {
      return ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 190),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 7,
            children: [
              Text(
                vi.commentsPanel.chuaTaiDuocBinhLuan,
                style: muted.copyWith(fontWeight: FontWeight.w700),
              ),
              TextButton(
                onPressed: () =>
                    ref.invalidate(articleCommentsProvider(widget.postId)),
                child: Text(vi.common.thuLai),
              ),
            ],
          ),
        ),
      );
    }
    if (comments.isEmpty) {
      return ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 190),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 7,
            children: [
              VnlfIcon(VnlfLucide.messageCircle, size: 24, color: colors.muted),
              Text(
                vi.commentsPanel.chuaCoBinhLuan,
                style: muted.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(vi.commentsPanel.moDauCuocThaoLuan, style: muted),
            ],
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final comment in comments)
          VnlfCommentTree(
            comment: comment,
            replyLabel: vi.commentsPanel.traLoi2,
            onAuthor: (username) =>
                context.push('/profile/${Uri.encodeComponent(username)}'),
            onLink: (url) => openVnlfLink(context, url),
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
    );
  }

  bool _canSend(CommentAttachmentController draft, AsyncValue<void> recovery) =>
      !(recovery.isLoading ||
          recovery.hasError ||
          draft.confirmed ||
          (_input.text.trim().isEmpty && draft.readyIds.isEmpty) ||
          draft.attachments.any(
            (item) => item.state != CommentAttachmentState.ready,
          ) ||
          _input.text.length > 4000 ||
          _selecting ||
          _submitting);

  /// The website's comment composer: reply chip, uploads and notices above a
  /// row of avatar, growing text box, photo button and send button.
  Widget _composer(
    BuildContext context, {
    required CommentAttachmentController draft,
    required AsyncValue<void> recovery,
    required bool phone,
  }) {
    final colors = VnlfColors.of(context);
    final signedIn = offlineFeatures || ref.watch(sessionStateProvider) != null;
    final error = VnlfTypography.body(colors.red);
    final busy =
        recovery.isLoading ||
        recovery.hasError ||
        draft.submissionPending ||
        _submitting;
    final canSend = _canSend(draft, recovery);
    final onBrand = colors.isDark ? const Color(0xFF102116) : Colors.white;
    return Material(
      color: colors.surface,
      shape: phone
          ? Border(top: BorderSide(color: colors.line))
          : RoundedRectangleBorder(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(VnlfDimensions.radiusLg),
              ),
              side: BorderSide.none,
            ),
      child: Container(
        decoration: phone
            ? null
            : BoxDecoration(
                border: Border(top: BorderSide(color: colors.line)),
              ),
        padding: phone
            ? const EdgeInsets.fromLTRB(16, 8, 16, 8)
            : const EdgeInsets.fromLTRB(20, 10, 20, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_replyTo != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surfaceSoft,
                    border: Border.all(color: colors.line),
                    borderRadius: BorderRadius.circular(
                      VnlfDimensions.radiusMd,
                    ),
                  ),
                  child: Row(
                    spacing: 8,
                    children: [
                      VnlfIcon(VnlfLucide.reply, size: 16, color: colors.brand),
                      Expanded(
                        child: Text(
                          format(vi.commentsPanel.traLoi, {
                            'displayName': _replyTo!.author.displayName,
                          }),
                          style: VnlfTypography.body(colors.brand),
                        ),
                      ),
                      IconButton(
                        tooltip: vi.commentsPanel.huyTraLoi,
                        visualDensity: VisualDensity.compact,
                        onPressed: busy
                            ? null
                            : () => setState(() => _replyTo = null),
                        icon: VnlfIcon(
                          VnlfLucide.x,
                          size: 16,
                          color: colors.brand,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (recovery.hasError)
              Text(vi.app.thread.khongKhoiPhucDuoc, style: error),
            if (draft.confirmed)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      vi.app.thread.binhLuanDaDuoc,
                      key: const ValueKey('comment-confirmed'),
                    ),
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
            if (draft.attachments.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: draft.attachments.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, i) =>
                        _uploadTile(context, draft, draft.attachments[i]),
                  ),
                ),
              ),
            if (draft.attachments.isNotEmpty)
              // The app also says what the website leaves unsaid: uploads are
              // public as soon as they are picked (API_NOTES, 2026-11-07).
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  vi.app.thread.anhDuocTaiLen,
                  style: VnlfTypography.body(colors.muted),
                ),
              ),
            if (_attachmentError != null)
              Text(
                _attachmentError == 'limit'
                    ? vi.commentsPanel.moiBinhLuanToiDa
                    : vi.commentsPanel.chonAnhJpgPngWebp,
                style: error,
              ),
            if (draft.submissionPending && !draft.confirmed && !_submitting)
              Text(
                vi.app.thread.binhLuanTruocCo,
                style: VnlfTypography.body(colors.muted),
              ),
            if (_failure != null)
              Text(
                _failure is HttpFailure &&
                        [
                          401,
                          403,
                        ].contains((_failure as HttpFailure).statusCode)
                    ? vi.app.thread.dangNhapLaiDe
                    : vi.commentsPanel.chuaGuiDuocBinhLuan,
                style: error,
              ),
            if (!draft.submissionPending)
              MentionSuggestions(controller: _mentions),
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                spacing: 6,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: sessionAvatar(
                      ref.watch(sessionStateProvider),
                      size: 44,
                      cornerRadius: VnlfDimensions.radiusMd,
                    ),
                  ),
                  Expanded(
                    child: Focus(
                      onKeyEvent: (_, event) {
                        if (_mentions.handleKey(event)) {
                          return KeyEventResult.handled;
                        }
                        if (event is KeyDownEvent &&
                            event.logicalKey == LogicalKeyboardKey.enter &&
                            !HardwareKeyboard.instance.isShiftPressed) {
                          if (canSend) _submit();
                          return KeyEventResult.handled;
                        }
                        return KeyEventResult.ignored;
                      },
                      child: TextField(
                        key: const ValueKey('comment-input'),
                        controller: _input,
                        focusNode: widget.focusNode,
                        readOnly: !signedIn || busy,
                        onTap: signedIn ? null : () => context.push('/login'),
                        minLines: 1,
                        maxLines: 7,
                        maxLength: 4000,
                        textInputAction: TextInputAction.newline,
                        onChanged: (_) => setState(() {}),
                        style: VnlfTypography.body(colors.ink),
                        decoration: InputDecoration(
                          hintText: signedIn
                              ? vi.commentsPanel.vietBinhLuan
                              : vi.commentsPanel.dangNhapDeBinhLuan,
                          hintStyle: VnlfTypography.body(colors.muted),
                          counterText: '',
                          isDense: true,
                          filled: true,
                          fillColor: colors.surfaceSoft,
                          contentPadding: const EdgeInsets.all(12),
                          constraints: const BoxConstraints(minHeight: 44),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              VnlfDimensions.radiusLg,
                            ),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: phone ? 44 : 40,
                    height: 44,
                    child: IconButton(
                      key: const ValueKey('comment-add-photos'),
                      tooltip: vi.commentsPanel.dinhKemAnhBinhLuan,
                      padding: EdgeInsets.zero,
                      onPressed:
                          !signedIn ||
                              busy ||
                              _selecting ||
                              draft.attachments.length >= 10
                          ? null
                          : _pickAttachments,
                      icon: VnlfIcon(
                        VnlfLucide.imagePlus,
                        size: 20,
                        color: colors.muted,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    height: 44,
                    child: Tooltip(
                      message: vi.commentsPanel.guiBinhLuan,
                      child: FilledButton(
                        key: const ValueKey('comment-send'),
                        onPressed: canSend ? _submit : null,
                        style: FilledButton.styleFrom(
                          padding: EdgeInsets.zero,
                          backgroundColor: colors.brand,
                          foregroundColor: onBrand,
                          disabledBackgroundColor: colors.brand.withValues(
                            alpha: .5,
                          ),
                          disabledForegroundColor: onBrand,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              VnlfDimensions.radiusSm,
                            ),
                          ),
                        ),
                        child: _submitting
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: onBrand,
                                ),
                              )
                            : VnlfIcon(
                                VnlfLucide.send,
                                size: 18,
                                color: onBrand,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// A photo waiting under the composer: its name, progress and remove.
  Widget _uploadTile(
    BuildContext context,
    CommentAttachmentController draft,
    CommentAttachment item,
  ) {
    final colors = VnlfColors.of(context);
    final working =
        item.state == CommentAttachmentState.presigning ||
        item.state == CommentAttachmentState.uploading ||
        item.state == CommentAttachmentState.completing;
    final failed =
        item.state == CommentAttachmentState.presignFailed ||
        item.state == CommentAttachmentState.uploadFailed ||
        item.state == CommentAttachmentState.completeFailed;
    return Container(
      key: ValueKey(item),
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: colors.surfaceSoft,
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(VnlfDimensions.radiusMd),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 30, 26),
              child: Text(
                item.file.name,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: VnlfTypography.body(colors.muted),
              ),
            ),
          ),
          Positioned(
            top: 2,
            right: 2,
            child: IconButton(
              tooltip: vi.app.common.xoaAnh,
              visualDensity: VisualDensity.compact,
              onPressed: _submitting || draft.submissionPending || working
                  ? null
                  : () => setState(() => draft.remove(item)),
              icon: Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0x8C000000),
                ),
                child: const Center(
                  child: VnlfIcon(VnlfLucide.x, size: 16, color: Colors.white),
                ),
              ),
            ),
          ),
          if (working || failed)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Material(
                color: Colors.black.withValues(alpha: .55),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(VnlfDimensions.radiusMd - 1),
                ),
                child: InkWell(
                  onTap:
                      item.state == CommentAttachmentState.completeFailed &&
                          !_submitting
                      ? () => _retryAttachment(item)
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      spacing: 4,
                      children: [
                        if (failed)
                          const VnlfIcon(
                            VnlfLucide.rotateCcw,
                            size: 14,
                            color: Colors.white,
                          ),
                        Flexible(
                          child: Text(
                            failed ? vi.common.thuLai : vi.common.dangTai,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: VnlfTypography.body(Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Reports the laid-out height of [child], so the page can leave room for a
/// composer that floats over it.
class _ReportHeight extends SingleChildRenderObjectWidget {
  const _ReportHeight({required this.onHeight, required super.child});

  final ValueChanged<double> onHeight;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderReportHeight(onHeight);

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderReportHeight renderObject,
  ) => renderObject.onHeight = onHeight;
}

class _RenderReportHeight extends RenderProxyBox {
  _RenderReportHeight(this.onHeight);

  ValueChanged<double> onHeight;
  double? _reported;

  @override
  void performLayout() {
    super.performLayout();
    final height = size.height;
    if (_reported != height) {
      _reported = height;
      WidgetsBinding.instance.addPostFrameCallback((_) => onHeight(height));
    }
  }
}
