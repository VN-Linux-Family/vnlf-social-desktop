import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/design_system.dart';
import '../../shared/presentation/community_samples.dart';
import '../../shared/presentation/feature_widgets.dart';
import 'channel_state.dart';
import '../../shared/presentation/feature_samples.dart';
import 'live_channel_directory.dart';

class ChannelDirectory extends ConsumerWidget {
  const ChannelDirectory({super.key, this.onSelected});

  final VoidCallback? onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!offlineFeatures) return LiveChannelDirectory(onSelected: onSelected);
    final english = Localizations.localeOf(context).languageCode == 'en';
    final selected = ref.watch(selectedChannelProvider);
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            english ? 'Community channels' : 'Kênh cộng đồng',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        for (final channel in localChannels)
          ListTile(
            title: Text('#${channel.id}', style: const TextStyle(fontSize: 12)),
            selected: selected == channel.id,
            selectedTileColor: VnlfColors.of(context).brandSoft,
            onTap: () {
              ref.read(selectedChannelProvider.notifier).state = channel.id;
              onSelected?.call();
            },
          ),
      ],
    );
  }
}

class ActiveCommunityMembers extends StatelessWidget {
  const ActiveCommunityMembers({super.key});

  @override
  Widget build(BuildContext context) {
    if (!offlineFeatures) return const SizedBox.shrink();
    final english = Localizations.localeOf(context).languageCode == 'en';
    return FeatureSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            english ? 'Active members' : 'Đang hoạt động',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          for (final author in communityMembers)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  VnlfAvatar(
                    author: author,
                    size: 32,
                    semanticLabel: author.displayName,
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: VnlfAuthorNameRow(author: author)),
                  Icon(
                    Icons.circle,
                    size: 8,
                    color: VnlfColors.of(context).brand,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
