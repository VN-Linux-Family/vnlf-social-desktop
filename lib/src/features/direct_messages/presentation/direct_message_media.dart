import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../design_system/components/vnlf_media_gallery.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/models.dart';
import '../../../i18n/vi.dart';
import '../domain/direct_message_models.dart';
import 'direct_message_feedback.dart';
import 'direct_message_state.dart';

final dmPrivateMediaUrlProvider = FutureProvider.autoDispose
    .family<Uri, String>((ref, downloadPath) {
      if (ref.watch(sessionStateProvider) == null) {
        throw const HttpFailure(401);
      }
      return ref
          .watch(directMessageRepositoryProvider)
          .resolvePrivateMediaUrl(downloadPath);
    });

class DirectMessageMedia extends ConsumerWidget {
  const DirectMessageMedia({super.key, required this.items});

  final List<DmAttachment> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final media = <PostMediaData>[];
    final pending = <Widget>[];
    for (final item in items) {
      var url = item.url;
      if (url.isEmpty && item.downloadPath.isNotEmpty) {
        final resolved = ref.watch(
          dmPrivateMediaUrlProvider(item.downloadPath),
        );
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
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => ref.invalidate(
                  dmPrivateMediaUrlProvider(item.downloadPath),
                ),
                icon: const Icon(Icons.broken_image_outlined),
                label: Text(vi.app.directMessages.khongTaiDuocAnh),
              ),
            ),
          );
          continue;
        }
        url = resolved.requireValue.toString();
      }
      if (url.isEmpty) continue;
      media.add(
        PostMediaData(
          url: url,
          mime: item.mime.isEmpty ? 'image/jpeg' : item.mime,
          width: item.width,
          height: item.height,
          posterUrl: item.posterUrl,
          state: item.state.isEmpty ? null : item.state,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (media.isNotEmpty) VnlfMediaGallery(items: media),
        ...pending,
      ],
    );
  }
}

class DirectMessageMediaTilePreview extends ConsumerWidget {
  const DirectMessageMediaTilePreview({
    super.key,
    required this.item,
    required this.onJumpToMessage,
  });

  final DmMediaItem item;
  final VoidCallback onJumpToMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = VnlfColors.of(context);
    final resolved = ref.watch(dmPrivateMediaUrlProvider(item.downloadPath));
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(VnlfDimensions.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  item.author.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: VnlfTypography.meta(colors.ink),
                ),
              ),
              Text(
                formatDmTimestamp(item.createdAt),
                style: VnlfTypography.meta(colors.muted),
              ),
              IconButton(
                tooltip: vi.app.directMessages.diToiTinNhan,
                onPressed: onJumpToMessage,
                icon: const Icon(Icons.open_in_new, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 6),
          resolved.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (_, _) => Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => ref.invalidate(
                  dmPrivateMediaUrlProvider(item.downloadPath),
                ),
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(vi.app.common.khongTaiDuocAnh),
              ),
            ),
            data: (uri) => VnlfMediaGallery(
              items: <PostMediaData>[
                PostMediaData(
                  url: uri.toString(),
                  mime: 'image/jpeg',
                  width: item.width,
                  height: item.height,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
