import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/vnlf_models.dart';
import '../tokens/vnlf_colors.dart';
import '../tokens/vnlf_dimensions.dart';
import '../tokens/vnlf_typography.dart';

/// Renders a user avatar with optional custom frame (`matrix`, `neon`, `stars`)
/// and offline vector artwork so zero network requests are ever triggered.
class VnlfAvatar extends StatelessWidget {
  const VnlfAvatar({super.key, required this.author, this.size = 40.0});

  final AuthorData author;
  final double size;

  @override
  Widget build(BuildContext context) {
    final frame = author.style.frame;
    final coreAvatar = Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(shape: BoxShape.circle),
      clipBehavior: Clip.antiAlias,
      child: CustomPaint(
        painter: _AvatarArtPainter(preset: author.avatarPreset),
      ),
    );

    return switch (frame) {
      AvatarFrameType.none => SizedBox(
        width: size,
        height: size,
        child: coreAvatar,
      ),
      AvatarFrameType.neon => SizedBox(
        width: size + 6,
        height: size + 6,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: size + 5,
              height: size + 5,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: [
                    Color(0xFF0284C7),
                    Color(0xFF38BDF8),
                    Color(0xFF2563EB),
                    Color(0xFF06B6D4),
                    Color(0xFF0284C7),
                  ],
                ),
              ),
            ),
            Container(
              width: size + 1.5,
              height: size + 1.5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: VnlfColors.of(context).surface,
              ),
            ),
            coreAvatar,
          ],
        ),
      ),
      AvatarFrameType.matrix => SizedBox(
        width: size + 6,
        height: size + 6,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: size + 5,
              height: size + 5,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF10B981),
                    Color(0xFF0D9488),
                    Color(0xFF047857),
                  ],
                ),
              ),
            ),
            Container(
              width: size + 1.5,
              height: size + 1.5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: VnlfColors.of(context).surface,
              ),
            ),
            coreAvatar,
          ],
        ),
      ),
      AvatarFrameType.stars => SizedBox(
        width: size + 6,
        height: size + 6,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            coreAvatar,
            Positioned(
              top: -2,
              left: -2,
              child: CustomPaint(
                size: const Size(12, 12),
                painter: _SparkleStarPainter(color: const Color(0xFFF59E0B)),
              ),
            ),
            Positioned(
              bottom: -2,
              right: -2,
              child: CustomPaint(
                size: const Size(11, 11),
                painter: _SparkleStarPainter(color: const Color(0xFFFBBF24)),
              ),
            ),
          ],
        ),
      ),
    };
  }
}

/// Guest / unauthenticated `?` badge box matching the sidebar login card,
/// header action button, and composer prompt in `reference_feed_desktop.png`.
class VnlfGuestAvatarBox extends StatelessWidget {
  const VnlfGuestAvatarBox({
    super.key,
    this.size = 36.0,
    this.isCircle = false,
  });

  final double size;
  final bool isCircle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF215A3B),
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircle
            ? null
            : BorderRadius.circular(VnlfDimensions.radiusMd),
      ),
      child: Text(
        '?',
        style: VnlfTypography.control(
          Colors.white,
          fontWeight: FontWeight.w700,
        ).copyWith(fontSize: size * 0.38),
      ),
    );
  }
}

class _SparkleStarPainter extends CustomPainter {
  const _SparkleStarPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final rOuter = size.width / 2;
    final rInner = size.width * 0.18;

