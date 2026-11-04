import 'package:flutter/material.dart';

import '../tokens/vnlf_colors.dart';

/// Provides application branding widgets behind a single abstraction.
///
/// In public builds or without explicit owner approval, [BrandAssets] renders
/// a neutral community placeholder. The local custom-painted emblem is isolated
/// here for local development and testing only.
abstract final class BrandAssets {
  /// Whether to render the unconfirmed local development emblem.
  /// Set to false to replace with a neutral community badge across the entire app.
  static bool useLocalDevEmblem = true;

  /// Returns the brand logo widget with the specified [size].
  static Widget logo({double size = 30.0}) {
    if (useLocalDevEmblem) {
      return _VnlfDevLogoEmblem(size: size);
    }
    return _NeutralLogoPlaceholder(size: size);
  }
}

/// Neutral placeholder emblem for safe public distribution.
class _NeutralLogoPlaceholder extends StatelessWidget {
  const _NeutralLogoPlaceholder({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colors.brandSoft,
        shape: BoxShape.circle,
        border: Border.all(color: colors.brand, width: 1.5),
      ),
      child: Center(
        child: Icon(
          Icons.terminal_rounded,
          size: size * 0.55,
          color: colors.brand,
        ),
      ),
    );
  }
}

/// Local dev custom-painted circular emblem.
///
/// UNKNOWN OWNERSHIP: Replicated from website top-left emblem. Kept for local
/// visual comparison only. Do not ship publicly without owner permission.
class _VnlfDevLogoEmblem extends StatelessWidget {
  const _VnlfDevLogoEmblem({this.size = 30.0});

  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = VnlfColors.of(context);

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _VnlfDevLogoPainter(
          brandColor: colors.brand,
          inkColor: colors.ink,
        ),
      ),
    );
  }
}

class _VnlfDevLogoPainter extends CustomPainter {
  const _VnlfDevLogoPainter({required this.brandColor, required this.inkColor});

  final Color brandColor;
  final Color inkColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final outerPaint = Paint()
      ..color = brandColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.085;
    canvas.drawCircle(center, radius - outerPaint.strokeWidth / 2, outerPaint);

    final innerPaint = Paint()
      ..color = brandColor.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.76, innerPaint);

    final glyphPaint = Paint()
      ..color = inkColor
      ..style = PaintingStyle.fill;

    final dotRadius = size.width * 0.095;
    canvas.drawCircle(
      Offset(center.dx, center.dy - radius * 0.28),
      dotRadius,
      glyphPaint,
    );

    final arcRect = Rect.fromCircle(
      center: Offset(center.dx, center.dy + radius * 0.06),
      radius: radius * 0.42,
    );
    final arcPaint = Paint()
      ..color = brandColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = size.width * 0.1;
    canvas.drawArc(arcRect, 0.45, 2.24, false, arcPaint);
  }

  @override
  bool shouldRepaint(covariant _VnlfDevLogoPainter oldDelegate) =>
      oldDelegate.brandColor != brandColor || oldDelegate.inkColor != inkColor;
}
