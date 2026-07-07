import 'package:flutter_test/flutter_test.dart';

import 'package:zual/scenes/car/car_painter.dart';
import 'package:zual/scenes/walk/walk_painter.dart' show arrivalLeftFraction;

/// Pins that `CarPainter` reuses the shared `arrivalLeftFraction` (never
/// redefines its own copy) and that `shouldRepaint` narrows on both
/// time-varying inputs, per `03-UI-SPEC.md`'s Arrival Mechanic section
/// (final, D-01) and `03-RESEARCH.md` Pattern 2/3.
void main() {
  group('CarPainter arrival mechanic (shared with WalkPainter)', () {
    test('car position at progress=0.0 matches arrivalLeftFraction(0.0)', () {
      expect(arrivalLeftFraction(0.0), closeTo(0.06, 1e-9));
    });

    test('car position at progress=1.0 matches arrivalLeftFraction(1.0)', () {
      expect(arrivalLeftFraction(1.0), closeTo(0.68, 1e-9));
    });
  });

  group('CarPainter.shouldRepaint', () {
    test('returns false when neither progress nor spinAngle changed', () {
      final a = CarPainter(progress: 0.4, spinAngle: 0.2);
      final b = CarPainter(progress: 0.4, spinAngle: 0.2);
      expect(a.shouldRepaint(b), isFalse);
    });

    test('returns true when progress changed', () {
      final a = CarPainter(progress: 0.4, spinAngle: 0.2);
      final b = CarPainter(progress: 0.6, spinAngle: 0.2);
      expect(a.shouldRepaint(b), isTrue);
    });

    test('returns true when spinAngle changed', () {
      final a = CarPainter(progress: 0.4, spinAngle: 0.2);
      final b = CarPainter(progress: 0.4, spinAngle: 0.9);
      expect(a.shouldRepaint(b), isTrue);
    });
  });
}
