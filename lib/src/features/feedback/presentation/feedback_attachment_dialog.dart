import 'dart:async';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/request_identity.dart';
import '../data/feedback_draft_controller.dart';
import '../data/feedback_draft_store.dart';
import '../data/feedback_media_repository.dart';
import '../domain/feedback_draft.dart';

final feedbackFilePickerProvider = Provider<Future<FeedbackMediaFile?> Function()>(
  (ref) => _pickFile,
);

Future<FeedbackMediaFile?> _pickFile() async {
  final file = await openFile(acceptedTypeGroups: const [
    XTypeGroup(label: 'Images and videos',
      extensions: ['jpg', 'jpeg', 'png', 'webp', 'gif', 'mp4', 'webm'],
      mimeTypes: ['image/jpeg', 'image/png', 'image/webp', 'image/gif', 'video/mp4', 'video/webm']),
  ]);
  if (file == null) return null;
  const mimes = {'jpg': 'image/jpeg', 'jpeg': 'image/jpeg', 'png': 'image/png',
    'webp': 'image/webp', 'gif': 'image/gif', 'mp4': 'video/mp4', 'webm': 'video/webm'};
  return FeedbackMediaFile(name: file.name,
    mime: file.mimeType ?? mimes[file.name.split('.').last.toLowerCase()] ?? '',
    length: await file.length(), openRead: file.openRead);
}

/// The caller prevents more than one dialog from being open at once.
class FeedbackAttachmentDialog extends ConsumerStatefulWidget {
  const FeedbackAttachmentDialog({super.key, required this.ownerId, required this.pagePath});
  final String ownerId;
  final String pagePath;

  @override
  ConsumerState<FeedbackAttachmentDialog> createState() => _FeedbackAttachmentDialogState();
}

class _FeedbackAttachmentDialogState extends ConsumerState<FeedbackAttachmentDialog> {
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
  bool get _en => Localizations.localeOf(context).languageCode == 'en';
  String _text(String vi, String en) => _en ? en : vi;

