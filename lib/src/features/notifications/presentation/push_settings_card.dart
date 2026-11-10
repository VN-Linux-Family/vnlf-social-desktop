import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/design_system.dart';
import '../../../i18n/vi.dart';
import 'push_settings_controller.dart';

/// The website's "Thông báo đẩy" card (`PushSettings`): what push does, a
/// button that turns it on or off at once, a test while it is on, and the
/// result of the last press.
class PushSettingsCard extends ConsumerWidget {
  const PushSettingsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pushSettingsProvider);
    final controller = ref.read(pushSettingsProvider.notifier);
    final colors = VnlfColors.of(context);
    final phone =
        VnlfViewportSize.fromWidth(MediaQuery.sizeOf(context).width) ==
        VnlfViewportSize.mobile;
    final muted = VnlfTypography.body(colors.muted);
    final config = state.config;
    final statuses = [
      if (!state.supported) vi.app.notifications.thietBiChuaHoTroDay,
      if (state.loadFailed) vi.pushSettings.chuaKiemTraDuocThong,
      if (config != null && !config.enabled && !state.enabled)
        vi.pushSettings.mayChuChuaCauHinh,
      ?state.status,
    ];
    return Semantics(
      container: true,
      label: vi.pushSettings.thongBaoTrenThietBi,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border.all(color: colors.line),
          borderRadius: BorderRadius.circular(
            phone ? VnlfDimensions.radiusMd : VnlfDimensions.radiusLg,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(phone ? 12 : 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                vi.pushSettings.thongBaoTrenThietBi,
                style: VnlfTypography.h3(colors.ink),
              ),
              const SizedBox(height: 5),
              Text(vi.app.notifications.dayMoTa, style: muted),
              const SizedBox(height: 8),
              Text(vi.app.notifications.dayCanUnifiedPush, style: muted),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _OutlineButton(
                    label: state.busy
                        ? vi.common.dangXuLy
                        : state.enabled
                        ? vi.pushSettings.tatThongBaoThietBi
                        : vi.pushSettings.batThongBaoThietBi,
                    onPressed: state.canToggle ? controller.toggle : null,
                  ),
                  if (state.enabled)
                    _OutlineButton(
                      label: vi.pushSettings.guiThongBaoThu,
                      onPressed: state.busy ? null : controller.test,
                    ),
                ],
              ),
              for (final status in statuses)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(status, style: VnlfTypography.body(colors.ink)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The website's `button-outline`, 44px tall as on the push card.
class _OutlineButton extends StatelessWidget {
  const _OutlineButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final radius = BorderRadius.circular(VnlfDimensions.radiusMd);
    return Semantics(
      button: true,
      enabled: onPressed != null,
      child: Material(
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: colors.line),
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: onPressed,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      style: VnlfTypography.control(
                        onPressed == null ? colors.muted : colors.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
