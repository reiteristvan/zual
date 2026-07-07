import 'dart:math';

import 'package:flutter/material.dart';

/// Pure sunrise formulas, locked verbatim from `design/README.md` §"D.
/// Running — Night to Sunrise" (final per D-01) and transcribed exactly in
/// `03-UI-SPEC.md`'s Night to Sunrise Geometry table. Star/moon opacity are
/// clamped per Pitfall 3: the raw `1 - p*k` forms go negative well before
/// `progress == 1` and would otherwise assert-crash `Color.withValues`.
double starOpacity(double progress) => (1 - progress * 2.3).clamp(0.0, 1.0);
double moonOpacity(double progress) => (1 - progress * 1.7).clamp(0.0, 1.0);

/// `top = (86 - p*64)%`, i.e. 86% of height at `p=0` down to 22% at `p=1`.
double sunTopFraction(double progress) => (86 - progress * 64) / 100;

/// Hill silhouette color, lerping night-blue to warm green as the sun rises.
Color hillColor(double progress) =>
    Color.lerp(const Color(0xFF26314F), const Color(0xFF6E9060), progress)!;

/// Paints the Night to Sunrise scene (SCENE-02): a progress-driven gradient
/// sky, 28 twinkling stars, a fading moon, a rising glowing sun, and a
/// warming hill silhouette. `progress` and `twinklePhase` (the shared
/// per-scene ticker's twinkle-loop phase, `03-RESEARCH.md` Pattern 1/2) are
/// the only two time-varying inputs this painter reads -- see
/// `03-UI-SPEC.md` §D.
class SunrisePainter extends CustomPainter {
  SunrisePainter({required this.progress, required this.twinklePhase})
    : _starPaint = Paint()..color = Colors.white,
      _moonPaint = Paint()..color = _moonColor,
      _moonGlowPaint = Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, _moonGlowSigma),
      _hillPaint = Paint();

  /// 0..1, already clamped upstream by [TimerController] but re-clamped
  /// defensively inside each pure formula (threat register T-03-03).
  final double progress;

  /// 0..1 decorative-loop phase for the 3s twinkle cycle, sourced from the
  /// scene's shared ticker (`SceneRendererState.loopPhase`) -- never a
  /// second `AnimationController`.
  final double twinklePhase;

  final Paint _starPaint;
  final Paint _moonPaint;
  final Paint _moonGlowPaint;
  final Paint _hillPaint;

  static const Color _skyTopStart = Color(0xFF182449);
  static const Color _skyTopEnd = Color(0xFF8FC9EA);
  static const Color _skyBottomStart = Color(0xFF3A2F5C);
  static const Color _skyBottomEnd = Color(0xFFFFDBA6);
  static const Color _moonColor = Color(0xFFEDE7D6);
  static const Color _sunGradientStart = Color(0xFFFFE9AE);
  static const Color _sunGradientEnd = Color(0xFFF3AE44);

  static const int _starCount = 28;
  static const double _starSize = 4;
  static const double _moonSize = 72;
  static const double _sunSize = 130;
  static const double _sunRadius = _sunSize / 2;
  static const double _hillHeight = 210;
  static const double _hillBottomOverhang = 70;

  /// CSS `0 0 30px rgba(...)` glow blur radius converted to a Gaussian
  /// sigma via the same `radius*0.57735+0.5` conversion used elsewhere in
  /// this codebase (`DiscPainter._shadowSigma`).
  static const double _moonGlowSigma = 30 * 0.57735 + 0.5;

  @override
  void paint(Canvas canvas, Size size) {
    _paintSky(canvas, size);
    _paintStars(canvas, size);
    _paintMoon(canvas, size);
    _paintSun(canvas, size);
    _paintHill(canvas, size);
  }

  void _paintSky(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    // Sky colors are progress-driven every frame -- cannot be cached as a
    // field, per `03-RESEARCH.md` Pitfall 5's explicit exception for this
    // scene's gradient.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(_skyTopStart, _skyTopEnd, progress)!,
            Color.lerp(_skyBottomStart, _skyBottomEnd, progress)!,
          ],
        ).createShader(rect),
    );
  }

  void _paintStars(Canvas canvas, Size size) {
    final layerFade = starOpacity(progress);
    if (layerFade <= 0.0) return;

    for (var i = 0; i < _starCount; i++) {
      final left = size.width * ((i * 37) % 100) / 100;
      final top = size.height * (4 + (i * 53) % 44) / 100;
      final base = 0.55 + ((i * 13) % 40) / 90;

      // Staggered per-star delay: `(i % 6) * 0.5s` within the shared 3s
      // twinkle period, per `03-UI-SPEC.md`'s Decorative Loop Contract.
      final stagger = (i % 6) * 0.5 / 3.0;
      final starPhase = (twinklePhase + stagger) % 1.0;
      final twinkle = 0.35 + 0.65 * (0.5 - 0.5 * cos(2 * pi * starPhase));

      final alpha = (base * twinkle * layerFade).clamp(0.0, 1.0);

      canvas.drawRect(
        Rect.fromLTWH(left, top, _starSize, _starSize),
        _starPaint..color = Colors.white.withValues(alpha: alpha),
      );
    }
  }

  void _paintMoon(Canvas canvas, Size size) {
    final alpha = moonOpacity(progress);
    if (alpha <= 0.0) return;

    final left = size.width * (1 - 0.18) - _moonSize;
    final top = size.height * 0.12;
    final center = Offset(left + _moonSize / 2, top + _moonSize / 2);
    const radius = _moonSize / 2;

    canvas.drawCircle(
      center,
      radius + 4,
      _moonGlowPaint..color = _moonColor.withValues(alpha: 0.5 * alpha),
    );
    canvas.drawCircle(
      center,
      radius,
      _moonPaint..color = _moonColor.withValues(alpha: alpha),
    );
  }

  void _paintSun(Canvas canvas, Size size) {
    final top = size.height * sunTopFraction(progress);
    final center = Offset(size.width * 0.5, top);

    // Glow-growth formula transcribed verbatim from `Zual.dc.html` (not
    // stated in `design/README.md`), per `03-UI-SPEC.md` §D.
    final blur = 40 + progress * 90;
    final spread = 12 + progress * 46;
    final glowAlpha = (0.3 + progress * 0.5).clamp(0.0, 1.0);
    final glowSigma = blur * 0.57735 + 0.5;

    canvas.drawCircle(
      center,
      _sunRadius + spread,
      Paint()
        ..color = Color.fromRGBO(247, 193, 91, glowAlpha)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowSigma),
    );

    canvas.drawCircle(
      center,
      _sunRadius,
      Paint()
        ..shader = RadialGradient(
          colors: const [_sunGradientStart, _sunGradientEnd],
        ).createShader(Rect.fromCircle(center: center, radius: _sunRadius)),
    );
  }

  void _paintHill(Canvas canvas, Size size) {
    // width = 150% of screen (left -25%, right -25%); bottom edge sits
    // `_hillBottomOverhang` below the screen's bottom edge; height 210px.
    // Drawn as an oval so a very wide, short bounding rect naturally reads
    // as a flat hill horizon (its top arc), per `03-UI-SPEC.md` §D.
    final rect = Rect.fromLTRB(
      -size.width * 0.25,
      size.height - _hillHeight + _hillBottomOverhang,
      size.width * 1.25,
      size.height + _hillBottomOverhang,
    );
    canvas.drawOval(rect, _hillPaint..color = hillColor(progress));
  }

  @override
  bool shouldRepaint(covariant SunrisePainter oldDelegate) {
    return progress != oldDelegate.progress ||
        twinklePhase != oldDelegate.twinklePhase;
  }
}
