import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/vnlf_navigation_helper.dart';
import '../../../design_system/design_system.dart';
import '../../../i18n/vi.dart';
import '../data/link_preview_repository.dart';
import '../domain/link_preview.dart';
import 'feature_samples.dart';

final linkPreviewRepositoryProvider = Provider<LinkPreviewRepository>(
  (ref) => offlineFeatures
      ? const FixtureLinkPreviewRepository()
      : LiveLinkPreviewRepository(
          ref.watch(apiClientProvider),
          baseUrl: ref.watch(apiBaseUrlProvider),
        ),
);

/// Cards are kept for an hour, like the website's query cache.
final linkPreviewProvider = FutureProvider.autoDispose
    .family<LinkPreview?, String>((ref, url) {
      final keep = ref.keepAlive();
      final timer = Timer(const Duration(hours: 1), keep.close);
      ref.onDispose(timer.cancel);
      return ref.watch(linkPreviewRepositoryProvider).preview(url);
    });

/// The card for the first link of a post without photos or a poll.
class PostLinkPreview extends ConsumerWidget {
  const PostLinkPreview({super.key, required this.content});

  final String content;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final url = firstContentLink(content);
    if (url == null) return const SizedBox.shrink();
    final video = youtubeVideoId(url);
    final repository = ref.watch(linkPreviewRepositoryProvider);
    final preview = ref.watch(linkPreviewProvider(url));
    if (preview.isLoading) return const SizedBox.shrink();
    final value = preview.valueOrNull;
    if (video != null) {
      return VnlfYoutubePreviewCard(
        siteName: value?.siteName.isNotEmpty == true
            ? value!.siteName
            : 'YouTube',
        title: value?.title.isNotEmpty == true
            ? value!.title
            : vi.linkPreview.videoYoutube,
        thumbnailUrl: repository.proxiedImage(
          value?.imageUrl ?? 'https://i.ytimg.com/vi/$video/hqdefault.jpg',
        ),
        onPlay: () => openVnlfLink(context, value?.url ?? url),
      );
    }
    if (value == null) return const SizedBox.shrink();
    return VnlfLinkPreviewCard(
      siteName: value.siteName,
      title: value.title,
      description: value.description,
      imageUrl: value.imageUrl == null
          ? null
          : repository.proxiedImage(value.imageUrl!),
      onOpen: () => openVnlfLink(context, value.url),
    );
  }
}
