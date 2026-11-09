import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/api_client.dart';
import '../../../design_system/components/vnlf_media_gallery.dart';
import '../../../design_system/design_system.dart';
import '../../../i18n/vi.dart';
import '../data/channel_media_repository.dart';
import '../domain/channel_models.dart';

final channelMediaUrlProvider = FutureProvider.autoDispose.family<Uri, String>((
  ref,
  path,
) {
  if (ref.watch(sessionStateProvider) == null) throw const HttpFailure(401);
  return ChannelMediaRepository(ref.watch(apiClientProvider)).resolve(path);
});

class ChannelMedia extends ConsumerWidget {
  const ChannelMedia({super.key, required this.items});
  final List<ChannelAttachment> items;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final media = <PostMediaData>[];
    final pending = <Widget>[];
    for (final item in items) {
      var url = item.url;
      if (url.isEmpty && item.downloadPath.isNotEmpty) {
        final resolved = ref.watch(channelMediaUrlProvider(item.downloadPath));
        if (resolved.isLoading) {
          pending.add(
            const Padding(
              padding: EdgeInsets.all(12),
              child: LinearProgressIndicator(),
            ),
          );
          continue;
        }
        if (resolved.hasError) {
          pending.add(
            TextButton.icon(
              onPressed: () =>
                  ref.invalidate(channelMediaUrlProvider(item.downloadPath)),
              icon: const Icon(Icons.broken_image_outlined),
              label: Text((vi.app.common.khongTaiDuocAnh)),
            ),
          );
          continue;
        }
        url = resolved.requireValue.toString();
      }
      media.add(
        PostMediaData(
          url: url,
          mime: item.mime,
          width: item.width,
          height: item.height,
          posterUrl: item.posterUrl,
          state: item.state.isEmpty ? null : item.state,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (media.isNotEmpty) VnlfMediaGallery(items: media),
        ...pending,
      ],
    );
  }
}
