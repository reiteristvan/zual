import 'package:flutter_test/flutter_test.dart';

import 'package:zual/scenes/walk/walk_painter.dart';

/// Pins `arrivalLeftFraction`'s exact locked values per `03-UI-SPEC.md`'s
/// Arrival Mechanic section (final, D-01) and the defensive re-clamp per
/// `03-RESEARCH.md` Pattern 3 / the threat register's T-03-05 mitigation.
void main() {
  group('arrivalLeftFraction', () {
    test('progress=0.0 is 0.06 (6% from the left edge)', () {
      expect(arrivalLeftFraction(0.0), closeTo(0.06, 1e-9));
    });

    test('progress=1.0 is 0.68 (arrives at the house door)', () {
      expect(arrivalLeftFraction(1.0), closeTo(0.68, 1e-9));
    });

    test('progress=0.5 is the midpoint, 0.37', () {
      expect(arrivalLeftFraction(0.5), closeTo(0.37, 1e-9));
    });

    test('re-clamps out-of-range input above 1.0 to the p=1.0 result', () {
      expect(arrivalLeftFraction(1.5), closeTo(0.68, 1e-9));
    });

    test('re-clamps out-of-range input below 0.0 to the p=0.0 result', () {
      expect(arrivalLeftFraction(-0.2), closeTo(0.06, 1e-9));
    });
  });

  group('WalkPainter.shouldRepaint', () {
    test('returns false when neither progress nor bobPhase changed', () {
      final a = WalkPainter(progress: 0.4, bobPhase: 0.2);
      final b = WalkPainter(progress: 0.4, bobPhase: 0.2);
      expect(a.shouldRepaint(b), isFalse);
    });

    test('returns true when progress changed', () {
      final a = WalkPainter(progress: 0.4, bobPhase: 0.2);
      final b = WalkPainter(progress: 0.6, bobPhase: 0.2);
      expect(a.shouldRepaint(b), isTrue);
    });

    test('returns true when bobPhase changed', () {
      final a = WalkPainter(progress: 0.4, bobPhase: 0.2);
      final b = WalkPainter(progress: 0.4, bobPhase: 0.9);
      expect(a.shouldRepaint(b), isTrue);
    });
  });
}
