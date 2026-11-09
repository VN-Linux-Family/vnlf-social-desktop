import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../design_system/design_system.dart';
import '../../../core/api_client.dart';
import '../../../i18n/vi.dart';
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
    if (_openingUserId == null ||
        ref.read(sessionStateProvider)?.userId != _openingUserId) {
      return false;
    }
    try {
      _openingSession.ensureCurrent();
      return true;
    } catch (_) {
      return false;
    }
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

  Future<void> _submit() async {
    if (_busy) return;
    if (!_isOpeningSession()) {
      setState(() => _error = vi.app.moderation.taiKhoanDaThay);
      return;
    }
    if (_reason.text.trim().isEmpty) {
      setState(() => _error = vi.app.moderation.vuiLongNhapLy);
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
      if (mounted &&
          ref.read(sessionStateProvider)?.userId == account &&
          _isOpeningSession()) {
        setState(() => _confirmed = true);
      }
    } catch (_) {
      if (mounted && _isOpeningSession()) {
        setState(() => _error = vi.app.moderation.khongGuiDuocBao);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        _confirmed
            ? vi.app.moderation.daNhanBaoCao
            : vi.app.moderation.baoCaoNoiDung,
      ),
      content: _confirmed
          ? Text(vi.app.moderation.doiNguKiemDuyet)
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
                        labelText: vi.socialOverlays.lyDo,
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
                        labelText: vi.app.moderation.chiTietKhongBat,
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
          child: Text(_confirmed ? vi.app.moderation.hoanTat : vi.common.huy),
        ),
        if (!_confirmed)
          FilledButton(
            onPressed: _busy ? null : () => _submit(),
            child: _busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(vi.socialOverlays.guiBaoCao),
          ),
      ],
    );
  }
}
