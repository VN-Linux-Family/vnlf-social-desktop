import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../design_system/design_system.dart';
import '../../../i18n/vi.dart';
import '../../notifications/presentation/notification_bell.dart';
import 'session_avatar.dart';

/// The buttons at the right of the website's desktop page header: search,
/// the notification bell, and the viewer's avatar (or sign-in).
class PageHeaderActions extends ConsumerWidget {
  const PageHeaderActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session =
        ref.watch(sessionStateProvider) ??
        ref.watch(sessionProvider).valueOrNull;
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 10,
      children: [
        VnlfHeaderIconBox(
          icon: VnlfLucide.search,
          tooltip: vi.common.timKiem,
          onPressed: () => context.push('/search'),
        ),
        const NotificationBellBox(),
        Semantics(
          button: true,
          label: session == null ? vi.common.dangNhap : session.displayName,
          child: InkWell(
            borderRadius: BorderRadius.circular(VnlfDimensions.radiusMd),
            onTap: () => context.push(
              session == null
                  ? '/login'
                  : '/profile/${Uri.encodeComponent(session.username)}',
            ),
            child: sessionAvatar(
              session,
              size: 40,
              cornerRadius: VnlfDimensions.radiusMd,
            ),
          ),
        ),
      ],
    );
  }
}
