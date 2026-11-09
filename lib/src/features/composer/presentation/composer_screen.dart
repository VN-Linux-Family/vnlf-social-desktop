import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../design_system/tokens/vnlf_colors.dart';
import '../../../i18n/vi.dart';
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
              Text(vi.app.composer.dangNhapDeViet),
              TextButton(
                onPressed: () => GoRouter.maybeOf(context)?.push('/login'),
                child: Text(vi.common.dangNhap),
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
          tooltip: vi.common.dong,
          icon: const Icon(Icons.close),
          onPressed: () => _close(controller),
        ),
        title: Text(
          draft.format == 'ARTICLE'
              ? vi.articleEditor.vietArticle
              : vi.articleEditor.taoBaiDang,
        ),
        actions: [
          IconButton(
            tooltip: vi.app.composer.banNhap,
            onPressed: controller.busy ? null : () => _drafts(controller),
            icon: const Icon(Icons.drafts_outlined),
          ),
          TextButton(
            onPressed:
                controller.busy || locked || controller.initializationFailed
                ? null
                : controller.save,
            child: Text(vi.common.luu),
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
                    ? vi.app.composer.kiemTraLanDang2
                    : vi.articleEditor.dang,
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
                          composerFailureText(controller.error!),
                          error: true,
                        ),
                      if (controller.recoveryError != null)
                        _notice(
                          composerFailureText(controller.recoveryError!),
                          error: true,
                        ),
                      if (_pickerError != null)
                        _notice(_pickerError!, error: true),
                      if (locked) _notice(vi.app.composer.mayChuChuaXac),
                      if (controller.conflictingDraft != null)
                        Wrap(
                          children: [
                            TextButton(
                              onPressed: () =>
                                  controller.resolveConflict(keepLocal: true),
                              child: Text(vi.app.composer.luuBanDangSua),
                            ),
                            TextButton(
                              onPressed: () =>
                                  controller.resolveConflict(keepLocal: false),
                              child: Text(vi.app.composer.taiBanTrenMay),
                            ),
                          ],
                        ),
                      if (controller.initializationFailed)
                        TextButton(
                          onPressed: () =>
                              controller.initialize(draftId: widget.draftId),
                          child: Text(vi.app.composer.taiLaiBanNhap),
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
                              Text(vi.articleEditor.congKhai),
                              Text(
                                controller.busy
                                    ? vi.common.dangLuu
                                    : controller.dirty
                                    ? vi.app.composer.chuaLuuThayDoi
                                    : draft.id.isEmpty
                                    ? vi.articleEditor.draftMoi
                                    : vi.common.daLuu,
                              ),
                              TextButton(
                                onPressed: controller.busy || locked
                                    ? null
                                    : () => _changeFormat(controller),
                                child: Text(
                                  draft.format == 'POST'
                                      ? vi.app.composer.vietBaiDaiArticle
                                      : vi.articleEditor.baiThuong,
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
                                      ? vi.articleEditor.soan
                                      : vi.articleEditor.xemTruoc,
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
        setState(() => _pickerError = vi.app.composer.khongMoDuocTep);
      }
    }
  }

  Future<void> _changeFormat(ComposerController controller) async {
    final draft = controller.draft;
    if (draft.format == 'POST') {
      if (draft.media.any((m) => m.isVideo)) {
        setState(() => _pickerError = vi.app.composer.goVideoTruocKhi);
        return;
      }
      if (draft.publishedAt == null && draft.pollDraft != null) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(vi.app.composer.chuyenSangArticle),
            content: Text(vi.app.composer.binhChonChiDungTrong),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(vi.common.huy),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(vi.app.composer.chuyen),
              ),
            ],
          ),
        );
        if (confirmed != true || !mounted) return;
      }
      try {
        controller.edit(asArticle(controller.draft));
      } catch (failure) {
        setState(() => _pickerError = composerFailureText(failure));
      }
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(vi.app.composer.chuyenSangBaiThuong),
        content: Text(vi.app.composer.tieuDeMoTa),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(vi.common.huy),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(vi.app.composer.chuyen),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      controller.edit(asRegularPost(controller.draft));
    } catch (failure) {
      setState(() => _pickerError = composerFailureText(failure));
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
