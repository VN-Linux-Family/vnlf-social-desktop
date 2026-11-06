import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/providers.dart';
import '../../../design_system/design_system.dart';
import '../domain/notifications_repository.dart';
import 'notifications_controller.dart';

class NotificationsSheet extends ConsumerWidget {
  const NotificationsSheet({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final english = Localizations.localeOf(context).languageCode == 'en';
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
                      english ? 'Notifications' : 'Thông báo',
                      style: VnlfTypography.h2(VnlfColors.of(context).ink),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    tooltip: english ? 'Close' : 'Đóng',
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
                      child: Text(
                        english
                            ? 'Sign in to view notifications'
                            : 'Đăng nhập để xem thông báo',
                      ),
                    ),
                  ),
                )
              else ...[
                Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: Text(english ? 'Unread only' : 'Chưa đọc'),
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
                              english ? 'All types' : 'Mọi loại',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          DropdownMenuItem(
                            value: NotificationKind.like,
                            child: Text(
                              english ? 'Likes' : 'Lượt thích',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          DropdownMenuItem(
                            value: NotificationKind.comment,
                            child: Text(
                              english ? 'Comments' : 'Bình luận',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          DropdownMenuItem(
                            value: NotificationKind.follow,
                            child: Text(
                              english ? 'Follows' : 'Theo dõi',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          DropdownMenuItem(
                            value: NotificationKind.system,
                            child: Text(
                              english ? 'System' : 'Hệ thống',
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
                      child: Text(
                        english ? 'Mark all as read' : 'Đánh dấu đã đọc tất cả',
                      ),
                    ),
                    IconButton(
                      onPressed: state.loading || state.busy
                          ? null
                          : controller.refresh,
                      tooltip: english ? 'Refresh' : 'Làm mới',
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
                if (state.failure != null)
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          english
                              ? 'Could not complete the request. Try again.'
                              : 'Không thực hiện được yêu cầu. Vui lòng thử lại.',
                          style: TextStyle(color: VnlfColors.of(context).red),
                        ),
                      ),
                      TextButton(
                        onPressed: state.loading || state.busy
                            ? null
                            : controller.refresh,
                        child: Text(english ? 'Retry' : 'Thử lại'),
                      ),
                    ],
                  ),
                if (state.loading) const LinearProgressIndicator(),
                Expanded(
                  child:
                      state.items.isEmpty &&
                          !state.loading &&
                          state.failure == null
                      ? Center(
                          child: Text(
                            english ? 'No notifications' : 'Chưa có thông báo',
                          ),
                        )
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
                                child: Text(english ? 'Load more' : 'Tải thêm'),
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
                                  _action(item.type, english),
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
                                      final route = _route(item);
                                      if (route != null) {
                                        Navigator.pop(context);
                                        router.push(route);
                                        return;
                                      }
                                      final href = Uri.tryParse(item.href);
                                      if (href == null) return;
                                      final uri = Uri.parse(
                                        'https://vietnamlinuxfamily.net',
                                      ).resolveUri(href);
                                      if (uri.scheme == 'https' &&
                                          uri.host ==
                                              'vietnamlinuxfamily.net') {
                                        final opened = await launchUrl(
                                          uri,
                                          mode: LaunchMode.externalApplication,
                                        );
                                        if (!opened && context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                english
                                                    ? 'Could not open notification'
                                                    : 'Không mở được thông báo',
                                              ),
                                            ),
                                          );
                                        }
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

String? _route(CommunityNotice item) {
  if (item.targetType == 'ARTICLE' && item.targetId.isNotEmpty) {
    return '/thread/${Uri.encodeComponent(item.targetId)}';
  }
  if (item.targetType == 'USER' && item.actor.username.isNotEmpty) {
    return '/profile/${Uri.encodeComponent(item.actor.username)}';
  }
  if (item.targetType == 'CONVERSATION' && item.targetId.isNotEmpty) {
    return '/messages/${Uri.encodeComponent(item.targetId)}';
  }
  if (item.targetType == 'FEEDBACK' && item.targetId.isNotEmpty) {
    return '/feedback/${Uri.encodeComponent(item.targetId)}';
  }
  final href = Uri.tryParse(item.href);
  if (href != null &&
      !href.hasScheme &&
      !href.hasAuthority &&
      href.pathSegments.length == 2 &&
      href.pathSegments.first == 'projects' &&
      href.pathSegments.last.isNotEmpty &&
      href.path.startsWith('/')) {
    return '/projects/${Uri.encodeComponent(href.pathSegments.last)}';
  }
  return null;
}

String _action(String type, bool english) => switch (type) {
  'article-liked' => english ? 'Liked your post' : 'Đã thích bài viết của bạn',
  'comment-liked' =>
    english ? 'Liked your comment' : 'Đã thích bình luận của bạn',
  'comment-created' =>
    english ? 'Commented on your post' : 'Đã bình luận bài viết của bạn',
  'comment-replied' =>
    english ? 'Replied to your comment' : 'Đã trả lời bình luận của bạn',
  'user-followed' => english ? 'Started following you' : 'Đã theo dõi bạn',
  _ => english ? 'Community update' : 'Cập nhật cộng đồng',
};
