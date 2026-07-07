import 'package:flutter/material.dart';

/// Shared contract every scene's mini-preview painter implements, so
/// `SceneCard`/`SceneGrid` depend only on this abstraction — never on any
/// theme's literal painting details (D-06). Phase 3 extends this same base
/// for the real "scene rendered at progress=0" renderer, mirroring
/// [ScreenWake]'s interface-then-adapter shape.
///
/// [ScreenWake]: package:zual/timer/screen_wake.dart
abstract class ScenePreviewPainter extends CustomPainter {
  const ScenePreviewPainter();
}

/// Static mini-preview for the Shrinking Disc theme: a flat background with
/// a centered accent-colored disc and soft drop shadow.
///
/// Colors/geometry transcribed verbatim from `02-UI-SPEC.md`'s Scene
/// Mini-Preview table (D-05: no animation, `shouldRepaint` is always false).
class DiscPreviewPainter extends ScenePreviewPainter {
  const DiscPreviewPainter();

  static const Color _background = Color(0xFFF3E8D6);
  static const Color _discColor = Color(0xFF7FA87A);

  /// `rgba(127,168,122,0.4)`.
  static const Color _shadowColor = Color(0x667FA87A);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = _background);

    final center = size.center(Offset.zero);
    const radius = 22.0; // 44px diameter.

    final shadowPaint = Paint()
      ..color = _shadowColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(center + const Offset(0, 3), radius, shadowPaint);

    canvas.drawCircle(center, radius, Paint()..color = _discColor);
  }

  @override
  bool shouldRepaint(covariant DiscPreviewPainter oldDelegate) => false;
}

/// Static mini-preview for the Night to Sunrise theme: a night->day vertical
/// gradient sky, two star dots, and a centered-bottom glowing sun.
class SunrisePreviewPainter extends ScenePreviewPainter {
  const SunrisePreviewPainter();

  static const List<Color> _skyColors = [
    Color(0xFF2B335F),
    Color(0xFF7C6E86),
    Color(0xFFF4C79A),
  ];
  static const List<double> _skyStops = [0.0, 0.55, 1.0];

  /// `rgba(247,193,91,0.55)`.
  static const Color _sunGlowColor = Color(0x8CF7C15B);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: _skyColors,
          stops: _skyStops,
        ).createShader(rect),
    );

    // Two small stars, upper area.
    canvas.drawCircle(
      Offset(size.width * 0.28, size.height * 0.22),
      2.0, // 4px diameter.
      Paint()..color = Colors.white.withValues(alpha: 0.8),
    );
    canvas.drawCircle(
      Offset(size.width * 0.62, size.height * 0.14),
      1.5, // 3px diameter.
      Paint()..color = Colors.white.withValues(alpha: 0.7),
    );

    // Centered-bottom sun with a soft glow.
    final sunCenter = Offset(size.width / 2, size.height - 6);
    const sunRadius = 15.0; // 30px diameter.

    canvas.drawCircle(
      sunCenter,
      sunRadius + 5,
      Paint()
        ..color = _sunGlowColor
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );

    canvas.drawCircle(
      sunCenter,
      sunRadius,
      Paint()
        ..shader = RadialGradient(
          colors: const [Color(0xFFFFE9AE), Color(0xFFF3AE44)],
        ).createShader(Rect.fromCircle(center: sunCenter, radius: sunRadius)),
    );
  }

  @override
  bool shouldRepaint(covariant SunrisePreviewPainter oldDelegate) => false;
}

/// Static mini-preview for the Walking Home theme: a sky gradient, a ground
/// band, a house at bottom-right, and a character at bottom-left.
class WalkPreviewPainter extends ScenePreviewPainter {
  const WalkPreviewPainter();

