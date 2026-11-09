import 'dart:async';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/api_client.dart';
import '../../../core/request_identity.dart';
import '../../../i18n/vi.dart';
import '../data/feedback_draft_controller.dart';
import '../data/feedback_draft_store.dart';
import '../data/feedback_media_repository.dart';
import '../domain/feedback_draft.dart';

final feedbackFilePickerProvider =
    Provider<Future<FeedbackMediaFile?> Function()>((ref) => _pickFile);

final feedbackMediaRepositoryProvider = Provider<FeedbackMediaRepository>(
  (ref) => FeedbackMediaRepository(ref.watch(apiClientProvider)),
);

Future<FeedbackMediaFile?> _pickFile() async {
  final file = await openFile(
    acceptedTypeGroups: [
      XTypeGroup(
        label: vi.app.feedback.anhVaVideo,
        extensions: ['jpg', 'jpeg', 'png', 'webp', 'gif', 'mp4', 'webm'],
        mimeTypes: [
          'image/jpeg',
          'image/png',
          'image/webp',
          'image/gif',
          'video/mp4',
          'video/webm',
        ],
      ),
    ],
  );
  if (file == null) return null;
  const mimes = {
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'webp': 'image/webp',
    'gif': 'image/gif',
    'mp4': 'video/mp4',
    'webm': 'video/webm',
  };
  return FeedbackMediaFile(
    name: file.name,
    mime: file.mimeType ?? mimes[file.name.split('.').last.toLowerCase()] ?? '',
    length: await file.length(),
    openRead: file.openRead,
  );
}

/// The caller prevents more than one dialog from being open at once.
class FeedbackAttachmentDialog extends ConsumerStatefulWidget {
  const FeedbackAttachmentDialog({
    super.key,
    required this.ownerId,
    required this.pagePath,
  });
  final String ownerId;
  final String pagePath;

  @override
  ConsumerState<FeedbackAttachmentDialog> createState() =>
      _FeedbackAttachmentDialogState();
}

