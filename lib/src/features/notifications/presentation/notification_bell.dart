import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../design_system/design_system.dart';
import '../../../i18n/vi.dart';
import 'notification_center.dart';
import 'notifications_controller.dart';

/// Opens the notification center under the [bell], as the website's
/// `NotificationBell` does at every width. Guests go to sign in.
Future<void> showNotificationsPopover(
  BuildContext context,
  WidgetRef ref,
  Rect bell,
) async {
  if (ref.read(sessionStateProvider) == null) {
    unawaited(context.push('/login'));
    return;
  }
  final media = MediaQuery.of(context);
  // On phones the panel hangs 10px under the 54px header, 8px from each
  // side; wider, it hangs 10px under the bell, right edges aligned.
  final anchor = media.size.width < 841
      ? Rect.fromLTRB(bell.left, bell.top, bell.right, media.padding.top + 54)
      : bell;
  final top = anchor.bottom + 10;
  await showVnlfPopover<void>(
    context,
    anchor: anchor,
    label: vi.common.thongBao,
    width: 400,
    gap: 10,
    padding: EdgeInsets.zero,
    maxHeight: math.min(media.size.height - 110, media.size.height - 8 - top),
    builder: (popover) => NotificationCenter(
      compact: true,
      onClose: () => Navigator.of(popover).pop(),
    ),
  );
  ref.invalidate(notificationBadgeCountProvider);
}

/// The 40px bell of the website's top bar, with the unseen count.
class NotificationBellBox extends ConsumerWidget {
  const NotificationBellBox({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => VnlfHeaderIconBox(
    icon: VnlfLucide.bell,
    iconSize: 20,
    muted: false,
    tooltip: vi.common.thongBao,
    badgeCount: ref.watch(notificationBadgeCountProvider).valueOrNull ?? 0,
    onPressed: () {
      final box = context.findRenderObject()! as RenderBox;
      unawaited(
        showNotificationsPopover(
          context,
          ref,
          box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    },
  );
}
