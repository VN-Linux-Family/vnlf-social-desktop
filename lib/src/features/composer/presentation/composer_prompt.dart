import 'package:flutter/material.dart';

import '../../../design_system/design_system.dart';
import '../../../i18n/vi.dart';

/// The website's composer bar: the viewer's avatar, the prompt and an
/// add-image tile. Wider screens draw a bordered card; phones a full-bleed
/// band whose image tile is a plain 44px target.
class ComposerPrompt extends StatelessWidget {
  const ComposerPrompt({
    super.key,
    required this.onPressed,
    required this.avatar,
  });

  final VoidCallback onPressed;

  /// The viewer's 34px avatar, or the guest "?".
  final Widget avatar;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final phone =
        VnlfViewportSize.fromWidth(MediaQuery.sizeOf(context).width) ==
        VnlfViewportSize.mobile;
    final imageTile = phone
        ? SizedBox.square(
            dimension: 44,
            child: Center(
              child: VnlfIcon(
                VnlfLucide.imagePlus,
                size: 20,
                color: colors.muted,
              ),
            ),
          )
        : Container(
            width: 25,
            height: 25,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.brandSoft,
              borderRadius: BorderRadius.circular(VnlfDimensions.radiusSm),
            ),
            child: VnlfIcon(
              VnlfLucide.imagePlus,
              size: 20,
              color: colors.brand,
            ),
          );

    return Padding(
      padding: phone
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(vertical: 14),
      child: Material(
        color: colors.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            phone ? 0 : VnlfDimensions.radiusLg,
          ),
          side: phone ? BorderSide.none : BorderSide(color: colors.line),
        ),
        child: InkWell(
          onTap: onPressed,
          child: Padding(
            padding: phone
                ? const EdgeInsets.fromLTRB(16, 10, 6, 10)
                : const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            child: Row(
              spacing: phone ? 12 : 10,
              children: [
                SizedBox.square(dimension: 34, child: avatar),
                Expanded(
                  child: Text(
                    vi.feedViews.homNayBanMuonChia,
                    style: VnlfTypography.body(colors.muted),
                  ),
                ),
                imageTile,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
