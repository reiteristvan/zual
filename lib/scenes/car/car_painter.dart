import 'package:flutter/material.dart';

import '../walk/walk_painter.dart' show arrivalLeftFraction;

/// Paints the Car on a Road scene (SCENE-04): a static sky/road/house
/// backdrop plus a car whose horizontal position is a pure function of
/// [progress] -- via the shared [arrivalLeftFraction] imported from
/// `walk_painter.dart` (one arrival formula, never redefined, per
/// `03-RESEARCH.md`) -- and whose wheels spin continuously per [spinAngle],
/// the shared per-scene ticker's decorative-loop phase (`03-RESEARCH.md`
/// Pattern 2), never a second `AnimationController`. See `03-UI-SPEC.md` §F.
class CarPainter extends CustomPainter {
  CarPainter({required this.progress, required this.spinAngle})
    : _roadPaint = Paint()..color = const Color(0xFF5A5048),
      _dashPaint = Paint()
        ..color = const Color(0xFFE9D9B8)
        ..style = PaintingStyle.fill,
      _roofPaint = Paint()..color = const Color(0xFFC98A5E),
      _houseBodyPaint = Paint()..color = const Color(0xFFEAD7B8),
      _doorPaint = Paint()..color = const Color(0xFFB5794E),
      _carShadowPaint = Paint()
        ..color = const Color(0x26000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, _carShadowSigma),
      _carBodyPaint = Paint()..color = const Color(0xFFDE6A4B),
      _carWindowPaint = Paint()..color = const Color(0xFFF0B49B),
      _headlightPaint = Paint()..color = const Color(0xFFFFE9AE),
      _wheelRimPaint = Paint()..color = const Color(0xFF3A3230),
      _wheelTirePaint = Paint()
        ..color = const Color(0xFF6B5E58)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6,
      _wheelSpokePaint = Paint()
        ..color = const Color(0xFF6B5E58)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;

  /// 0..1, already clamped upstream but re-clamped defensively inside
  /// [arrivalLeftFraction].
  final double progress;

  /// Continuous wheel-rotation angle in radians, derived from the scene's
  /// shared ticker's 0.7s spin-loop phase (`SceneRendererState.loopPhase`).
  final double spinAngle;

  // Progress-/spinAngle-independent Paints, cached once per painter
  // instance (`03-RESEARCH.md` Pitfall 5).
  final Paint _roadPaint;
  final Paint _dashPaint;
  final Paint _roofPaint;
  final Paint _houseBodyPaint;
  final Paint _doorPaint;
  final Paint _carShadowPaint;
  final Paint _carBodyPaint;
  final Paint _carWindowPaint;
  final Paint _headlightPaint;
  final Paint _wheelRimPaint;
  final Paint _wheelTirePaint;
  final Paint _wheelSpokePaint;

  // The sky gradient is static (not progress-driven) but its shader depends
  // on canvas `size`, so it is cached lazily and only rebuilt if `size`
  // changes -- per Pitfall 5, mirroring `WalkPainter`.
  Paint? _skyPaint;
  Size? _skyPaintSize;

  static const Color _skyTop = Color(0xFFF6D9A8);
  static const Color _skyMid = Color(0xFFF5E4C4);
  static const Color _skyBottom = Color(0xFFEFDCBC);

  static const double _roadHeightFraction = 0.32;
  static const double _dashHeight = 6;
  static const double _dashBottomFraction = 0.16;

  /// `bottom: 16% - 3px`.
  static const double _dashBottomExtraPx = -3;
  static const double _dashOn = 26;
  static const double _dashOff = 26;

  static const double _houseBodyWidth = 112;
  static const double _houseBodyHeight = 88;
  static const double _houseRoofHalfBase = 70;
  static const double _houseRoofHeight = 48;
  static const double _houseRightInset = 26;

  /// `bottom: 32% - 2px`.
  static const double _houseBottomExtraPx = -2;

  /// `bottom: 16% + 6px`.
  static const double _carBottomExtraPx = 6;
  static const double _carBodyWidth = 110;
  static const double _carBodyHeight = 42;
  static const double _carWindowWidth = 56;
  static const double _carWindowHeight = 26;
  static const double _wheelDiameter = 28;

  /// CSS `0 4px 10px rgba(0,0,0,0.15)` blur radius converted to a Gaussian
  /// sigma via the same `radius*0.57735+0.5` conversion used elsewhere in
  /// this codebase (`DiscPainter._shadowSigma`).
  static const double _carShadowSigma = 10 * 0.57735 + 0.5;

