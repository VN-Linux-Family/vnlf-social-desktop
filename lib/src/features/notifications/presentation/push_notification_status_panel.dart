import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/design_system.dart';
import '../domain/push_subscription_models.dart';
import 'push_notifications_providers.dart';

class PushNotificationStatusPanel extends ConsumerWidget {
  const PushNotificationStatusPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = VnlfColors.of(context);
    final english = Localizations.localeOf(context).languageCode == 'en';
    final regState = ref.watch(pushRegistrationControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          english ? 'Web Push (VAPID)' : 'Thông báo đẩy Web Push (VAPID)',
          style: VnlfTypography.h2(colors.ink),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildStatusIcon(regState.phase, colors),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _buildStatusTitle(regState.phase, english),
                      style: VnlfTypography.control(
                        colors.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (regState.phase == PushRegistrationPhase.checking)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    IconButton(
                      icon: Icon(Icons.refresh, size: 20, color: colors.muted),
                      tooltip: english
                          ? 'Refresh / Re-register'
                          : 'Đăng ký lại',
                      onPressed: () => ref
                          .read(pushRegistrationControllerProvider.notifier)
                          .registerDevice(force: true),
                    ),
                ],
              ),
              if (regState.endpoint != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Endpoint: ${Uri.tryParse(regState.endpoint ?? '')?.host ?? regState.endpoint}',
                  style: VnlfTypography.meta(colors.muted),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (regState.errorMessage != null) ...[
                const SizedBox(height: 6),
                Text(
                  regState.errorMessage!,
                  style: VnlfTypography.meta(colors.red),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusIcon(PushRegistrationPhase phase, VnlfColors colors) {
    switch (phase) {
      case PushRegistrationPhase.registered:
        return Icon(Icons.check_circle_outline, color: colors.brand, size: 20);
      case PushRegistrationPhase.checking:
        return Icon(Icons.sync, color: colors.muted, size: 20);
      case PushRegistrationPhase.disabled:
        return Icon(Icons.info_outline, color: colors.muted, size: 20);
      case PushRegistrationPhase.failed:
        return Icon(Icons.error_outline, color: colors.red, size: 20);
      case PushRegistrationPhase.idle:
        return Icon(Icons.notifications_none, color: colors.muted, size: 20);
    }
  }

  String _buildStatusTitle(PushRegistrationPhase phase, bool english) {
    switch (phase) {
      case PushRegistrationPhase.registered:
        return english
            ? 'Device subscribed to server push'
            : 'Đã đăng ký nhận thông báo đẩy từ máy chủ';
      case PushRegistrationPhase.checking:
        return english
            ? 'Checking push subscription...'
            : 'Đang kiểm tra đăng ký thông báo...';
      case PushRegistrationPhase.disabled:
        return english
            ? 'Web Push disabled on server'
            : 'Máy chủ chưa kích hoạt Web Push';
      case PushRegistrationPhase.failed:
        return english
            ? 'Push subscription failed'
            : 'Không thể đăng ký thông báo đẩy';
      case PushRegistrationPhase.idle:
        return english
            ? 'Push subscription inactive'
            : 'Chưa đăng ký thông báo đẩy';
    }
  }
}