  String? _owner() => (ref.read(sessionStateProvider) ?? ref.read(sessionProvider).valueOrNull)?.userId;

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
        media: FeedbackMediaRepository(client), client: client,
        currentOwner: _owner,
        initial: FeedbackDraft(ownerId: widget.ownerId, submissionId: newRequestIdentity(),
          kind: 'FEEDBACK', detail: '', contact: '', pagePath: widget.pagePath,
          assetIds: [], uploadUncertain: false, submissionUncertain: false),
      );
      if (!mounted) return;
      _controller = controller;
      _detail.text = controller.draft.detail;
      _contact.text = controller.draft.contact;
      _kind = controller.draft.kind;
    } catch (_) {
      if (mounted) _error = _text('Không thể khôi phục bản nháp. Hãy kiểm tra tài khoản và bộ nhớ bảo mật.',
        'Could not restore the draft. Check your account and secure storage.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _enqueueSave() {
    final controller = _controller!;
    final kind = _kind;
    final detail = _detail.text;
    final contact = _contact.text;
    _saveTail = _saveTail.then((_) async {
      if (!controller.draft.submissionUncertain && !controller.draft.uploadUncertain) {
        await controller.edit(kind: kind, detail: detail,
          contact: contact, pagePath: controller.draft.pagePath);
      }
    });
    return _saveTail;
  }

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 400), () {
      _enqueueSave().then<void>((_) {}, onError: (Object _, StackTrace __) {
        if (mounted) setState(() => _saveFailed = true);
      });
    });
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
    setState(() { _busy = true; _error = null; });
    try {
      await action();
    } catch (failure) {
      if (mounted) _error = failure is FormatException
        ? (failure.message == 'detail'
          ? _text('Vui lòng nhập 20–4000 ký tự.', 'Enter 20–4000 characters.')
          : _text('Tệp không hợp lệ hoặc vượt quá giới hạn kích thước.',
              'The file is unsupported or exceeds the size limit.')) : _text(
        'Thao tác chưa được xác nhận. Bản nháp được giữ; kiểm tra trạng thái bên dưới.',
        'The operation was not confirmed. The draft is kept; check its status below.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _add() => _run(() async {
    await _save();
    final file = await ref.read(feedbackFilePickerProvider)();
    if (file == null) return;
    if (!feedbackMediaMimes.contains(file.mime) || file.length < 1 ||
        file.length > (file.mime.startsWith('video/') ? feedbackVideoLimit : feedbackImageLimit) ||
        file.name.isEmpty || file.name.length > 255) {
      throw const FormatException();
    }
    await _controller!.attach(file);
  });

  Future<void> _close() async {
    if (_busy) return;
    if (_controller != null && !_done && !_saveFailed && _owner() == widget.ownerId) {
      await _run(_save);
      if (_error != null) return;
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _restart() async {
    final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text(_text('Bắt đầu bản nháp mới?', 'Start a new draft?')),
      content: Text(_text(
        'Máy chủ có thể đã tạo một tệp không xác định. Không thể xóa tệp đó. Nội dung sẽ được giữ và bản nháp mới dùng mã khác.',
        'The server may have created an unidentified asset that cannot be deleted. Your text will be kept in a new draft with a new ID.')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(_text('Hủy', 'Cancel'))),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(_text('Bắt đầu lại', 'Start again'))),
      ],
    ));
    if (confirmed == true && mounted) await _run(() async {
      await _save();
      await _controller!.restartAfterUnknownPresign();
    });
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
    final draft = _controller?.draft;
    final locked = draft == null || draft.uploadUncertain || draft.submissionUncertain;
    final sessionChanged = _owner() != widget.ownerId;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) { if (!didPop) _close(); },
      child: AlertDialog(
        title: Text(_text('Giúp VNLF tốt hơn', 'Help Make VNLF Better')),
        content: SizedBox(width: 460, child: SingleChildScrollView(child: Column(
          mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_done) Text(_text('Đã ghi nhận phản hồi!', 'Feedback received!'))
            else ...[
              if (sessionChanged) Text(_text('Tài khoản đã thay đổi. Đóng và đăng nhập lại để tiếp tục.',
                'The account changed. Close and sign in again to continue.')),
              DropdownButton<String>(value: _kind, isExpanded: true,
                onChanged: _busy || _saveFailed || locked || sessionChanged || (draft?.assetIds.isNotEmpty ?? false)
                  ? null : (value) { setState(() => _kind = value!); _scheduleSave(); },
                items: [
                  DropdownMenuItem(value: 'FEEDBACK', child: Text(_text('Góp ý', 'Feedback'))),
                  DropdownMenuItem(value: 'BUG', child: Text(_text('Báo lỗi', 'Bug report'))),
                ]),
              TextField(controller: _detail, readOnly: _busy || locked || sessionChanged || _saveFailed,
                onChanged: (_) => _scheduleSave(),
                maxLines: 4, maxLength: 4000,
                decoration: InputDecoration(labelText: _text('Mô tả (20–4000 ký tự)', 'Description (20–4000 characters)'))),
              const SizedBox(height: 12),
              Text(_text('Tệp đính kèm', 'Attachments')),
              Text(_text('Tối đa 5 tệp. Ảnh tối đa 10 MiB; video MP4/WebM tối đa 50 MiB.',
                'Up to 5 files. Images: 10 MiB; MP4/WebM video: 50 MiB.')),
              if (draft != null) for (final id in draft.assetIds)
                ListTile(contentPadding: EdgeInsets.zero,
                  title: Text(draft.assetNames[id] ?? _text('Tệp đính kèm', 'Attachment')),
                  subtitle: draft.pendingAssetId == id
                    ? Text(_text('Chưa xác nhận; hãy xóa tệp này.', 'Unconfirmed; delete this attachment.')) : null,
                  trailing: IconButton(tooltip: _text('Xóa tệp', 'Delete attachment'),
                    onPressed: _busy || _saveFailed || sessionChanged || draft.submissionUncertain ||
                      (draft.uploadUncertain && draft.pendingAssetId != null && draft.pendingAssetId != id)
                      ? null : () => _run(() async { await _save(); await _controller!.deleteAsset(id); }),
                    icon: const Icon(Icons.delete_outline))),
              if (draft?.uploadUncertain == true && draft?.pendingAssetId == null)
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_text('Không xác nhận được yêu cầu tải lên. Một vị trí có thể đã được dùng; hãy xóa các tệp đã biết trước khi bắt đầu lại.',
                    'The upload request is unconfirmed. One slot may be used; delete known attachments before starting again.')),
                  TextButton(onPressed: _busy || _saveFailed || sessionChanged || draft!.assetIds.isNotEmpty ? null : _restart,
                    child: Text(_text('Bắt đầu bản nháp mới', 'Start a new draft'))),
                ]),
              if (draft?.submissionUncertain == true)
                Text(_text('Chưa xác nhận được kết quả gửi. Chỉ có thể gửi lại nội dung không thay đổi.',
                  'The submission result is unconfirmed. Only the unchanged submission can be retried.')),
              OutlinedButton.icon(onPressed: _busy || _saveFailed || locked || sessionChanged || (draft?.assetIds.length ?? 5) >= 5
                ? null : _add, icon: const Icon(Icons.attach_file),
                label: Text(_text('Thêm tệp', 'Add attachment'))),
              if (_busy) const LinearProgressIndicator(),
              if (_saveFailed) Text(_text(
                'Không lưu được bản nháp vào bộ nhớ bảo mật. Không thể tiếp tục gửi; sao chép nội dung trước khi đóng.',
                'The draft could not be saved to secure storage. Sending is disabled; copy your text before closing.'),
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
              if (_error != null) Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
          ],
        ))),
        actions: [
          TextButton(onPressed: _busy ? null : _close, child: Text(_text('Đóng', 'Close'))),
          if (!_done) FilledButton(onPressed: _busy || _saveFailed || draft == null || draft.uploadUncertain || sessionChanged
            ? null : () => _run(() async {
              if (_detail.text.trim().length < 20 || _detail.text.trim().length > 4000) {
                throw const FormatException('detail');
              }
              await _save(); await _controller!.submit(); if (mounted) _done = true;
            }),
            child: Text(draft?.submissionUncertain == true ? _text('Gửi lại', 'Retry') : _text('Gửi cho VNLF', 'Send feedback'))),
        ],
      ),
    );
  }
}
