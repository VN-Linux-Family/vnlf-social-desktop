import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens/vnlf_colors.dart';
import '../tokens/vnlf_dimensions.dart';
import '../tokens/vnlf_typography.dart';

/// Dark forest-green terminal code block matching Post 2 in `reference_feed_desktop.png`,
/// with a copy control and a functional horizontal scrollbar.
class VnlfCodeBlock extends StatefulWidget {
  const VnlfCodeBlock({
    super.key,
    required this.code,
    this.showHorizontalScrollbar = true,
    this.copyLabel = '',
    this.copiedLabel = '',
    this.semanticLabel,
    this.copyButtonSemanticLabel,
    this.copiedButtonSemanticLabel,
  });

  final String code;
  final bool showHorizontalScrollbar;
  final String copyLabel;
  final String copiedLabel;
  final String? semanticLabel;
  final String? copyButtonSemanticLabel;
  final String? copiedButtonSemanticLabel;

  @override
  State<VnlfCodeBlock> createState() => _VnlfCodeBlockState();
}

class _VnlfCodeBlockState extends State<VnlfCodeBlock> {
  bool _copied = false;
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleCopy() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    if (!mounted) return;
    setState(() => _copied = true);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final activeCopyText = _copied ? widget.copiedLabel : widget.copyLabel;
    final activeCopySemantics = _copied
        ? (widget.copiedButtonSemanticLabel ?? widget.copiedLabel)
        : (widget.copyButtonSemanticLabel ?? widget.copyLabel);

    final block = Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.codeBlockBg,
        borderRadius: BorderRadius.circular(VnlfDimensions.radiusMd),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (activeCopyText.isNotEmpty)
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: Semantics(
                  button: true,
                  label: activeCopySemantics.isNotEmpty
                      ? activeCopySemantics
                      : null,
                  child: Material(
                    color: colors.codeBlockPillBg,
                    borderRadius: BorderRadius.circular(
                      VnlfDimensions.radiusSm,
                    ),
                    child: InkWell(
                      onTap: _handleCopy,
                      borderRadius: BorderRadius.circular(
                        VnlfDimensions.radiusSm,
                      ),
                      child: IntrinsicWidth(
                        child: Container(
                          constraints: const BoxConstraints(
                            minWidth: 48,
                            minHeight: 48,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          alignment: Alignment.center,
                          child: Text(
                            activeCopyText,
                            style: VnlfTypography.caption(colors.codeBlockText),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Scrollbar(
            controller: _scrollController,
            thumbVisibility: widget.showHorizontalScrollbar,
            interactive: true,
            scrollbarOrientation: ScrollbarOrientation.bottom,
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
              child: Text(
                widget.code,
                style: VnlfTypography.code(colors.codeBlockText),
              ),
            ),
          ),
        ],
      ),
    );

    if (widget.semanticLabel == null) {
      return block;
    }
    return Semantics(
      label: widget.semanticLabel,
      container: true,
      child: block,
    );
  }
}
