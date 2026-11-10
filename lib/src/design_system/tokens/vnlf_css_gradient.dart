import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// CSS `linear-gradient(<angle>deg, …)`, which the website's tinted cards use.
///
/// The gradient line runs through the box's centre at [angle] degrees
/// clockwise from "to top", and is just long enough for the far corners to
/// take the first and last colours. Flutter's [LinearGradient] runs between
/// two alignments instead, so it only matches CSS on a square box.
@immutable
final class VnlfCssGradient extends Gradient {
  const VnlfCssGradient({
    required this.angle,
    required super.colors,
    super.stops,
  });

  /// Degrees, as in CSS: 0 points up, 90 right, 180 down.
  final double angle;

  @override
  ui.Shader createShader(Rect rect, {TextDirection? textDirection}) {
    final radians = angle * math.pi / 180;
    final direction = Offset(math.sin(radians), -math.cos(radians));
    final half =
        (rect.width * direction.dx.abs() + rect.height * direction.dy.abs()) /
        2;
    return ui.Gradient.linear(
      rect.center - direction * half,
      rect.center + direction * half,
      colors,
      stops ??
          [
            for (var index = 0; index < colors.length; index++)
              index / (colors.length - 1),
          ],
    );
  }

  @override
  VnlfCssGradient scale(double factor) => VnlfCssGradient(
    angle: angle,
    colors: [for (final color in colors) Color.lerp(null, color, factor)!],
    stops: stops,
  );

  @override
  VnlfCssGradient withOpacity(double opacity) => VnlfCssGradient(
    angle: angle,
    colors: [
      for (final color in colors) color.withValues(alpha: color.a * opacity),
    ],
    stops: stops,
  );

  @override
  bool operator ==(Object other) =>
      other is VnlfCssGradient &&
      other.angle == angle &&
      listEquals(other.colors, colors) &&
      listEquals(other.stops, stops);

  @override
  int get hashCode => Object.hash(
    angle,
    Object.hashAll(colors),
    stops == null ? null : Object.hashAll(stops!),
  );
}
