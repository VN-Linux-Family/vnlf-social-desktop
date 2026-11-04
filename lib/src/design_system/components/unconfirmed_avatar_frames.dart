// UNCONFIRMED SITE-ORIGINAL COSMETIC EFFECTS - UNKNOWN OWNERSHIP - DO NOT EXPORT FROM BARREL
//
// These procedural canvas effects replicate gamified avatar animations seen on the website.
// They are NOT confirmed by public API docs or licensed by the site owners.
// Kept in this isolated file for Phase 3 evaluation; NOT exported from the design system barrel.

import 'package:flutter/material.dart';

/// Legacy unconfirmed neon gradient glow frame.
class NeonAvatarFramePainter extends CustomPainter {
  const NeonAvatarFramePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: size.width / 2);
    final paint = Paint()
      ..shader = const SweepGradient(
        colors: [
          Color(0xFF0284C7),
          Color(0xFF38BDF8),
          Color(0xFF2563EB),
          Color(0xFF06B6D4),
          Color(0xFF0284C7),
        ],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, (size.width - 2) / 2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Legacy unconfirmed matrix digital rain frame.
class MatrixAvatarFramePainter extends CustomPainter {
  const MatrixAvatarFramePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = const Color(0xFF10B981)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, (size.width - 2) / 2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Legacy unconfirmed twinkling stars frame.
class StarsAvatarFramePainter extends CustomPainter {
  const StarsAvatarFramePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, (size.width - 2) / 2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