  Paint _skyPaintFor(Size size) {
    if (_skyPaintSize != size) {
      final rect = Offset.zero & size;
      _skyPaint = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_skyTop, _skyMid, _skyBottom],
          stops: [0.0, 0.55, 0.66],
        ).createShader(rect);
      _skyPaintSize = size;
    }
    return _skyPaint!;
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, _skyPaintFor(size));
    _paintRoad(canvas, size);
    _paintDashedLine(canvas, size);
    _paintHouse(canvas, size);
    _paintCar(canvas, size);
  }

  void _paintRoad(Canvas canvas, Size size) {
    final roadHeight = size.height * _roadHeightFraction;
    canvas.drawRect(
      Rect.fromLTWH(0, size.height - roadHeight, size.width, roadHeight),
      _roadPaint,
    );
  }

  void _paintDashedLine(Canvas canvas, Size size) {
    final bottomY = _bottomY(size, _dashBottomFraction, _dashBottomExtraPx);
    final rect = Rect.fromLTWH(0, bottomY - _dashHeight, size.width, _dashHeight);

    var x = 0.0;
    while (x < size.width) {
      final dashWidth = (x + _dashOn <= size.width) ? _dashOn : size.width - x;
      canvas.drawRect(
        Rect.fromLTWH(x, rect.top, dashWidth, _dashHeight),
        _dashPaint,
      );
      x += _dashOn + _dashOff;
    }
  }

  /// Bottom edge, in canvas coordinates, for an element positioned via
  /// CSS-style `bottom: <fraction of height> + <extraPx>` (extraPx may be
  /// negative, e.g. `32% - 2px`).
  double _bottomY(Size size, double bottomFraction, double extraPx) =>
      size.height - (size.height * bottomFraction + extraPx);

  void _paintHouse(Canvas canvas, Size size) {
    final groupBottomY =
        _bottomY(size, _roadHeightFraction, _houseBottomExtraPx);
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

    final roofBaseY = bodyRect.top;
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
      bodyRect.bottom - 50,
      36,
      50,
    );
    canvas.drawRect(doorRect, _doorPaint);
  }

  void _paintCar(Canvas canvas, Size size) {
    final carBottomY = _bottomY(size, _dashBottomFraction, _carBottomExtraPx);
    final carCenterX = size.width * arrivalLeftFraction(progress);

    final bodyRect = Rect.fromLTWH(
      carCenterX - _carBodyWidth / 2,
      carBottomY - _carBodyHeight,
      _carBodyWidth,
      _carBodyHeight,
    );
    final bodyRRect = RRect.fromRectAndCorners(
      bodyRect,
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: const Radius.circular(12),
      bottomRight: const Radius.circular(12),
    );

    canvas.drawRRect(
      bodyRRect.shift(const Offset(0, 4)),
      _carShadowPaint,
    );
    canvas.drawRRect(bodyRRect, _carBodyPaint);

    final windowRect = Rect.fromLTWH(
      bodyRect.left + 24,
      bodyRect.top - 20,
      _carWindowWidth,
      _carWindowHeight,
    );
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        windowRect,
        topLeft: const Radius.circular(14),
        topRight: const Radius.circular(14),
      ),
      _carWindowPaint,
    );

    // 8x8 circle, box right edge at `right: 12` / top edge at `top: 14`
    // within body -- center is the box's top-right corner offset by half
    // the 8px diameter in each axis.
    canvas.drawCircle(
      Offset(bodyRect.right - 12 - 4, bodyRect.top + 14 + 4),
      4,
      _headlightPaint,
    );

    // Wheels: `bottom: -11px` (i.e. the wheel's own bottom edge sits 11px
    // *below* the car group's bottom edge -- wheels visibly protrude below
    // the body) and `left: 16px` / `left: 66px` within the group -- convert
    // each box position to a center by offsetting half the 28px diameter.
    const wheelRadius = _wheelDiameter / 2;
    final wheelCenterY = bodyRect.bottom + 11 - wheelRadius;
    _paintWheel(canvas, Offset(bodyRect.left + 16 + wheelRadius, wheelCenterY));
    _paintWheel(canvas, Offset(bodyRect.left + 66 + wheelRadius, wheelCenterY));
  }

  void _paintWheel(Canvas canvas, Offset center) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(spinAngle);
    canvas.drawCircle(Offset.zero, _wheelDiameter / 2 - 3, _wheelRimPaint);
    canvas.drawCircle(Offset.zero, _wheelDiameter / 2 - 3, _wheelTirePaint);
    // Deliberate, user-approved fidelity deviation from `design/Zual.dc.html`:
    // the source wheel is a rotationally symmetric circle (spin invisible
    // even there), so a spoke marking is added here, reusing only the
    // already-locked tire color, to make the 0.7s spin actually observable
    // (CR-01 / Truth #8 / SCENE-04).
    canvas.drawLine(
      Offset.zero,
      Offset(0, -(_wheelDiameter / 2 - 3)),
      _wheelSpokePaint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CarPainter oldDelegate) {
    return progress != oldDelegate.progress ||
        spinAngle != oldDelegate.spinAngle;
  }
}
