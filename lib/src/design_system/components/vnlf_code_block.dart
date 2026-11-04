import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens/vnlf_colors.dart';
import '../tokens/vnlf_dimensions.dart';
import '../tokens/vnlf_typography.dart';

/// Dark forest-green terminal code block matching Post 2 in `reference_feed_desktop.png`,
/// featuring a floating top-right "Sao chép" pill and bottom scrollbar track.
class VnlfCodeBlock extends StatefulWidget {
  const VnlfCodeBlock({
    super.key,
    required this.code,
    this.showHorizontalScrollbar = true,
  });

  final String code;
  final bool showHorizontalScrollbar;

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

    return Container(
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
                  color: const Color(0xFF1F2421),
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.arrow_left_rounded,
                        size: 11,
                        color: Color(0xFF9CA3AF),
                      ),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: 0.92,
                            child: Container(
                              height: 6,
                              decoration: BoxDecoration(
                                color: const Color(0xFFC7CCC9),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.arrow_right_rounded,
                        size: 11,
                        color: Color(0xFF9CA3AF),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          Positioned(
            top: 8,
            right: 10,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(VnlfDimensions.radiusSm),
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
                      color: Colors.white.withValues(alpha: 0.14),
                    ),
                  ),
                  child: Text(
                    _copied ? 'Đã chép' : 'Sao chép',
                    style: VnlfTypography.caption(
                      colors.codeBlockText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
