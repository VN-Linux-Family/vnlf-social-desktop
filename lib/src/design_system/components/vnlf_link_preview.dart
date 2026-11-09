import 'package:flutter/material.dart';

import '../../i18n/vi.dart';
import '../icons/vnlf_icon.dart';
import '../tokens/vnlf_colors.dart';
import '../tokens/vnlf_dimensions.dart';
import '../tokens/vnlf_typography.dart';

/// A link card under a post without photos, like the website's
/// `.post-link-preview`: photo first, then site, title and description.
class VnlfLinkPreviewCard extends StatelessWidget {
  const VnlfLinkPreviewCard({
    super.key,
    required this.siteName,
    required this.title,
    required this.description,
    required this.onOpen,
    this.imageUrl,
  });

  final String siteName;
  final String title;
  final String description;
  final String? imageUrl;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final text = VnlfTypography.body(colors.ink).copyWith(height: 1.5);
    return _PreviewFrame(
      onTap: onOpen,
      semanticLabel: title,
      children: [
        if (imageUrl != null) _PreviewPhoto(url: imageUrl!),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
          child: Text(
            siteName,
            style: text.copyWith(
              color: colors.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(title, style: text.copyWith(fontWeight: FontWeight.w700)),
        ),
        if (description.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: text,
            ),
          ),
      ],
    );
  }
}

/// A YouTube link under a post: site, title and a 16:9 thumbnail with a play
/// button. The app cannot embed the player, so play opens the video outside.
class VnlfYoutubePreviewCard extends StatelessWidget {
  const VnlfYoutubePreviewCard({
    super.key,
    required this.siteName,
    required this.title,
    required this.thumbnailUrl,
    required this.onPlay,
  });

  final String siteName;
  final String title;
  final String thumbnailUrl;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final text = VnlfTypography.body(colors.ink).copyWith(height: 1.5);
    return _PreviewFrame(
      bottomPadding: 0,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
          child: Text(
            siteName,
            style: text.copyWith(
              color: colors.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(title, style: text.copyWith(fontWeight: FontWeight.w700)),
        ),
        Semantics(
          button: true,
          label: format(vi.linkPreview.phatVideo, {'title': title}),
          child: InkWell(
            onTap: onPlay,
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const ColoredBox(color: Colors.black),
                  Image.network(
                    thumbnailUrl,
                    fit: BoxFit.cover,
                    excludeFromSemantics: true,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                  Center(
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xA8000000),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x59000000),
                            offset: Offset(0, 4),
                            blurRadius: 14,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: VnlfIcon(
                          VnlfLucide.play,
                          size: 24,
                          color: Colors.white,
                          filled: true,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PreviewFrame extends StatelessWidget {
  const _PreviewFrame({
    required this.children,
    this.onTap,
    this.semanticLabel,
    this.bottomPadding = 12,
  });

  final List<Widget> children;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final radius = BorderRadius.circular(VnlfDimensions.radiusMd);
    final column = Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 6,
        children: children,
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Material(
            color: colors.surface,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: radius,
              side: BorderSide(color: colors.line),
            ),
            child: onTap == null
                ? column
                : Semantics(
                    link: true,
                    label: semanticLabel,
                    child: InkWell(onTap: onTap, child: column),
                  ),
          ),
        ),
      ),
    );
  }
}

/// Wide photos fill the 1.91:1 frame; logos and tall pictures are shown whole
/// and never enlarged, as on the website. A photo that fails takes no room.
class _PreviewPhoto extends StatefulWidget {
  const _PreviewPhoto({required this.url});
  final String url;

  @override
  State<_PreviewPhoto> createState() => _PreviewPhotoState();
}

class _PreviewPhotoState extends State<_PreviewPhoto> {
  static final _outcomes = <String, BoxFit?>{};
  ImageStream? _stream;
  ImageStreamListener? _listener;
  bool _failed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_stream != null || _outcomes.containsKey(widget.url)) return;
    final stream = NetworkImage(widget.url)
        .resolve(createLocalImageConfiguration(context));
    final listener = ImageStreamListener(
      (info, _) {
        final wide =
            info.image.width > 400 &&
            info.image.width >= info.image.height * 1.3;
        _outcomes[widget.url] = wide ? BoxFit.cover : BoxFit.scaleDown;
        if (mounted) setState(() {});
      },
      onError: (_, _) {
        _outcomes[widget.url] = null;
        if (mounted) setState(() => _failed = true);
      },
    );
    stream.addListener(listener);
    _stream = stream;
    _listener = listener;
  }

  @override
  void dispose() {
    final listener = _listener;
    if (listener != null) _stream?.removeListener(listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final known = _outcomes.containsKey(widget.url);
    if (_failed || (known && _outcomes[widget.url] == null)) {
      return const SizedBox.shrink();
    }
    final colors = VnlfColors.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 280),
      child: AspectRatio(
        aspectRatio: 1.91,
        child: ColoredBox(
          color: colors.ink.withValues(alpha: .07),
          child: known
              ? Image.network(
                  widget.url,
                  fit: _outcomes[widget.url],
                  excludeFromSemantics: true,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                )
              : null,
        ),
      ),
    );
  }
}
