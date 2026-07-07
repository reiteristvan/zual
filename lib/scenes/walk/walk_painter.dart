import 'dart:math';

import 'package:flutter/material.dart';

/// `left = (6 + p*62)%`, the arrival mechanic shared by Walking Home
/// (SCENE-03) and Car on a Road (SCENE-04): distance remaining visibly
/// tracks time remaining, locked verbatim from `design/README.md` §§E/F
/// (final per D-01) and `03-UI-SPEC.md`'s Arrival Mechanic section.
///
/// [progress] is already clamped to 0..1 upstream by [TimerController], but
/// re-clamped here defensively per the threat register's T-03-05 mitigation
/// and `03-RESEARCH.md` Pattern 3, since this pure function may gain other
/// call sites (e.g. a scene preview) in the future.
double arrivalLeftFraction(double progress) =>
    (6 + progress.clamp(0.0, 1.0) * 62) / 100;

/// Paints the Walking Home scene (SCENE-03): a static sky/ground/path/house
/// backdrop plus a character whose horizontal position is a pure function of
/// [progress] (via [arrivalLeftFraction]) and whose vertical bob offset is a
/// pure function of [bobPhase] -- the shared per-scene ticker's decorative-
/// loop phase (`03-RESEARCH.md` Pattern 2), never a second
/// `AnimationController`. See `03-UI-SPEC.md` §E.
class WalkPainter extends CustomPainter {
  WalkPainter({required this.progress, required this.bobPhase})
    : _cloud1Paint = Paint()..color = const Color.fromRGBO(255, 255, 255, 0.7),
      _cloud2Paint = Paint()..color = const Color.fromRGBO(255, 255, 255, 0.6),
      _groundPaint = Paint()..color = const Color(0xFFCFE0A8),
      _pathPaint = Paint()..color = const Color(0xFFE4D3A6),
      _roofPaint = Paint()..color = const Color(0xFFC98A5E),
      _houseBodyPaint = Paint()..color = const Color(0xFFEAD7B8),
      _doorPaint = Paint()..color = const Color(0xFFB5794E),
      _windowPaint = Paint()..color = const Color(0xFFF6D9A8),
      _headPaint = Paint()..color = const Color(0xFFF0C9A0),
      _eyePaint = Paint()..color = const Color(0xFF4B4038),
      _characterBodyPaint = Paint()..color = const Color(0xFFE0805F);

  /// 0..1, already clamped upstream but re-clamped defensively inside
  /// [arrivalLeftFraction].
  final double progress;

  /// 0..1 decorative-loop phase for the 0.62s bob cycle, sourced from the
  /// scene's shared ticker (`SceneRendererState.loopPhase`).
  final double bobPhase;

  // Progress-/bobPhase-independent Paints, cached once per painter instance
  // (`03-RESEARCH.md` Pitfall 5).
  final Paint _cloud1Paint;
  final Paint _cloud2Paint;
  final Paint _groundPaint;
  final Paint _pathPaint;
  final Paint _roofPaint;
  final Paint _houseBodyPaint;
  final Paint _doorPaint;
  final Paint _windowPaint;
  final Paint _headPaint;
  final Paint _eyePaint;
  final Paint _characterBodyPaint;

  // The sky gradient is static (not progress-driven) but its shader depends
  // on canvas `size`, so it is cached lazily and only rebuilt if `size`
  // changes (e.g. an orientation change) -- per Pitfall 5 and the plan's
  // explicit "cache the shader/Paint" instruction for this static sky.
  Paint? _skyPaint;
  Size? _skyPaintSize;

  static const Color _skyTop = Color(0xFFBFE0EE);
  static const Color _skyMid = Color(0xFFDCEAEF);
  static const Color _skyBottom = Color(0xFFE9F2E0);

  static const double _groundHeightFraction = 0.34;
  static const double _pathHeight = 22;
  static const double _pathBottomFraction = 0.20;

  static const double _houseBodyWidth = 112;
  static const double _houseBodyHeight = 92;
  static const double _houseRoofHalfBase = 70;
  static const double _houseRoofHeight = 48;
  static const double _houseRightInset = 26;
  static const double _houseBottomExtraPx = 6;

  static const double _characterBottomExtraPx = 10;
  static const double _characterHeadSize = 38;
  static const double _characterBodyWidth = 50;
  static const double _characterBodyHeight = 52;
  static const double _characterHeadBodyOverlap = 8;
  static const double _bobAmplitude = 7;

