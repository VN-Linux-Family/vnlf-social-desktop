import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../design_system/design_system.dart';
import 'channel_feedback.dart';
import 'live_channel_state.dart';

class LiveChannelDirectory extends ConsumerWidget {
  const LiveChannelDirectory({super.key, this.onSelected});
  final VoidCallback? onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(sessionStateProvider) == null) return const SizedBox.shrink();
    final channels = ref.watch(liveChannelsProvider);
    final selected = ref.watch(liveSelectedChannelProvider);
    return Column(
      children: [
        ListTile(
          title: Text(
            channelText(context, 'Kênh cộng đồng', 'Community channels'),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          trailing: IconButton(
            tooltip: channelText(
              context,
              'Làm mới danh sách kênh',
              'Refresh channels',
            ),
            onPressed: channels.isLoading
                ? null
                : () {
                    ref.read(apiClientProvider).clearCache();
                    ref.invalidate(liveChannelsProvider);
                  },
            icon: const Icon(Icons.refresh, size: 20),
          ),
        ),
        Expanded(
          child: channels.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Padding(
              padding: const EdgeInsets.all(12),
              child: Text(channelFailure(context, error)),
            ),
            data: (items) {
              final sorted = [...items]
                ..sort((a, b) => a.position.compareTo(b.position));
              final active = items.any((c) => c.id == selected)
                  ? selected
                  : sorted.firstOrNull?.id;
              if (sorted.isEmpty) {
                return Center(
                  child: Text(
                    channelText(context, 'Chưa có kênh', 'No channels yet'),
                  ),
                );
              }
              return ListView(
                children: [
                  for (final channel in sorted)
                    ListTile(
                      key: ValueKey('channel-${channel.id}'),
                      selected: active == channel.id,
                      selectedTileColor: VnlfColors.of(context).brandSoft,
                      leading: Icon(
                        channel.isArchived
                            ? Icons.archive_outlined
                            : channel.type == 'ANNOUNCEMENT'
                            ? Icons.campaign_outlined
                            : Icons.tag,
                        size: 18,
                      ),
                      title: Text(
                        channel.name.isEmpty ? channel.slug : channel.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '#${channel.slug}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: channel.unreadCount > 0
                          ? Badge(
                              label: Text('${channel.unreadCount}'),
                              backgroundColor: channel.unreadAttentionCount > 0
                                  ? VnlfColors.of(context).red
                                  : null,
                            )
                          : null,
                      onTap: () {
                        ref.read(liveSelectedChannelProvider.notifier).state =
                            channel.id;
                        onSelected?.call();
                      },
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
