import 'package:flutter/material.dart';

/// Launcher-icon-specific `CustomPainter`s (05-04-PLAN.md Task 1).
///
/// Both painters restate a subset of `SunrisePainter`'s (private) palette
/// hexes rather than importing them, since those constants are
/// library-private to `lib/scenes/sunrise/sunrise_painter.dart`. This is the
/// scene-matched Night-to-Sunrise palette per D-02 -- NOT the app's flat
/// warm-cream UI background token, and NOT an arbitrary new hex.
///
/// Deliberately kept far simpler than the real scene: no stars, no moon, no
/// per-frame progress -- these render a single fixed "bright sunrise"
/// moment as a static icon source (D-03: big, simple, generously padded so
/// the shape survives circle/squircle adaptive-icon masking and stays
/// legible at 48dp).

/// Fills the canvas with a vertical gradient reproducing the Night to
/// Sunrise scene's sky at a bright, high-progress moment (D-02): a
/// scene-matched gradient, not a flat color.
class IconBackgroundPainter extends CustomPainter {
  const IconBackgroundPainter();

  // Restated from SunrisePainter's high-progress (bright sunrise) sky
  // lerp targets -- see lib/scenes/sunrise/sunrise_painter.dart.
  static const Color _skyTop = Color(0xFF8FC9EA);
  static const Color _skyBottom = Color(0xFFFFDBA6);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_skyTop, _skyBottom],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant IconBackgroundPainter oldDelegate) => false;
}

/// Paints one dominant, simple shape: a large sun disc using the scene's
/// sun gradient colors, centered and generously padded (D-03), with a soft
/// glow and a single simple hill arc for silhouette character. Transparent
/// elsewhere so the background layer shows through the adaptive mask.
class IconForegroundPainter extends CustomPainter {
  const IconForegroundPainter();

  // Restated from SunrisePainter's sun RadialGradient colors.
  static const Color _sunGradientStart = Color(0xFFFFE9AE);
  static const Color _sunGradientEnd = Color(0xFFF3AE44);
  static const Color _hillColor = Color(0xFF6E9060);

  // Sun radius as a fraction of canvas width -- kept within the 30-34%
  // range so the disc survives circle/squircle safe-zone masking and
  // still reads clearly at 48dp (D-03).
  static const double _sunRadiusFraction = 0.32;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.46);
    final sunRadius = size.width * _sunRadiusFraction;

    // Soft glow behind the sun disc.
    final glowSigma = 40 * 0.57735 + 0.5;
    canvas.drawCircle(
      center,
      sunRadius * 1.25,
      Paint()
        ..color = const Color.fromRGBO(247, 193, 91, 0.45)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowSigma),
    );

    // The dominant sun disc itself.
    canvas.drawCircle(
      center,
      sunRadius,
      Paint()
        ..shader = RadialGradient(
          colors: const [_sunGradientStart, _sunGradientEnd],
        ).createShader(Rect.fromCircle(center: center, radius: sunRadius)),
    );

    // A single simple hill arc at the very bottom for silhouette
    // character -- kept minimal, no fine scene fidelity.
    final hillRect = Rect.fromLTRB(
      -size.width * 0.25,
      size.height * 0.86,
      size.width * 1.25,
      size.height * 1.25,
    );
    canvas.drawOval(hillRect, Paint()..color = _hillColor);
  }

  @override
  bool shouldRepaint(covariant IconForegroundPainter oldDelegate) => false;
}
