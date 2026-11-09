import 'package:flutter/material.dart';

import '../../core/external_uri.dart';
import '../../i18n/vi.dart';
import '../models/vnlf_models.dart';
import '../tokens/vnlf_colors.dart';
import 'vnlf_video.dart';

/// Photos and videos under a post or comment, like the website's
/// `.media-gallery`: one photo spans the width, two share it, more scroll
/// sideways in a rail. [compact] is the smaller rail used in comments.
class VnlfMediaGallery extends StatelessWidget {
  const VnlfMediaGallery({
    super.key,
    required this.items,
    this.compact = false,
  });
  final List<PostMediaData> items;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final images = items.where((item) => !item.isVideo).toList();
    final videos = items.where((item) => item.isVideo).toList();
    final screen = MediaQuery.sizeOf(context).width;
    final narrow = screen <= 520;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final video in videos)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: VnlfVideo(media: video),
          ),
        if (images.length == 1)
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final height = (width / images.first.aspectRatio)
                  .clamp(180.0, compact ? 280.0 : 520.0)
                  .toDouble();
              return _GalleryTile(
                images: images,
                index: 0,
                width: width,
                height: height,
                fit: BoxFit.contain,
              );
            },
          )
        else if (images.length > 1)
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final height = compact
                  ? 180.0
                  : narrow
                  ? 260.0
                  : (screen * .42).clamp(240.0, 420.0).toDouble();
              final tile = images.length == 2
                  ? (width - 8) / 2
                  : compact || !narrow
                  ? (width * .78).clamp(0.0, 420.0).toDouble()
                  : width * .82;
              return SizedBox(
                height: height + 4,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: images.length == 2
                      ? const NeverScrollableScrollPhysics()
                      : null,
                  padding: const EdgeInsets.only(bottom: 4),
                  itemCount: images.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, i) => _GalleryTile(
                    images: images,
                    index: i,
                    width: tile,
                    height: height,
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

class _GalleryTile extends StatelessWidget {
  const _GalleryTile({
    required this.images,
    required this.index,
    required this.width,
    required this.height,
    required this.fit,
  });

  final List<PostMediaData> images;
  final int index;
  final double width;
  final double height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final image = images[index];
    final radius = BorderRadius.circular(14);
    return Semantics(
      button: true,
      label: format(vi.mediaGallery.xemAnh, {
        'value': index + 1,
        'count': images.length,
      }),
      excludeSemantics: true,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: colors.surfaceSoft,
          border: Border.all(color: colors.line),
          borderRadius: radius,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: externalWebUri(image.url) == null
                  ? null
                  : () => Navigator.of(context).push<void>(
                      MaterialPageRoute(
                        builder: (_) =>
                            _ImageViewer(items: images, initial: index),
                      ),
                    ),
              child: _RemoteImage(media: image, fit: fit),
            ),
          ),
        ),
      ),
    );
  }
}

class _RemoteImage extends StatelessWidget {
  const _RemoteImage({required this.media, this.fit = BoxFit.contain});
  final PostMediaData media;
  final BoxFit fit;
  @override
  Widget build(BuildContext context) {
    Widget failure() => ColoredBox(
      color: VnlfColors.of(context).surfaceSoft,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.broken_image_outlined),
            Text(vi.articleImageNode.khongTaiDuocAnh),
          ],
        ),
      ),
    );
    if (externalWebUri(media.url) == null) return failure();
    final size = MediaQuery.sizeOf(context);
    return Image.network(
      media.url,
      fit: fit,
      semanticLabel: media.alt.isEmpty
          ? vi.app.designSystem.anhBaiViet
          : media.alt,
      cacheWidth: (size.width * MediaQuery.devicePixelRatioOf(context))
          .round()
          .clamp(1, 4096),
      loadingBuilder: (context, child, progress) => progress == null
          ? child
          : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      errorBuilder: (context, error, stack) => failure(),
    );
  }
}

class _ImageViewer extends StatefulWidget {
  const _ImageViewer({required this.items, required this.initial});
  final List<PostMediaData> items;
  final int initial;
  @override
  State<_ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<_ImageViewer> {
  late final _controller = PageController(initialPage: widget.initial);
  late int _index = widget.initial;
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      title: Text('${_index + 1} / ${widget.items.length}'),
    ),
    body: SafeArea(
      child: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.items.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) => InteractiveViewer(
              minScale: 1,
              maxScale: 5,
              child: _RemoteImage(media: widget.items[i]),
            ),
          ),
          if (_index > 0)
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton.filled(
                tooltip: vi.mediaGallery.anhTruoc,
                icon: const Icon(Icons.chevron_left),
                onPressed: () => _controller.previousPage(
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                ),
              ),
            ),
          if (_index < widget.items.length - 1)
            Align(
              alignment: Alignment.centerRight,
              child: IconButton.filled(
                tooltip: vi.app.designSystem.anhSau,
                icon: const Icon(Icons.chevron_right),
                onPressed: () => _controller.nextPage(
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
