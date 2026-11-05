import 'package:flutter/material.dart';

import '../../core/external_uri.dart';
import '../models/vnlf_models.dart';
import '../tokens/vnlf_colors.dart';
import 'vnlf_video.dart';

class VnlfMediaGallery extends StatelessWidget {
  const VnlfMediaGallery({super.key, required this.items});
  final List<PostMediaData> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final images = items.where((item) => !item.isVideo).toList();
    final videos = items.where((item) => item.isVideo).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final video in videos)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: VnlfVideo(media: video),
          ),
        if (images.isNotEmpty)
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = images.length > 1 ? 2 : 1;
              final width =
                  (constraints.maxWidth - (columns - 1) * 6) / columns;
              return Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (var i = 0; i < images.length; i++)
                    SizedBox(
                      width: width,
                      child: InkWell(
                        onTap: externalWebUri(images[i].url) == null
                            ? null
                            : () => Navigator.of(context).push<void>(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      _ImageViewer(items: images, initial: i),
                                ),
                              ),
                        borderRadius: BorderRadius.circular(10),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 650),
                            child: AspectRatio(
                              aspectRatio: columns == 1
                                  ? images[i].aspectRatio
                                  : 1,
                              child: _RemoteImage(
                                media: images[i],
                                fit: columns == 1
                                    ? BoxFit.contain
                                    : BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }
}

class _RemoteImage extends StatelessWidget {
  const _RemoteImage({required this.media, this.fit = BoxFit.contain});
  final PostMediaData media;
  final BoxFit fit;
  @override
  Widget build(BuildContext context) {
    final english = Localizations.localeOf(context).languageCode == 'en';
    Widget failure() => ColoredBox(
      color: VnlfColors.of(context).surfaceSoft,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.broken_image_outlined),
            Text(english ? 'Image unavailable' : 'Không tải được ảnh'),
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
          ? (english ? 'Post image' : 'Ảnh bài viết')
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
                tooltip: 'Ảnh trước',
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
                tooltip: 'Ảnh sau',
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
