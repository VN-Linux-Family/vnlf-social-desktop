import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../design_system/design_system.dart';
import '../../../core/api_client.dart';
import '../data/live_report_repository.dart';
import '../domain/report_repository.dart';

final reportRepositoryProvider = Provider<ReportRepository>(
  (ref) => LiveReportRepository(ref.watch(apiClientProvider)),
);

Future<void> showArticleReport(
  BuildContext context,
  WidgetRef ref,
  String id,
) async {
  if (ref.read(sessionStateProvider) == null) {
    context.push('/login');
    return;
  }
  await showDialog<void>(
    context: context,
    builder: (_) => ReportDialog(targetId: id),
  );
}

class ReportDialog extends ConsumerStatefulWidget {
  const ReportDialog({
    super.key,
    required this.targetId,
    this.targetType = 'ARTICLE',
  });
  final String targetId;
  final String targetType;
  @override
  ConsumerState<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends ConsumerState<ReportDialog> {
  late final String? _openingUserId;
  late final ApiSessionScope _openingSession;

  @override
  void initState() {
    super.initState();
    _openingUserId = ref.read(sessionStateProvider)?.userId;
    _openingSession = ref.read(apiClientProvider).captureSession();
  }

  bool _isOpeningSession() {
    if (_openingUserId == null || ref.read(sessionStateProvider)?.userId != _openingUserId) return false;
    try { _openingSession.ensureCurrent(); return true; } catch (_) { return false; }
  }

  final _reason = TextEditingController();
  final _detail = TextEditingController();
  bool _busy = false;
  bool _confirmed = false;
  String? _error;
  @override
  void dispose() {
    _reason.dispose();
    _detail.dispose();
    super.dispose();
  }

  Future<void> _submit(bool english) async {
    if (_busy) return;
    if (!_isOpeningSession()) {
      setState(() => _error = english ? 'Your account changed. Close this report and open it again.' : 'Tài khoản đã thay đổi. Hãy đóng và mở lại báo cáo.');
      return;
    }
    if (_reason.text.trim().isEmpty) {
      setState(
        () => _error = english ? 'Enter a reason.' : 'Vui lòng nhập lý do.',
      );
      return;
    }
    final account = ref.read(sessionStateProvider)?.userId;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(reportRepositoryProvider)
          .submit(
            targetId: widget.targetId,
            targetType: widget.targetType,
            reason: _reason.text,
            detail: _detail.text,
          );
      if (mounted && ref.read(sessionStateProvider)?.userId == account && _isOpeningSession()) {
        setState(() => _confirmed = true);
      }
    } catch (_) {
      if (mounted && _isOpeningSession()) {
        setState(
          () => _error = english
              ? 'Could not send report. Your draft is kept; try again.'
              : 'Không gửi được báo cáo. Bản nháp vẫn được giữ; vui lòng thử lại.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final english = Localizations.localeOf(context).languageCode == 'en';
    return AlertDialog(
      title: Text(
        _confirmed
            ? (english ? 'Report received' : 'Đã nhận báo cáo')
            : (english ? 'Report content' : 'Báo cáo nội dung'),
      ),
      content: _confirmed
          ? Text(
              english
                  ? 'The moderation team will review your report.'
                  : 'Đội ngũ kiểm duyệt sẽ xem xét báo cáo của bạn.',
            )
          : SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      key: const Key('report-reason'),
                      controller: _reason,
                      enabled: !_busy,
                      maxLength: 60,
                      decoration: InputDecoration(
                        labelText: english ? 'Reason' : 'Lý do',
                      ),
                    ),
                    TextField(
                      key: const Key('report-detail'),
                      controller: _detail,
                      enabled: !_busy,
                      maxLength: 2000,
                      minLines: 3,
                      maxLines: 6,
                      decoration: InputDecoration(
                        labelText: english
                            ? 'Details (optional)'
                            : 'Chi tiết (không bắt buộc)',
                      ),
                    ),
                    if (_error != null)
                      Text(
                        _error!,
                        style: TextStyle(color: VnlfColors.of(context).red),
                      ),
                  ],
                ),
              ),
            ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: Text(
            _confirmed
                ? (english ? 'Done' : 'Hoàn tất')
                : (english ? 'Cancel' : 'Hủy'),
          ),
        ),
        if (!_confirmed)
          FilledButton(
            onPressed: _busy ? null : () => _submit(english),
            child: _busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(english ? 'Send report' : 'Gửi báo cáo'),
          ),
      ],
    );
  }
}
