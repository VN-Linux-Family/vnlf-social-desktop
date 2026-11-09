import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/models.dart';
import '../../../i18n/vi.dart';
import '../../channels/presentation/live_channel_state.dart';
import '../../direct_messages/domain/direct_message_models.dart';
import '../../direct_messages/presentation/direct_message_feedback.dart';
import '../../direct_messages/presentation/direct_message_panels.dart';
import '../../direct_messages/presentation/direct_message_state.dart';
import '../../shared/presentation/author_mapper.dart';
import 'communication_preferences.dart';

class CommunicationDirectory extends ConsumerStatefulWidget {
  const CommunicationDirectory({
    super.key,
    this.onSelected,
    this.activeChannelId,
    this.activeConversationId,
  });
  final String? activeChannelId;
  final String? activeConversationId;
  final VoidCallback? onSelected;
  @override
  ConsumerState<CommunicationDirectory> createState() =>
      _CommunicationDirectoryState();
}

class _CommunicationDirectoryState
    extends ConsumerState<CommunicationDirectory> {
  final _search = TextEditingController();
  final _pending = <String>{};
  final _answered = <String, DateTime?>{};
  final _failures = <String, AppFailure>{};
  int _ownerRevision = 0;
  @override
  void initState() {
    super.initState();
    _search.text = ref.read(communicationFilterProvider);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _navigate(String path) {
    final router = GoRouter.maybeOf(context);
    widget.onSelected?.call();
    router?.go(path);
  }

  Future<void> _answer(DmConversation conversation, bool accept) async {
    final owner = ref.read(sessionStateProvider)?.userId;
    if (owner == null || _pending.contains(conversation.id)) return;
    final revision = _ownerRevision;
    final repository = ref.read(directMessageRepositoryProvider);
    final inbox = ref.read(dmInboxProvider.notifier);
    setState(() {
      _pending.add(conversation.id);
      _failures.remove(conversation.id);
    });
    try {
      if (accept) {
        await repository.acceptRequest(conversation.id);
      } else {
        await repository.declineRequest(conversation.id);
      }
      if (!mounted || revision != _ownerRevision) return;
      setState(() => _answered[conversation.id] = conversation.updatedAt);
      await inbox.load(refresh: true);
    } catch (error) {
      if (mounted && revision == _ownerRevision) {
        setState(
          () => _failures[conversation.id] = error is AppFailure
              ? error
              : const TransportFailure(),
        );
      }
    } finally {
      if (mounted && revision == _ownerRevision) {
        setState(() => _pending.remove(conversation.id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final owner = ref.watch(sessionStateProvider);
    ref.listen(sessionStateProvider, (before, after) {
      if (before?.userId == after?.userId) return;
      _ownerRevision++;
      setState(() {
        _pending.clear();
        _answered.clear();
        _failures.clear();
      });
    });
    ref.listen(communicationFilterProvider, (before, after) {
      if (_search.text != after) _search.text = after;
    });
    if (owner == null) {
      return Center(
        child: TextButton(
          onPressed: () => _navigate('/login'),
          child: Text(vi.app.communication.dangNhapDeTro),
        ),
      );
    }
    final query = ref.watch(communicationFilterProvider).trim().toLowerCase();
    final collapsed = ref.watch(channelsCollapsedProvider);
    final channels = ref.watch(liveChannelsProvider);
    final inbox = ref.watch(dmInboxProvider);

    final sorted = [...?channels.valueOrNull]
      ..sort((a, b) => a.position.compareTo(b.position));
    final visibleChannels = sorted.where(
      (item) =>
          !item.isArchived &&
          (query.isEmpty ||
              item.name.toLowerCase().contains(query) ||
              item.slug.toLowerCase().contains(query)),
    );
    final conversations = inbox.conversations.where(
      (item) =>
          query.isEmpty ||
          item.peer.displayName.toLowerCase().contains(query) ||
          item.peer.username.toLowerCase().contains(query),
    );
    final showChannels = !collapsed || query.isNotEmpty;
    return ListView(
      padding: const EdgeInsets.all(10),
      children: [
        TextField(
          key: const Key('communication-search'),
          controller: _search,
          style: VnlfTypography.body(colors.ink),
          onChanged: (value) =>
              ref.read(communicationFilterProvider.notifier).state = value,
          decoration: InputDecoration(
            hintText: vi.app.communication.timKenhHoacNguoi,
            prefixIcon: const Icon(Icons.search, size: 18),
          ),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          key: const Key('communication-toggle-channels'),
          onPressed: () =>
              ref.read(channelsCollapsedProvider.notifier).toggle(),
          icon: Icon(
            showChannels ? Icons.expand_more : Icons.chevron_right,
            size: 18,
          ),
          label: Align(
            alignment: Alignment.centerLeft,
            child: Text(vi.app.communication.kenhCongDong),
          ),
        ),
        if (ref.watch(communicationPreferenceFailureProvider) != null)
          Text(
            vi.app.communication.khongLuuDuocLua,
            style: VnlfTypography.meta(colors.red),
          ),
        if (showChannels) ...[
          if (channels.isLoading) const LinearProgressIndicator(),
          if (channels.hasError)
            TextButton(
              onPressed: () => ref.invalidate(liveChannelsProvider),
              child: Text(vi.app.communication.khongTaiDuocKenh),
            ),
          for (final channel in visibleChannels)
            ListTile(
              key: ValueKey('communication-channel-${channel.id}'),
              contentPadding: const EdgeInsets.symmetric(horizontal: 6),
              selected: widget.activeChannelId == channel.id,
              selectedTileColor: colors.brandSoft,
              leading: Icon(
                channel.type == 'ANNOUNCEMENT'
                    ? Icons.campaign_outlined
                    : Icons.tag,
                size: 18,
              ),
              title: Text(
                channel.name.isEmpty ? channel.slug : channel.name,
                style: VnlfTypography.body(colors.ink),
              ),
              trailing: channel.unreadCount == 0
                  ? null
                  : Text(
                      '${channel.unreadCount}',
                      style: VnlfTypography.meta(colors.brand),
                    ),
              onTap: () {
                _navigate(
                  '/channels/${Uri.encodeComponent(channel.slug.isEmpty ? channel.id : channel.slug)}',
                );
              },
            ),
          if (!channels.isLoading &&
              !channels.hasError &&
              visibleChannels.isEmpty)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                vi.app.communication.khongCoKenhPhu,
                style: VnlfTypography.meta(colors.muted),
              ),
            ),
        ],
        Row(
          children: [
            Expanded(
              child: Text(
                vi.directMessageLiveView.tinNhanRieng,
                style: VnlfTypography.control(colors.muted),
              ),
            ),
            IconButton(
              tooltip: vi.app.communication.troChuyenMoi,
              onPressed: inbox.openingConversation
                  ? null
                  : () => showNewDmDialog(context, ref),
              icon: const Icon(Icons.add_comment_outlined, size: 18),
            ),
            IconButton(
              tooltip: vi.app.communication.lamMoiHopThu,
              onPressed: inbox.loading
                  ? null
                  : () =>
                        ref.read(dmInboxProvider.notifier).load(refresh: true),
              icon: const Icon(Icons.refresh, size: 18),
            ),
          ],
        ),
        if (inbox.loading) const LinearProgressIndicator(),
        if (inbox.failure != null || inbox.actionFailure != null)
          Text(
            dmFailureMessage(context, inbox.actionFailure ?? inbox.failure),
            style: VnlfTypography.meta(colors.red),
          ),
        for (final conversation in conversations) ...[
          if (conversation.isIncomingRequest) ...[
            if (!_answered.containsKey(conversation.id) ||
                _answered[conversation.id] != conversation.updatedAt)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      conversation.peer.displayName,
                      style: VnlfTypography.body(colors.ink),
                    ),
                  ),
                  IconButton(
                    key: ValueKey('communication-accept-${conversation.id}'),
                    tooltip: vi.app.communication.chapNhanYeuCau,
                    onPressed: _pending.contains(conversation.id)
                        ? null
                        : () => _answer(conversation, true),
                    icon: const Icon(Icons.check, size: 18),
                  ),
                  IconButton(
                    key: ValueKey('communication-decline-${conversation.id}'),
                    tooltip: vi.app.communication.tuChoiYeuCau,
                    onPressed: _pending.contains(conversation.id)
                        ? null
                        : () => _answer(conversation, false),
                    icon: const Icon(Icons.close, size: 18),
                  ),
                ],
              )
            else
              Text(
                vi.app.communication.daXuLyYeu,
                style: VnlfTypography.meta(colors.muted),
              ),
          ],
          ListTile(
            key: ValueKey('communication-dm-${conversation.id}'),
            contentPadding: const EdgeInsets.symmetric(horizontal: 6),
            selected: widget.activeConversationId == conversation.id,
            selectedTileColor: colors.brandSoft,
            leading: conversation.isBlockedByMe
                ? CircleAvatar(
                    backgroundColor: colors.surfaceSoft,
                    child: const Text('?'),
                  )
                : VnlfAvatar(
                    author: presentAuthor(conversation.peer.toAuthor()),
                    size: 34,
                  ),
            title: Text(
              conversation.peer.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: VnlfTypography.body(colors.ink),
            ),
            subtitle: Text(
              conversation.lastMessage ??
                  vi.directMessageLiveView.chuaCoTinNhan,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: VnlfTypography.meta(colors.muted),
            ),
            trailing: conversation.unreadCount == 0
                ? null
                : Text(
                    '${conversation.unreadCount}',
                    style: VnlfTypography.meta(colors.brand),
                  ),
            onTap: () {
              ref.read(selectedDmConversationIdProvider.notifier).state =
                  conversation.id;
              _navigate('/messages/${Uri.encodeComponent(conversation.id)}');
            },
          ),
          if (_failures[conversation.id] != null)
            Semantics(
              liveRegion: true,
              child: Text(
                dmFailureMessage(context, _failures[conversation.id]),
                style: VnlfTypography.meta(colors.red),
              ),
            ),
        ],
        if (inbox.loaded && !inbox.loading && conversations.isEmpty)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              vi.app.communication.chuaCoCuocTro,
              style: VnlfTypography.meta(colors.muted),
            ),
          ),
      ],
    );
  }
}