  Paint _skyPaintFor(Size size) {
    if (_skyPaintSize != size) {
      final rect = Offset.zero & size;
      _skyPaint = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_skyTop, _skyMid, _skyBottom],
          stops: [0.0, 0.45, 0.63],
        ).createShader(rect);
      _skyPaintSize = size;
    }
    return _skyPaint!;
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, _skyPaintFor(size));
    _paintClouds(canvas, size);
    _paintGround(canvas, size);
    _paintPath(canvas, size);
    _paintHouse(canvas, size);
    _paintCharacter(canvas, size);
  }

  void _paintClouds(Canvas canvas, Size size) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(40, 80, 70, 26),
        const Radius.circular(20),
      ),
      _cloud1Paint,
    );
    // Cloud 2: right = 50px, top = 150px, 54x20 -- right-anchored, so its
    // left edge depends on canvas width.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width - 50 - 54, 150, 54, 20),
        const Radius.circular(16),
      ),
      _cloud2Paint,
    );
  }

  void _paintGround(Canvas canvas, Size size) {
    final groundHeight = size.height * _groundHeightFraction;
    canvas.drawRect(
      Rect.fromLTWH(0, size.height - groundHeight, size.width, groundHeight),
      _groundPaint,
    );
  }

  void _paintPath(Canvas canvas, Size size) {
    final bottomY = size.height * (1 - _pathBottomFraction);
    canvas.drawRect(
      Rect.fromLTWH(0, bottomY - _pathHeight, size.width, _pathHeight),
      _pathPaint,
    );
  }

  /// Bottom edge, in canvas coordinates, for an element positioned via
  /// CSS-style `bottom: <fraction of height> + <extraPx>`.
  double _bottomY(Size size, double bottomFraction, double extraPx) =>
      size.height - (size.height * bottomFraction + extraPx);

  void _paintHouse(Canvas canvas, Size size) {
    final groupBottomY =
        _bottomY(size, _pathBottomFraction, _houseBottomExtraPx);
    final groupRight = size.width - _houseRightInset;

    final bodyRect = Rect.fromLTWH(
      groupRight - _houseBodyWidth,
      groupBottomY - _houseBodyHeight,
      _houseBodyWidth,
      _houseBodyHeight,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, const Radius.circular(10)),
      _houseBodyPaint,
    );

    // Roof overlaps 2px into the body per the plan.
    final roofBaseY = bodyRect.top + 2;
    final roofApexY = roofBaseY - _houseRoofHeight;
    final roofCenterX = bodyRect.center.dx;
    final roofPath = Path()
      ..moveTo(roofCenterX - _houseRoofHalfBase, roofBaseY)
      ..lineTo(roofCenterX + _houseRoofHalfBase, roofBaseY)
      ..lineTo(roofCenterX, roofApexY)
      ..close();
    canvas.drawPath(roofPath, _roofPaint);

    final doorRect = Rect.fromLTWH(
      bodyRect.center.dx - 18,
      bodyRect.bottom - 52,
      36,
      52,
    );
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        doorRect,
        topLeft: const Radius.circular(10),
        topRight: const Radius.circular(10),
      ),
      _doorPaint,
    );

    final windowRect = Rect.fromLTWH(
      bodyRect.left + 16,
      bodyRect.top + 16,
      22,
      22,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(windowRect, const Radius.circular(5)),
      _windowPaint,
    );
  }

  void _paintCharacter(Canvas canvas, Size size) {
    // ease-in-out via a cosine bell: 0 -> -amplitude -> 0 over the loop.
    final bobOffset = -_bobAmplitude * (0.5 - 0.5 * cos(2 * pi * bobPhase));

    final characterBottomY =
        _bottomY(size, _pathBottomFraction, _characterBottomExtraPx) +
            bobOffset;
    final characterCenterX = size.width * arrivalLeftFraction(progress);

    final bodyRect = Rect.fromLTWH(
      characterCenterX - _characterBodyWidth / 2,
      characterBottomY - _characterBodyHeight,
      _characterBodyWidth,
      _characterBodyHeight,
    );
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        bodyRect,
        topLeft: const Radius.circular(24),
        topRight: const Radius.circular(24),
        bottomLeft: const Radius.circular(16),
        bottomRight: const Radius.circular(16),
      ),
      _characterBodyPaint,
    );

    final headBottomY = bodyRect.top + _characterHeadBodyOverlap;
    final headTopY = headBottomY - _characterHeadSize;
    final headCenter = Offset(
      characterCenterX,
      headTopY + _characterHeadSize / 2,
    );
    canvas.drawCircle(headCenter, _characterHeadSize / 2, _headPaint);

    final headLeft = characterCenterX - _characterHeadSize / 2;
    final eyeY = headTopY + 14 + 2.5;
    canvas.drawCircle(Offset(headLeft + 9 + 2.5, eyeY), 2.5, _eyePaint);
    canvas.drawCircle(
      Offset(headLeft + _characterHeadSize - 9 - 2.5, eyeY),
      2.5,
      _eyePaint,
    );
  }

  @override
  bool shouldRepaint(covariant WalkPainter oldDelegate) {
    return progress != oldDelegate.progress ||
        bobPhase != oldDelegate.bobPhase;
  }
}