class _FeedbackAttachmentDialogState
    extends ConsumerState<FeedbackAttachmentDialog> {
  final _detail = TextEditingController();
  final _contact = TextEditingController();
  FeedbackDraftController? _controller;
  String _kind = 'FEEDBACK';
  String? _error;
  bool _busy = true;
  bool _done = false;
  Timer? _saveTimer;
  Future<void> _saveTail = Future.value();
  bool _saveFailed = false;
  int _editRevision = 0;
  int _savedRevision = 0;
  Future<void>? _preserveFuture;
  bool _ownerChanged = false;
  bool _preserving = false;

  String? _owner() => ref.read(sessionStateProvider)?.userId;

  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    try {
      final client = ref.read(apiClientProvider);
      final controller = await FeedbackDraftController.open(
        store: FeedbackDraftStore(ref.read(sessionStorageProvider)),
        media: ref.read(feedbackMediaRepositoryProvider),
        client: client,
        currentOwner: _owner,
        initial: FeedbackDraft(
          ownerId: widget.ownerId,
          submissionId: newRequestIdentity(),
          kind: 'FEEDBACK',
          detail: '',
          contact: '',
          pagePath: widget.pagePath,
          assetIds: [],
          uploadUncertain: false,
          submissionUncertain: false,
        ),
      );
      if (!mounted) return;
      _controller = controller;
      _detail.text = controller.draft.detail;
      _contact.text = controller.draft.contact;
      _kind = controller.draft.kind;
      _done = controller.draft.submissionConfirmed;
    } catch (_) {
      if (mounted) {
        _error = (vi.app.feedback.khongTheKhoiPhuc);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _enqueueSave() {
    final controller = _controller!;
    final kind = _kind;
    final detail = _detail.text;
    final contact = _contact.text;
    final revision = _editRevision;
    _saveTail = _saveTail.then((_) async {
      if (!controller.draft.submissionUncertain &&
          !controller.draft.uploadUncertain) {
        await controller.edit(
          kind: kind,
          detail: detail,
          contact: contact,
          pagePath: controller.draft.pagePath,
        );
        _savedRevision = revision;
      }
    });
    return _saveTail;
  }

  void _scheduleSave() {
    _editRevision++;
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 400), () {
      _enqueueSave().then<void>(
        (_) {},
        onError: (Object _, StackTrace _) {
          if (mounted) setState(() => _saveFailed = true);
        },
      );
    });
  }

  void _preserveOriginalOwner() {
    if (_preserving) return;
    _saveTimer?.cancel();
    _saveTimer = null;
    final controller = _controller;
    if (controller == null || _editRevision == _savedRevision) return;
    _preserving = true;
    final detail = _detail.text;
    final contact = _contact.text;
    final kind = _kind;
    final store = FeedbackDraftStore(ref.read(sessionStorageProvider));
    _preserveFuture = () async {
      try {
        try {
          await _saveTail;
        } catch (_) {
          /* Preserve the captured edit below. */
        }
        final old = controller.draft;
        if (old.uploadUncertain || old.submissionUncertain) return;
        await store.write(
          widget.ownerId,
          FeedbackDraft(
            ownerId: old.ownerId,
            submissionId: old.submissionId,
            kind: kind,
            detail: detail,
            contact: contact,
            pagePath: old.pagePath,
            assetIds: old.assetIds,
            assetNames: old.assetNames,
            uploadUncertain: false,
            submissionUncertain: false,
          ),
        );
        if (mounted) setState(() => _saveFailed = false);
      } catch (_) {
        if (mounted) setState(() => _saveFailed = true);
      } finally {
        _preserving = false;
        if (mounted) setState(() {});
      }
    }();
  }

  Future<void> _save() async {
    _saveTimer?.cancel();
    _saveTimer = null;
    if (_saveFailed) throw StateError('Draft save failed');
    try {
      await _enqueueSave();
    } catch (_) {
      _saveFailed = true;
      rethrow;
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy || _controller == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (failure) {
      if (mounted && failure is FeedbackConfirmedCleanupFailure) {
        _done = true;
        _error = (vi.app.feedback.daGuiThanhCong);
      } else if (mounted) {
        _error = failure is FormatException
            ? (failure.message == 'detail'
                  ? (vi.app.common.vuiLongNhap20)
                  : (vi.app.feedback.tepKhongHopLe))
            : failure is HttpFailure &&
                  failure.statusCode >= 400 &&
                  failure.statusCode < 500 &&
                  failure.statusCode != 408 &&
                  _controller?.draft.submissionUncertain == false
            ? (vi.app.feedback.mayChuTuChoi)
            : (vi.app.feedback.thaoTacChuaDuoc);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _add() => _run(() async {
    await _save();
    final file = await ref.read(feedbackFilePickerProvider)();
    if (file == null) return;
    if (!feedbackMediaMimes.contains(file.mime) ||
        file.length < 1 ||
        file.length >
            (file.mime.startsWith('video/')
                ? feedbackVideoLimit
                : feedbackImageLimit) ||
        file.name.isEmpty ||
        file.name.length > 255) {
      throw const FormatException();
    }
    await _controller!.attach(file);
  });

  Future<void> _close({bool openHistory = false}) async {
    if (_busy) return;
    await _preserveFuture;
    if (_done &&
        _controller != null &&
        !_ownerChanged &&
        _owner() == widget.ownerId) {
      try {
        await _controller!.clearConfirmed();
      } catch (_) {
        /* Keep the recovery marker. */
      }
    }
    if (_controller != null &&
        !_done &&
        !_saveFailed &&
        !_ownerChanged &&
        _owner() == widget.ownerId) {
      await _run(_save);
      if (_error != null) return;
    }
    if (mounted) Navigator.of(context).pop(openHistory);
  }

  Future<void> _restart() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text((vi.app.feedback.batDauBanNhap)),
        content: Text((vi.app.feedback.mayChuCoThe)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text((vi.common.huy)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text((vi.app.feedback.batDauLai)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _run(() async {
        await _save();
        await _controller!.restartAfterUnknownPresign();
      });
    }
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _detail.dispose();
    _contact.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(sessionStateProvider);
    ref.listen(sessionStateProvider, (previous, next) {
      if (previous?.userId == widget.ownerId &&
          next?.userId != widget.ownerId) {
        _ownerChanged = true;
        _preserveOriginalOwner();
      }
    });
    final draft = _controller?.draft;
    final locked =
        draft == null || draft.uploadUncertain || draft.submissionUncertain;
    final sessionChanged = _ownerChanged || _owner() != widget.ownerId;
    if (sessionChanged) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) _close();
        },
        child: AlertDialog(
          title: Text((vi.app.feedback.taiKhoanDaThay)),
          content: Text(
            _saveFailed
                ? (vi.app.feedback.khongTheLuuThay)
                : (vi.app.feedback.dongVaDangNhap),
          ),
          actions: [
            if (_saveFailed && _owner() == widget.ownerId)
              TextButton(
                onPressed: _preserving ? null : _preserveOriginalOwner,
                child: Text((vi.app.feedback.thuLuuLai)),
              ),
            TextButton(
              onPressed: _busy ? null : _close,
              child: Text((vi.common.dong)),
            ),
          ],
        ),
      );
    }
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _close();
      },
      child: AlertDialog(
        title: Text((vi.feedbackWidget.giupVnlfTotHon)),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_done) ...[
                  Text((vi.app.common.daGhiNhanPhan)),
                  if (_error != null) Text(_error!),
                ] else ...[
                  if (sessionChanged) Text((vi.app.feedback.taiKhoanDaThayDoi)),
                  DropdownButton<String>(
                    value: _kind,
                    isExpanded: true,
                    onChanged:
                        _busy ||
                            _saveFailed ||
                            locked ||
                            sessionChanged ||
                            draft.assetIds.isNotEmpty
                        ? null
                        : (value) {
                            setState(() => _kind = value!);
                            _scheduleSave();
                          },
                    items: [
                      DropdownMenuItem(
                        value: 'FEEDBACK',
                        child: Text((vi.feedbackWidget.gopY)),
                      ),
                      DropdownMenuItem(
                        value: 'BUG',
                        child: Text((vi.feedbackWidget.baoLoi)),
                      ),
                    ],
                  ),
                  TextField(
                    controller: _detail,
                    readOnly: _busy || locked || sessionChanged || _saveFailed,
                    onChanged: (_) => _scheduleSave(),
                    maxLines: 4,
                    maxLength: 4000,
                    decoration: InputDecoration(
                      labelText: (vi.app.feedback.moTa204000),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text((vi.feedbackWidget.tepDinhKem2)),
                  Text((vi.app.feedback.toiDa5Tep)),
                  if (draft != null)
                    for (final id in draft.assetIds)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          draft.assetNames[id] ??
                              (vi.feedbackWidget.tepDinhKem2),
                        ),
                        subtitle: draft.pendingAssetId == id
                            ? Text((vi.app.feedback.chuaXacNhanHay))
                            : null,
                        trailing: IconButton(
                          tooltip: (vi.app.feedback.xoaTep),
                          onPressed:
                              _busy ||
                                  _saveFailed ||
                                  sessionChanged ||
                                  draft.submissionUncertain ||
                                  (draft.uploadUncertain &&
                                      draft.pendingAssetId != null &&
                                      draft.pendingAssetId != id)
                              ? null
                              : () => _run(() async {
                                  await _save();
                                  await _controller!.deleteAsset(id);
                                }),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ),
                  if (draft?.uploadUncertain == true &&
                      draft?.pendingAssetId == null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text((vi.app.feedback.khongXacNhanDuoc)),
                        TextButton(
                          onPressed:
                              _busy ||
                                  _saveFailed ||
                                  sessionChanged ||
                                  draft!.assetIds.isNotEmpty
                              ? null
                              : _restart,
                          child: Text((vi.app.feedback.batDauBanNhapMoi)),
                        ),
                      ],
                    ),
                  if (draft?.submissionUncertain == true)
                    Text((vi.app.feedback.chuaXacNhanDuoc)),
                  OutlinedButton.icon(
                    onPressed:
                        _busy ||
                            _saveFailed ||
                            locked ||
                            sessionChanged ||
                            draft.assetIds.length >= 5
                        ? null
                        : _add,
                    icon: const Icon(Icons.attach_file),
                    label: Text((vi.app.feedback.themTep)),
                  ),
                  if (_busy) const LinearProgressIndicator(),
                  if (_saveFailed)
                    Text(
                      (vi.app.feedback.khongLuuDuocBan),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  if (_error != null)
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: _busy || _saveFailed
                ? null
                : () => _close(openHistory: true),
            icon: const Icon(Icons.history),
            label: Text((vi.app.common.gopYCuaToi)),
          ),
          TextButton(
            onPressed: _busy ? null : _close,
            child: Text((vi.common.dong)),
          ),
          if (!_done)
            FilledButton(
              onPressed:
                  _busy ||
                      _saveFailed ||
                      draft == null ||
                      draft.uploadUncertain ||
                      sessionChanged
                  ? null
                  : () => _run(() async {
                      if (_detail.text.trim().length < 20 ||
                          _detail.text.trim().length > 4000) {
                        throw const FormatException('detail');
                      }
                      await _save();
                      await _controller!.submit();
                      if (mounted) _done = true;
                    }),
              child: Text(
                draft?.submissionUncertain == true
                    ? (vi.miscViews.guiLai)
                    : (vi.feedbackWidget.guiChoVnlf),
              ),
            ),
        ],
      ),
    );
  }
}
