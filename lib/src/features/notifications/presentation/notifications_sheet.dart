import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/vnlf_navigation_helper.dart';
import '../../../design_system/design_system.dart';
import '../../../i18n/vi.dart';
import '../domain/notifications_repository.dart';
import 'notice_copy.dart';
import 'notifications_controller.dart';

class NotificationsSheet extends ConsumerWidget {
  const NotificationsSheet({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signedIn = ref.watch(sessionStateProvider) != null;
    final state = ref.watch(notificationsControllerProvider);
    final controller = ref.read(notificationsControllerProvider.notifier);
    final router = GoRouter.of(context);
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .8,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      vi.common.thongBao,
                      style: VnlfTypography.h2(VnlfColors.of(context).ink),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    tooltip: vi.common.dong,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              if (!signedIn)
                Expanded(
                  child: Center(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(context);
                        router.push('/login');
                      },
                      child: Text(vi.app.notifications.dangNhapDeXem),
                    ),
                  ),
                )
              else ...[
                Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: Text(vi.notificationCenter.chuaDoc),
                      selected: state.unreadOnly,
                      onSelected: state.loading || state.busy
                          ? null
                          : (value) => controller.refresh(unreadOnly: value),
                    ),
                    SizedBox(
                      width: 170,
                      child: DropdownButton<NotificationKind>(
                        isExpanded: true,
                        value: state.kind,
                        items: [
                          DropdownMenuItem(
                            value: NotificationKind.all,
                            child: Text(
                              vi.app.notifications.moiLoai,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          DropdownMenuItem(
                            value: NotificationKind.like,
                            child: Text(
                              vi.notificationCenter.luotThich,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          DropdownMenuItem(
                            value: NotificationKind.comment,
                            child: Text(
                              vi.common.binhLuan,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          DropdownMenuItem(
                            value: NotificationKind.follow,
                            child: Text(
                              vi.common.theoDoi,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          DropdownMenuItem(
                            value: NotificationKind.system,
                            child: Text(
                              vi.notificationCenter.heThong,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                        onChanged: state.loading || state.busy
                            ? null
                            : (kind) {
                                if (kind != null) {
                                  controller.refresh(kind: kind);
                                }
                              },
                      ),
                    ),
                    TextButton(
                      onPressed:
                          state.busy || state.loading || state.unreadCount == 0
                          ? null
                          : controller.markAllRead,
                      child: Text(vi.app.notifications.danhDauDaDoc),
                    ),
                    IconButton(
                      onPressed: state.loading || state.busy
                          ? null
                          : controller.refresh,
                      tooltip: vi.app.common.lamMoi,
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
                if (state.failure != null)
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          vi.app.notifications.khongThucHienDuoc,
                          style: TextStyle(color: VnlfColors.of(context).red),
                        ),
                      ),
                      TextButton(
                        onPressed: state.loading || state.busy
                            ? null
                            : controller.refresh,
                        child: Text(vi.common.thuLai),
                      ),
                    ],
                  ),
                if (state.loading) const LinearProgressIndicator(),
                Expanded(
                  child:
                      state.items.isEmpty &&
                          !state.loading &&
                          state.failure == null
                      ? Center(child: Text(vi.app.notifications.chuaCoThongBao))
                      : ListView.builder(
                          itemCount:
                              state.items.length +
                              (state.nextCursor == null ? 0 : 1),
                          itemBuilder: (context, index) {
                            if (index == state.items.length) {
                              return TextButton(
                                onPressed: state.loading
                                    ? null
                                    : controller.loadMore,
                                child: Text(vi.app.notifications.taiThem),
                              );
                            }
                            final item = state.items[index];
                            return ListTile(
                              leading: Icon(
                                item.unread
                                    ? Icons.notifications_active_outlined
                                    : Icons.notifications_none,
                                color: item.unread
                                    ? VnlfColors.of(context).brand
                                    : null,
                              ),
                              title: Text(
                                [
                                  if (item.actor.displayName.isNotEmpty)
                                    item.actor.displayName,
                                  noticeAction(item.type),
                                ].join(' · '),
                                style: TextStyle(
                                  fontWeight: item.unread
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                ),
                              ),
                              subtitle: Text(
                                [
                                  item.title,
                                  item.excerpt,
                                ].where((s) => s.isNotEmpty).join('\n'),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: state.busy
                                  ? null
                                  : () async {
                                      if (item.unread) {
                                        await controller.markRead(item.id);
                                      }
                                      if (!context.mounted ||
                                          ref
                                                  .read(
                                                    notificationsControllerProvider,
                                                  )
                                                  .failure !=
                                              null) {
                                        return;
                                      }
                                      final route = noticeRoute(item);
                                      if (route != null) {
                                        Navigator.pop(context);
                                        router.push(route);
                                        return;
                                      }
                                      final opened = await openVnlfLink(
                                        context,
                                        item.href,
                                      );
                                      if (!opened && context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  vi
                                                      .app
                                                      .notifications
                                                      .khongMoDuocThong,
                                                ),
                                              ),
                                            );
                                      }
                                    },
                            );
                          },
                        ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
