import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../design_system/design_system.dart';
import '../../shared/presentation/author_mapper.dart';
import '../domain/direct_message_models.dart';
import 'direct_message_feedback.dart';
import 'direct_message_panels.dart';
import 'direct_message_state.dart';

class DirectMessageInbox extends ConsumerStatefulWidget {
  const DirectMessageInbox({super.key, this.onSelected});

  final VoidCallback? onSelected;

  @override
  ConsumerState<DirectMessageInbox> createState() => _DirectMessageInboxState();
}

class _DirectMessageInboxState extends ConsumerState<DirectMessageInbox> {
  String _filterQuery = '';

  @override
  Widget build(BuildContext context) {
    if (ref.watch(sessionStateProvider) == null) {
      return const SizedBox.shrink();
    }
    final inbox = ref.watch(dmInboxProvider);
    final selectedId = ref.watch(selectedDmConversationIdProvider);
    final activeTab = ref.watch(dmInboxTabProvider);
    final colors = VnlfColors.of(context);

    final requestsCount = inbox.incomingRequests.length;
    final baseItems = activeTab == DmInboxTab.requests
        ? inbox.incomingRequests
        : inbox.conversations;
    final normalizedFilter = _filterQuery.trim().toLowerCase();
    final filtered = normalizedFilter.isEmpty
        ? baseItems
        : baseItems
              .where(
                (item) =>
                    item.peer.displayName.toLowerCase().contains(
                      normalizedFilter,
                    ) ||
                    item.peer.username.toLowerCase().contains(normalizedFilter),
              )
              .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
          title: Text(
            dmText(context, 'Hộp thư đến', 'Inbox'),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              IconButton(
                key: const Key('dm-new-conversation-button'),
                tooltip: dmText(context, 'Trò chuyện mới', 'New conversation'),
                onPressed: inbox.openingConversation
                    ? null
                    : () => showNewDmDialog(context, ref),
                icon: const Icon(Icons.add_comment_outlined, size: 20),
              ),
              IconButton(
                key: const Key('dm-refresh-inbox-button'),
                tooltip: dmText(
                  context,
                  'Làm mới danh sách',
                  'Refresh conversations',
                ),
                onPressed: inbox.loading
                    ? null
                    : () {
                        ref.read(apiClientProvider).clearCache();
                        ref.read(dmInboxProvider.notifier).load(refresh: true);
                      },
                icon: const Icon(Icons.refresh, size: 20),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: <Widget>[
              Expanded(
                child: ChoiceChip(
                  key: const Key('dm-tab-all'),
                  selected: activeTab == DmInboxTab.all,
                  showCheckmark: false,
                  label: Text(
                    inbox.totalUnreadCount > 0
                        ? '${dmText(context, 'Tất cả', 'All')} (${inbox.totalUnreadCount})'
                        : dmText(context, 'Tất cả', 'All'),
                  ),
                  onSelected: (_) =>
                      ref.read(dmInboxTabProvider.notifier).state =
                          DmInboxTab.all,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  key: const Key('dm-tab-requests'),
                  selected: activeTab == DmInboxTab.requests,
                  showCheckmark: false,
                  label: Text(
                    requestsCount > 0
                        ? '${dmText(context, 'Yêu cầu', 'Requests')} ($requestsCount)'
                        : dmText(context, 'Yêu cầu', 'Requests'),
                  ),
                  onSelected: (_) =>
                      ref.read(dmInboxTabProvider.notifier).state =
                          DmInboxTab.requests,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
          child: TextField(
            key: const Key('dm-inbox-filter'),
            onChanged: (value) => setState(() => _filterQuery = value),
            decoration: InputDecoration(
              isDense: true,
              prefixIcon: const Icon(Icons.search, size: 18),
              hintText: dmText(
                context,
                'Lọc theo tên hoặc @username...',
                'Filter by name or @username...',
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(VnlfDimensions.radiusMd),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
            ),
          ),
        ),
        if (inbox.actionFailure != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Text(
              dmFailureMessage(context, inbox.actionFailure, mutation: true),
              style: TextStyle(color: colors.red, fontSize: 12),
            ),
          ),
        Expanded(
          child: inbox.loading && !inbox.loaded
              ? const Center(child: CircularProgressIndicator())
              : inbox.failure != null && inbox.conversations.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        dmFailureMessage(context, inbox.failure),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () {
                          ref.read(apiClientProvider).clearCache();
                          ref
                              .read(dmInboxProvider.notifier)
                              .load(refresh: true);
                        },
                        child: Text(dmText(context, 'Thử lại', 'Try again')),
                      ),
                    ],
                  ),
                )
              : filtered.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      activeTab == DmInboxTab.requests
                          ? dmText(
                              context,
                              'Không có yêu cầu nhắn tin đang chờ.',
                              'No pending message requests.',
                            )
                          : dmText(
                              context,
                              'Chưa có cuộc trò chuyện nào.',
                              'No conversations yet.',
                            ),
                      textAlign: TextAlign.center,
                      style: VnlfTypography.body(colors.muted),
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final conversation = filtered[index];
                    return _DmConversationTile(
                      key: ValueKey('dm-conversation-${conversation.id}'),
                      conversation: conversation,
                      selected: conversation.id == selectedId,
                      onTap: () {
                        ref
                                .read(selectedDmConversationIdProvider.notifier)
                                .state =
                            conversation.id;
                        widget.onSelected?.call();
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _DmConversationTile extends StatelessWidget {
  const _DmConversationTile({
    super.key,
    required this.conversation,
    required this.selected,
    required this.onTap,
  });

  final DmConversation conversation;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final peerAuthor = presentAuthor(conversation.peer.toAuthor());
    final subtitle = _subtitleText(context, conversation);

    return ListTile(
      selected: selected,
      selectedTileColor: colors.brandSoft,
      leading: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          VnlfAvatar(
            author: peerAuthor,
            size: 38,
            semanticLabel: conversation.peer.displayName,
          ),
          if (conversation.peer.isOnline)
            Positioned(
              right: -1,
              bottom: -1,
              child: Container(
                width: 11,
                height: 11,
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E),
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.surface, width: 2),
                ),
              ),
            ),
        ],
      ),
      title: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              conversation.peer.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (conversation.updatedAt != null)
            Text(
              formatDmTimestamp(conversation.updatedAt),
              style: VnlfTypography.meta(colors.muted),
            ),
        ],
      ),
      subtitle: Text(
        subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: VnlfTypography.caption(
          conversation.unreadCount > 0 ? colors.ink : colors.muted,
        ),
      ),
      trailing: conversation.unreadCount > 0
          ? Badge(label: Text('${conversation.unreadCount}'))
          : null,
      onTap: onTap,
    );
  }

  String _subtitleText(BuildContext context, DmConversation item) {
    if (item.isBlockedByMe) {
      return dmText(context, 'Đã chặn', 'Blocked');
    }
    if (item.isIncomingRequest) {
      return item.lastMessage?.isNotEmpty == true
          ? item.lastMessage!
          : dmText(context, 'Yêu cầu nhắn tin mới', 'New message request');
    }
    if (item.isAwaitingAcceptance) {
      return item.lastMessage?.isNotEmpty == true
          ? item.lastMessage!
          : dmText(context, 'Đang chờ chấp nhận', 'Awaiting acceptance');
    }
    if (item.requiresNewRequest) {
      return dmText(context, 'Cần gửi yêu cầu mới', 'Request required');
    }
    if (item.lastMessage != null && item.lastMessage!.trim().isNotEmpty) {
      return item.lastMessage!;
    }
    return item.peer.username.isNotEmpty ? '@${item.peer.username}' : '';
  }
}