    final path = Path();
    for (var i = 0; i < 8; i++) {
      final angle = (i * math.pi / 4) - math.pi / 2;
      final r = i.isEven ? rOuter : rInner;
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparkleStarPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _AvatarArtPainter extends CustomPainter {
  const _AvatarArtPainter({required this.preset});
  final AvatarVisualPreset preset;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    switch (preset) {
      case AvatarVisualPreset.workspaceCoder:
        // Warm bright workspace photo look with person silhouette in white shirt
        final bgPaint = Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF475569), Color(0xFF1E293B)],
          ).createShader(rect);
        canvas.drawRect(rect, bgPaint);
        // Window / monitor glow behind
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              size.width * 0.15,
              size.height * 0.14,
              size.width * 0.7,
              size.height * 0.4,
            ),
            const Radius.circular(3),
          ),
          Paint()..color = const Color(0xFF94A3B8).withValues(alpha: 0.45),
        );
        // White shirt shoulders
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(size.width * 0.5, size.height * 0.92),
            width: size.width * 0.72,
            height: size.height * 0.48,
          ),
          Paint()..color = const Color(0xFFF8FAFC),
        );
        // Head & dark hair
        canvas.drawCircle(
          Offset(size.width * 0.5, size.height * 0.48),
          size.width * 0.19,
          Paint()..color = const Color(0xFFF1C29B),
        );
        canvas.drawArc(
          Rect.fromCircle(
            center: Offset(size.width * 0.5, size.height * 0.45),
            radius: size.width * 0.2,
          ),
          math.pi,
          math.pi,
          true,
          Paint()..color = const Color(0xFF0F172A),
        );

      case AvatarVisualPreset.retroChef:
        // Dark moody kitchen/terminal background with character silhouette
        final bgPaint = Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          ).createShader(rect);
        canvas.drawRect(rect, bgPaint);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(size.width * 0.5, size.height * 0.88),
            width: size.width * 0.65,
            height: size.height * 0.45,
          ),
          Paint()..color = const Color(0xFF334155),
        );
        canvas.drawCircle(
          Offset(size.width * 0.5, size.height * 0.48),
          size.width * 0.18,
          Paint()..color = const Color(0xFFE2E8F0),
        );
        // Subtle green code reflection
        canvas.drawRect(
          Rect.fromLTWH(
            size.width * 0.2,
            size.height * 0.2,
            size.width * 0.22,
            2,
          ),
          Paint()..color = const Color(0xFF4ADE80),
        );

      case AvatarVisualPreset.matrixHacker:
        final bgPaint = Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFD1FAE5), Color(0xFF6EE7B7)],
          ).createShader(rect);
        canvas.drawRect(rect, bgPaint);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(size.width * 0.5, size.height * 0.9),
            width: size.width * 0.68,
            height: size.height * 0.46,
          ),
          Paint()..color = const Color(0xFF065F46),
        );
        canvas.drawCircle(
          Offset(size.width * 0.5, size.height * 0.46),
          size.width * 0.19,
          Paint()..color = const Color(0xFF047857),
        );

      case AvatarVisualPreset.pastelSakura:
        final bgPaint = Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFCE7F3), Color(0xFFFBCFE8)],
          ).createShader(rect);
        canvas.drawRect(rect, bgPaint);
        canvas.drawCircle(
          Offset(size.width * 0.5, size.height * 0.52),
          size.width * 0.26,
          Paint()..color = const Color(0xFFF472B6),
        );
        canvas.drawCircle(
          Offset(size.width * 0.5, size.height * 0.54),
          size.width * 0.18,
          Paint()..color = const Color(0xFFFFF1F2),
        );

      case AvatarVisualPreset.tuxMascot:
        // Classic Linux Tux penguin style matching Leaderboard #3
        canvas.drawRect(rect, Paint()..color = const Color(0xFFE2E8F0));
        // Black body
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(size.width * 0.5, size.height * 0.62),
            width: size.width * 0.68,
            height: size.height * 0.78,
          ),
          Paint()..color = const Color(0xFF1E293B),
        );
        // White belly
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(size.width * 0.5, size.height * 0.68),
            width: size.width * 0.46,
            height: size.height * 0.54,
          ),
          Paint()..color = Colors.white,
        );
        // Eyes
        canvas.drawCircle(
          Offset(size.width * 0.41, size.height * 0.36),
          size.width * 0.055,
          Paint()..color = Colors.white,
        );
        canvas.drawCircle(
          Offset(size.width * 0.59, size.height * 0.36),
          size.width * 0.055,
          Paint()..color = Colors.white,
        );
        canvas.drawCircle(
          Offset(size.width * 0.42, size.height * 0.36),
          size.width * 0.028,
          Paint()..color = Colors.black,
        );
        canvas.drawCircle(
          Offset(size.width * 0.58, size.height * 0.36),
          size.width * 0.028,
          Paint()..color = Colors.black,
        );
        // Golden beak
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(size.width * 0.5, size.height * 0.44),
            width: size.width * 0.24,
            height: size.height * 0.11,
          ),
          Paint()..color = const Color(0xFFF59E0B),
        );

      case AvatarVisualPreset.nixosflake:
        final bgPaint = Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
          ).createShader(rect);
        canvas.drawRect(rect, bgPaint);
        final stroke = Paint()
          ..color = const Color(0xFF38BDF8)
          ..strokeWidth = 2.2
          ..style = PaintingStyle.stroke;
        canvas.drawCircle(
          Offset(size.width * 0.5, size.height * 0.5),
          size.width * 0.26,
          stroke,
        );
    }
  }

  @override
  bool shouldRepaint(covariant _AvatarArtPainter oldDelegate) =>
      oldDelegate.preset != preset;
}
