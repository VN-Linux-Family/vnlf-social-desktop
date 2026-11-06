import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../design_system/tokens/vnlf_colors.dart';
import '../../feed/presentation/feed_notifier.dart';
import '../domain/composer_draft.dart';
import '../domain/composer_format.dart';
import 'composer_controller.dart';
import 'composer_draft_picker.dart';
import 'composer_editor.dart';
import 'composer_messages.dart';
import 'composer_writing_pane.dart';
import 'composer_providers.dart';

class ComposerScreen extends ConsumerStatefulWidget {
  const ComposerScreen({super.key, this.draftId});
  final String? draftId;
  @override
  ConsumerState<ComposerScreen> createState() => _ComposerScreenState();
}

class _ComposerScreenState extends ConsumerState<ComposerScreen> {
  final _editorKey = GlobalKey<ComposerEditorState>();
  bool _preview = false;
  String? _pickerError;
  @override
  Widget build(BuildContext context) {
    final en = Localizations.localeOf(context).languageCode == 'en';
    final session =
        ref.watch(sessionStateProvider) ??
        ref.watch(sessionProvider).valueOrNull;
    if (session == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(en ? 'Sign in to write a post' : 'Đăng nhập để viết bài'),
              TextButton(
                onPressed: () => GoRouter.maybeOf(context)?.push('/login'),
                child: Text(en ? 'Sign in' : 'Đăng nhập'),
              ),
            ],
          ),
        ),
      );
    }
    final controller = ref.watch(composerControllerProvider(widget.draftId));
    final draft = controller.draft;
    final locked = controller.publishUncertain;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: en ? 'Close' : 'Đóng',
          icon: const Icon(Icons.close),
          onPressed: () => _close(controller),
        ),
        title: Text(
          draft.format == 'ARTICLE'
              ? (en ? 'Write an article' : 'Viết Article')
              : (en ? 'Create post' : 'Tạo bài đăng'),
        ),
        actions: [
          IconButton(
            tooltip: en ? 'Drafts' : 'Bản nháp',
            onPressed: controller.busy ? null : () => _drafts(controller),
            icon: const Icon(Icons.drafts_outlined),
          ),
          TextButton(
            onPressed:
                controller.busy || locked || controller.initializationFailed
                ? null
                : controller.save,
            child: Text(en ? 'Save' : 'Lưu'),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              onPressed:
                  controller.busy ||
                      !controller.initialized ||
                      controller.initializationFailed
                  ? null
                  : () => _publish(controller),
              child: Text(
                locked
                    ? (en ? 'Retry publication' : 'Kiểm tra lần đăng')
                    : (en ? 'Publish' : 'Đăng'),
              ),
            ),
          ),
        ],
      ),
      body: !controller.initialized
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (controller.busy) const LinearProgressIndicator(),
                      if (controller.error != null)
                        _notice(
                          composerFailureText(controller.error!, en),
                          error: true,
                        ),
                      if (controller.recoveryError != null)
                        _notice(
                          composerFailureText(controller.recoveryError!, en),
                          error: true,
                        ),
                      if (_pickerError != null)
                        _notice(_pickerError!, error: true),
                      if (locked)
                        _notice(
                          en
                              ? 'The server has not confirmed the last publication. Retrying checks the same submission.'
                              : 'Máy chủ chưa xác nhận lần đăng trước. Bấm kiểm tra để xác nhận cùng lần đăng đó.',
                        ),
                      if (controller.conflictingDraft != null)
                        Wrap(
                          children: [
                            TextButton(
                              onPressed: () =>
                                  controller.resolveConflict(keepLocal: true),
                              child: Text(
                                en
                                    ? 'Save my version over the latest'
                                    : 'Lưu bản đang sửa lên phiên bản mới nhất',
                              ),
                            ),
                            TextButton(
                              onPressed: () =>
                                  controller.resolveConflict(keepLocal: false),
                              child: Text(
                                en
                                    ? 'Load the server version'
                                    : 'Tải bản trên máy chủ',
                              ),
                            ),
                          ],
                        ),
                      if (controller.initializationFailed)
                        TextButton(
                          onPressed: () =>
                              controller.initialize(draftId: widget.draftId),
                          child: Text(
                            en ? 'Retry loading draft' : 'Tải lại bản nháp',
                          ),
                        )
                      else ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          child: Wrap(
                            spacing: 12,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                '${session.displayName}  @${session.username}',
                              ),
                              const Icon(Icons.public, size: 16),
                              Text(en ? 'Public' : 'Công khai'),
                              Text(
                                controller.busy
                                    ? (en ? 'Saving…' : 'Đang lưu…')
                                    : controller.dirty
                                    ? (en
                                          ? 'Unsaved changes'
                                          : 'Chưa lưu thay đổi')
                                    : draft.id.isEmpty
                                    ? (en ? 'New draft' : 'Bản nháp mới')
                                    : (en ? 'Saved' : 'Đã lưu'),
                              ),
                              TextButton(
                                onPressed: controller.busy || locked
                                    ? null
                                    : () => _changeFormat(controller),
                                child: Text(
                                  draft.format == 'POST'
                                      ? (en
                                            ? 'Write a long article'
                                            : 'Viết bài dài · Article')
                                      : (en ? 'Regular post' : 'Bài thường'),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () =>
                                    setState(() => _preview = !_preview),
                                icon: Icon(
                                  _preview
                                      ? Icons.edit_outlined
                                      : Icons.visibility_outlined,
                                ),
                                label: Text(
                                  _preview
                                      ? (en ? 'Edit' : 'Soạn')
                                      : (en ? 'Preview' : 'Xem trước'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ComposerWritingPane(
                          controller: controller,
                          editorKey: _editorKey,
                          preview: _preview,
                          onPick: (placement, video) => _pick(
                            controller,
                            placement: placement,
                            video: video,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _notice(String text, {bool error = false}) => Semantics(
    liveRegion: true,
    child: Container(
      padding: const EdgeInsets.all(12),
      color: error
          ? Theme.of(context).colorScheme.errorContainer
          : VnlfColors.of(context).surfaceSoft,
      child: Text(text),
    ),
  );
  Future<void> _close(ComposerController controller) async {
    await controller.flushRecovery();
    if (!mounted || (controller.dirty && controller.recoveryError != null)) {
      return;
    }
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      GoRouter.maybeOf(context)?.go('/');
    }
  }

  Future<void> _publish(ComposerController controller) async {
    final published = await controller.publish();
    if (!mounted || published == null) return;
    ref.invalidate(feedNotifierProvider);
    ref.invalidate(composerDraftsProvider);
    GoRouter.maybeOf(context)
        ?.go('/thread/${Uri.encodeComponent(published.id)}');
  }

  Future<void> _pick(
    ComposerController controller, {
    bool video = false,
    String placement = 'ATTACHMENT',
  }) async {
    final en = Localizations.localeOf(context).languageCode == 'en';
    try {
      final files = await openFiles(
        acceptedTypeGroups: [
          video
              ? const XTypeGroup(
                  label: 'Video',
                  extensions: ['mp4', 'mov', 'webm'],
                  mimeTypes: ['video/mp4', 'video/quicktime', 'video/webm'],
                )
              : const XTypeGroup(
                  label: 'Images',
                  extensions: ['jpg', 'jpeg', 'png', 'webp', 'gif'],
                  mimeTypes: [
                    'image/jpeg',
                    'image/png',
                    'image/webp',
                    'image/gif',
                  ],
                ),
        ],
      );
      if (!mounted) return;
      setState(() => _pickerError = null);
      for (final file
          in placement == 'COVER' || video ? files.take(1) : files) {
        if (!mounted) break;
        final mime =
            file.mimeType ??
            _mimes[file.name.split('.').last.toLowerCase()] ??
            '';
        final media = await controller.upload(
          ComposerUpload(
            name: file.name,
            mime: mime,
            length: await file.length(),
            openRead: file.openRead,
          ),
          placement: placement,
        );
        if (media == null || !mounted) break;
        if (placement == 'INLINE') _editorKey.currentState?.insertImage(media);
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _pickerError = en
              ? 'Could not open the selected file. Your draft is kept.'
              : 'Không mở được tệp đã chọn. Bản nháp vẫn được giữ.',
        );
      }
    }
  }

  Future<void> _changeFormat(ComposerController controller) async {
    final draft = controller.draft;
    final en = Localizations.localeOf(context).languageCode == 'en';
    if (draft.format == 'POST') {
      if (draft.media.any((m) => m.isVideo)) {
        setState(
          () => _pickerError = en
              ? 'Remove the video before switching to an article.'
              : 'Gỡ video trước khi chuyển sang Article.',
        );
        return;
      }
      try {
        controller.edit(asArticle(controller.draft));
      } catch (failure) {
        setState(() => _pickerError = composerFailureText(failure, en));
      }
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          en ? 'Switch to a regular post?' : 'Chuyển sang bài thường?',
        ),
        content: Text(
          en
              ? 'Title, excerpt, tags and cover will be removed. Images in the text become attachments.'
              : 'Tiêu đề, mô tả, thẻ và ảnh bìa sẽ được gỡ. Ảnh trong nội dung chuyển thành tệp đính kèm.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(en ? 'Cancel' : 'Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(en ? 'Switch' : 'Chuyển'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      controller.edit(asRegularPost(controller.draft));
    } catch (failure) {
      setState(() => _pickerError = composerFailureText(failure, en));
    }
  }

  Future<void> _drafts(ComposerController controller) async {
    await controller.flushRecovery();
    if (!mounted) return;
    final id = await chooseServerDraft(context);
    if (id != null && mounted) {
      GoRouter.maybeOf(context)?.go('/compose/${Uri.encodeComponent(id)}');
    }
  }
}

const _mimes = {
  'jpg': 'image/jpeg',
  'jpeg': 'image/jpeg',
  'png': 'image/png',
  'webp': 'image/webp',
  'gif': 'image/gif',
  'mp4': 'video/mp4',
  'mov': 'video/quicktime',
  'webm': 'video/webm',
};
