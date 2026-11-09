import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/vnlf_navigation_helper.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/models.dart';
import '../../../i18n/vi.dart';

/// The website's public article route uses the server-provided slug.
Uri? canonicalPostUri(FeedPost post) => post.slug.isEmpty
    ? null
    : Uri(
        scheme: 'https',
        host: 'vietnamlinuxfamily.net',
        pathSegments: ['a', post.slug],
      );

Future<void> copyPostLink(BuildContext context, FeedPost post) async {
  final uri = canonicalPostUri(post);
  if (uri == null) {
    showVnlfToast(context, vi.app.shared.baiVietChuaCo);
    return;
  }
  await _copy(context, uri);
}

Future<void> _copy(BuildContext context, Uri uri) async {
  String message;
  try {
    await Clipboard.setData(ClipboardData(text: uri.toString()));
    message = vi.socialOverlays.daSaoChepLienKet;
  } on PlatformException {
    message = vi.app.shared.khongTheSaoChep;
  }
  if (context.mounted) showVnlfToast(context, message);
}

/// The website's share dialog: send in a message, Facebook, Telegram, Email,
/// and the link with a copy button.
Future<void> showPostShareDialog(BuildContext context, FeedPost post) async {
  final uri = canonicalPostUri(post);
  if (uri == null) {
    showVnlfToast(context, vi.app.shared.baiVietChuaCo);
    return;
  }
  await showVnlfModal<void>(
    context,
    label: vi.common.chiaSeBaiViet,
    builder: (_) => _ShareDialog(uri: uri, hostContext: context),
  );
}

class _ShareDialog extends StatelessWidget {
  const _ShareDialog({required this.uri, required this.hostContext});

  final Uri uri;

  /// Stays mounted after the dialog closes, for navigation and toasts.
  final BuildContext hostContext;

  @override
  Widget build(BuildContext context) {
    final link = Uri.encodeComponent(uri.toString());
    final targets = <(VnlfLucide, String, Future<void> Function())>[
      (
        VnlfLucide.messageCircle,
        vi.common.tinNhan,
        () async => GoRouter.maybeOf(hostContext)?.push('/messages'),
      ),
      (
        VnlfLucide.users,
        'Facebook',
        () => _open('https://www.facebook.com/sharer/sharer.php?u=$link'),
      ),
      (
        VnlfLucide.send,
        'Telegram',
        () => _open('https://t.me/share/url?url=$link'),
      ),
      (
        VnlfLucide.mail,
        vi.socialOverlays.email,
        () => _open(
          'mailto:?subject=${Uri.encodeComponent(vi.socialOverlays.baiVietTuVnlfSocial)}&body=$link',
        ),
      ),
    ];
    final columns = MediaQuery.sizeOf(context).width <= 520 ? 2 : 4;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VnlfModalHeader(
          eyebrow: vi.socialOverlays.chiaSe,
          title: vi.socialOverlays.guiBaiVietNay,
        ),
        const SizedBox(height: 25),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = (constraints.maxWidth - 7 * (columns - 1)) / columns;
            return Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (final (icon, label, action) in targets)
                  SizedBox(
                    width: width,
                    child: _ShareTarget(
                      icon: icon,
                      label: label,
                      onPressed: () {
                        Navigator.of(context).pop();
                        action();
                      },
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 17),
        _CopyRow(uri: uri, hostContext: hostContext),
      ],
    );
  }

  Future<void> _open(String url) async {
    if (await openVnlfLink(hostContext, url)) return;
    if (hostContext.mounted) {
      showVnlfToast(hostContext, vi.app.common.khongMoDuocLien);
    }
  }
}

class _ShareTarget extends StatefulWidget {
  const _ShareTarget({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final VnlfLucide icon;
  final String label;
  final VoidCallback onPressed;

  @override
  State<_ShareTarget> createState() => _ShareTargetState();
}

class _ShareTargetState extends State<_ShareTarget> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final color = _hovered ? colors.brand : colors.ink;
    final radius = BorderRadius.circular(VnlfDimensions.radiusMd);
    return Material(
      color: colors.surfaceSoft,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: _hovered ? colors.brand : colors.line),
      ),
      child: InkWell(
        borderRadius: radius,
        onHover: (value) => setState(() => _hovered = value),
        onTap: widget.onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 12),
          child: Column(
            spacing: 6,
            children: [
              VnlfIcon(widget.icon, size: 19, color: color),
              Text(
                widget.label,
                textAlign: TextAlign.center,
                style: VnlfTypography.body(color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CopyRow extends StatelessWidget {
  const _CopyRow({required this.uri, required this.hostContext});

  final Uri uri;
  final BuildContext hostContext;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);
    final shown = uri.toString().replaceFirst(RegExp(r'^https?://'), '');
    final onBrand = colors.isDark ? const Color(0xFF102116) : Colors.white;
    return Container(
      padding: const EdgeInsets.fromLTRB(9, 4, 5, 4),
      decoration: BoxDecoration(
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(VnlfDimensions.radiusMd),
      ),
      child: Row(
        spacing: 8,
        children: [
          VnlfIcon(VnlfLucide.link2, size: 16, color: colors.brand),
          Expanded(
            child: Text(
              shown,
              maxLines: 1,
              overflow: TextOverflow.fade,
              softWrap: false,
              style: VnlfTypography.body(colors.muted),
            ),
          ),
          FilledButton(
            onPressed: () => _copy(hostContext, uri),
            style: FilledButton.styleFrom(
              backgroundColor: colors.brand,
              foregroundColor: onBrand,
              minimumSize: const Size(0, 32),
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
              tapTargetSize: MaterialTapTargetSize.padded,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(VnlfDimensions.radiusSm),
              ),
              textStyle: VnlfTypography.body(onBrand)
                  .copyWith(fontWeight: FontWeight.w600),
            ),
            child: Text(vi.socialOverlays.saoChep),
          ),
        ],
      ),
    );
  }
}
