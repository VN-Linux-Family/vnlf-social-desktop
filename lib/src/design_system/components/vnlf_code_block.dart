import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens/vnlf_colors.dart';
import '../tokens/vnlf_dimensions.dart';
import '../tokens/vnlf_typography.dart';

/// Dark forest-green terminal code block matching Post 2 in `reference_feed_desktop.png`,
/// featuring a floating top-right copy pill and bottom scrollbar track.
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
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Text(
                    widget.code,
                    style: VnlfTypography.code(colors.codeBlockText),
                  ),
                ),
              ),
              if (widget.showHorizontalScrollbar)
                Container(
                  height: 11,
                  color: colors.brandStrong,
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Row(
                    children: [
                      Icon(
                        Icons.arrow_left_rounded,
                        size: 11,
                        color: colors.muted,
                      ),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: 0.92,
                            child: Container(
                              height: 6,
                              decoration: BoxDecoration(
                                color: colors.line,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_right_rounded,
                        size: 11,
                        color: colors.muted,
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (activeCopyText.isNotEmpty)
            Positioned(
              top: 8,
              right: 10,
              child: Semantics(
                button: true,
                label: activeCopySemantics.isNotEmpty
                    ? activeCopySemantics
                    : null,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(
                      VnlfDimensions.radiusSm,
                    ),
                    onTap: _handleCopy,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colors.codeBlockPillBg.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(
                          VnlfDimensions.radiusSm,
                        ),
                        border: Border.all(
                          color: colors.codeBlockText.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Text(
                        activeCopyText,
                        style: VnlfTypography.caption(
                          colors.codeBlockText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
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