  static const double _groundHeight = 26.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFBFE0EE), Color(0xFFE9F2E0)],
        ).createShader(rect),
    );

    canvas.drawRect(
      Rect.fromLTWH(0, size.height - _groundHeight, size.width, _groundHeight),
      Paint()..color = const Color(0xFFCFE0A8),
    );

    _drawHouse(canvas, size);
    _drawCharacter(canvas, size);
  }

  void _drawHouse(Canvas canvas, Size size) {
    const bodyWidth = 26.0;
    const bodyHeight = 20.0;
    final bodyRect = Rect.fromLTWH(
      size.width - bodyWidth - 8,
      size.height - _groundHeight - bodyHeight,
      bodyWidth,
      bodyHeight,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, const Radius.circular(4)),
      Paint()..color = const Color(0xFFEAD7B8),
    );

    final roofPath = Path()
      ..moveTo(bodyRect.left - 2, bodyRect.top)
      ..lineTo(bodyRect.right + 2, bodyRect.top)
      ..lineTo(bodyRect.center.dx, bodyRect.top - 12)
      ..close();
    canvas.drawPath(roofPath, Paint()..color = const Color(0xFFC98A5E));
  }

  void _drawCharacter(Canvas canvas, Size size) {
    const bodyWidth = 16.0;
    const bodyHeight = 16.0;
    final bodyRect = Rect.fromLTWH(
      8,
      size.height - _groundHeight - bodyHeight,
      bodyWidth,
      bodyHeight,
    );
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        bodyRect,
        topLeft: const Radius.circular(8),
        topRight: const Radius.circular(8),
        bottomLeft: const Radius.circular(4),
        bottomRight: const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFFE0805F),
    );

    canvas.drawCircle(
      Offset(bodyRect.center.dx, bodyRect.top - 6),
      6, // 12px diameter.
      Paint()..color = const Color(0xFFF0C9A0),
    );
  }

  @override
  bool shouldRepaint(covariant WalkPreviewPainter oldDelegate) => false;
}

/// Static mini-preview for the Car on a Road theme: a sky gradient, a dashed
/// road band, and a car at bottom-left.
class CarPreviewPainter extends ScenePreviewPainter {
  const CarPreviewPainter();

  static const double _roadHeight = 22.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF6D9A8), Color(0xFFF3E3C4)],
        ).createShader(rect),
    );

    final roadRect = Rect.fromLTWH(
      0,
      size.height - _roadHeight,
      size.width,
      _roadHeight,
    );
    canvas.drawRect(roadRect, Paint()..color = const Color(0xFF5A5048));
    _drawDashedCenterLine(canvas, size, roadRect.center.dy);

    _drawCar(canvas, size);
  }

  void _drawDashedCenterLine(Canvas canvas, Size size, double centerY) {
    final dashPaint = Paint()
      ..color = const Color(0xFFE9D9B8)
      ..strokeWidth = 2;
    const dashWidth = 6.0;
    const dashGap = 5.0;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, centerY),
        Offset(x + dashWidth, centerY),
        dashPaint,
      );
      x += dashWidth + dashGap;
    }
  }

  void _drawCar(Canvas canvas, Size size) {
    const bodyWidth = 40.0;
    const bodyHeight = 16.0;
    final bodyRect = Rect.fromLTWH(
      8,
      size.height - _roadHeight - bodyHeight,
      bodyWidth,
      bodyHeight,
    );
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        bodyRect,
        topLeft: const Radius.circular(8),
        topRight: const Radius.circular(8),
        bottomLeft: const Radius.circular(4),
        bottomRight: const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFFDE6A4B),
    );

    final windowRect = Rect.fromLTWH(
      bodyRect.left + (bodyWidth - 20) / 2,
      bodyRect.top + 2,
      20,
      10,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(windowRect, const Radius.circular(2)),
      Paint()..color = const Color(0xFFF0B49B),
    );

    final wheelPaint = Paint()..color = const Color(0xFF3A3230);
    canvas.drawCircle(Offset(bodyRect.left + 10, bodyRect.bottom), 5, wheelPaint);
    canvas.drawCircle(Offset(bodyRect.right - 10, bodyRect.bottom), 5, wheelPaint);
  }

  @override
  bool shouldRepaint(covariant CarPreviewPainter oldDelegate) => false;
}
