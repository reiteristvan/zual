import 'dart:math';

import 'package:flutter/material.dart';

import '../../theme/app_tokens.dart';

/// Pure disc color-zone function, locked verbatim from `design/README.md`
/// §"C. Running — Shrinking Disc" (final per D-01) and transcribed exactly
/// in `03-UI-SPEC.md`'s Shrinking Disc color table:
///
/// - `remaining > 0.5`: pure green.
/// - `0.2 < remaining <= 0.5`: yellow -> green lerp, `t = (remaining-0.2)/0.3`.
/// - `remaining <= 0.2`: red -> yellow lerp, `t = remaining/0.2`.
///
/// The two lerp branches are continuous at their shared `remaining == 0.2`
/// boundary (both evaluate to pure yellow there) and at `remaining == 0.5`
/// (both evaluate to pure green) -- no color ever jumps discontinuously as
/// `remaining` decreases. Pure red is reached only at `remaining == 0`
/// (`progress == 1`), matching this plan's `done` criterion ("At progress=1
/// the disc is ... colored pure red").
Color discColorForRemaining(double remaining) {
  const green = Color(0xFF7FA87A);
  const yellow = Color(0xFFE8B75A);
  const red = Color(0xFFDE6A4B);

  if (remaining > 0.5) return green;
  if (remaining > 0.2) {
    final t = (remaining - 0.2) / (0.5 - 0.2);
    return Color.lerp(yellow, green, t)!;
  }
  final t = remaining / 0.2;
  return Color.lerp(red, yellow, t)!;
}

/// Paints the Shrinking Disc scene (SCENE-01): a centered dashed track ring
/// plus a filled circle whose radius and color are pure functions of
/// [progress]. `progress` is the only time-varying input this painter reads
/// (SCENE-05's "progress in, pixels out" contract) -- see `03-UI-SPEC.md`
/// §C.
class DiscPainter extends CustomPainter {
  DiscPainter({required this.progress})
    : _backgroundPaint = Paint()..color = AppTokens.bg,
      _trackPaint = Paint()
        ..color = const Color(0x244B4038)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
      _shadowPaint = Paint()
        ..color = const Color(0x1A000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, _shadowSigma);

  /// 0..1, already clamped upstream by [TimerController], re-clamped
  /// defensively in [paint] per the threat register's T-03-01 mitigation.
  final double progress;

  final Paint _backgroundPaint;
  final Paint _trackPaint;
  final Paint _shadowPaint;

  /// Radius for the 310px-diameter dashed track ring, per `03-UI-SPEC.md` §C.
  static const double _trackRadius = 155;

  /// Radius for the 300px-diameter disc at `remaining == 1`, per §C.
  static const double _discBaseRadius = 150;

  static const double _shadowOffsetY = 20;
  static const double _dashLength = 6;
  static const double _dashGap = 5;

  /// Gaussian sigma equivalent to a CSS-style 55px blur radius, using the
  /// same `radius * 0.57735 + 0.5` conversion `BoxShadow` applies internally
  /// (`kBlurSigmaScale` / `convertRadiusToSigma`), inlined as a `const`
  /// since that conversion is not exposed as a `const`-callable API.
  static const double _shadowSigma = 55 * 0.57735 + 0.5;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, _backgroundPaint);

    final center = size.center(Offset.zero);
    final remaining = (1 - progress).clamp(0.0, 1.0);

    _drawDashedRing(canvas, center);

    // The 0.001 floor (from `Zual.dc.html`) avoids a degenerate zero-radius
    // draw call once remaining reaches exactly 0 at progress=1.
    final discRadius = _discBaseRadius * max(0.001, remaining);

    canvas.drawCircle(
      center + const Offset(0, _shadowOffsetY),
      discRadius,
      _shadowPaint,
    );
    canvas.drawCircle(
      center,
      discRadius,
      Paint()..color = discColorForRemaining(remaining),
    );
  }

  void _drawDashedRing(Canvas canvas, Offset center) {
    const period = _dashLength + _dashGap;
    final circumference = 2 * pi * _trackRadius;
    final dashCount = (circumference / period).floor();
    if (dashCount <= 0) return;

    final anglePerDash = 2 * pi / dashCount;
    final dashAngle = anglePerDash * (_dashLength / period);
    final rect = Rect.fromCircle(center: center, radius: _trackRadius);

    for (var i = 0; i < dashCount; i++) {
      canvas.drawArc(rect, i * anglePerDash, dashAngle, false, _trackPaint);
    }
  }

  @override
  bool shouldRepaint(covariant DiscPainter oldDelegate) {
    return progress != oldDelegate.progress;
  }
}
