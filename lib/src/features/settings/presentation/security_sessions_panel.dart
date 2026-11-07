import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../design_system/design_system.dart';
import '../../shared/presentation/feature_widgets.dart';
import '../domain/security_sessions.dart';
import 'security_sessions_controller.dart';

class SecuritySessionsPanel extends ConsumerWidget {
  const SecuritySessionsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final en = Localizations.localeOf(context).languageCode == 'en';
    final colors = VnlfColors.of(context);
    final state = ref.watch(securitySessionsControllerProvider);
    final controller = ref.read(securitySessionsControllerProvider.notifier);
    return FeatureSurface(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(en ? 'Sessions' : 'Phiên đăng nhập', style: VnlfTypography.h2(colors.ink)),
      const SizedBox(height: 8),
      Text(en ? 'Devices signed in to your account' : 'Thiết bị đang đăng nhập vào tài khoản', style: VnlfTypography.meta(colors.muted)),
      if (state.loading) const LinearProgressIndicator(),
      if (state.failed || state.uncertain) ...[
        const SizedBox(height: 8),
        Text(state.uncertain ? (en ? 'The result could not be confirmed. Refresh before trying again.' : 'Chưa thể xác nhận kết quả. Hãy làm mới trước khi thử lại.') : (en ? 'Could not load sessions.' : 'Chưa tải được danh sách phiên đăng nhập.'), style: VnlfTypography.meta(colors.red)),
      ],
      for (final session in state.items ?? <SecuritySession>[])
        ListTile(contentPadding: EdgeInsets.zero,
          leading: Icon(session.current ? Icons.computer : Icons.devices_other),
          title: Text((session.deviceName?.isNotEmpty ?? false) ? session.deviceName! : ((session.userAgent?.isNotEmpty ?? false) ? session.userAgent! : (en ? 'Unknown device' : 'Thiết bị không xác định'))),
          subtitle: Text(session.lastSeenAt == null ? (en ? 'Last activity unknown' : 'Không rõ lần hoạt động cuối') : '${en ? 'Last active' : 'Hoạt động'}: ${MaterialLocalizations.of(context).formatMediumDate(session.lastSeenAt!.toLocal())} ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(session.lastSeenAt!.toLocal()))}'),
          trailing: session.current ? Text(en ? 'Current' : 'Hiện tại') : TextButton(onPressed: state.loading || state.uncertain ? null : () => _confirm(context, en, () => controller.revoke(session), false), child: Text(en ? 'Log out' : 'Đăng xuất'))),
      if (state.items?.any((s) => !s.current) ?? false)
        OutlinedButton(onPressed: state.loading || state.uncertain ? null : () => _confirm(context, en, () => controller.revoke(null), true), child: Text(en ? 'Log out other sessions' : 'Đăng xuất các phiên khác')),
      TextButton(onPressed: state.loading ? null : controller.refresh, child: Text(en ? 'Refresh' : 'Làm mới')),
    ]));
  }

  Future<void> _confirm(BuildContext context, bool en, Future<void> Function() action, bool all) async {
    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: Text(all ? (en ? 'Log out other sessions?' : 'Đăng xuất các phiên khác?') : (en ? 'Log out this device?' : 'Đăng xuất thiết bị này?')),
      content: Text(en ? 'You will need to sign in again on the affected devices.' : 'Bạn sẽ cần đăng nhập lại trên các thiết bị bị ảnh hưởng.'),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: Text(en ? 'Cancel' : 'Hủy')), FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(en ? 'Log out' : 'Đăng xuất'))],
    ));
    if (confirmed == true && context.mounted) await action();
  }
}
