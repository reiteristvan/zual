import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zual/scenes/sunrise/sunrise_painter.dart';

/// Pins the sunrise pure formulas' behavior exactly per `03-UI-SPEC.md`'s
/// Night to Sunrise Geometry table (locked, D-01), including the required
/// Pitfall-3 clamps on the star/moon opacity formulas, which go negative
/// well before `progress == 1`.
void main() {
  group('starOpacity', () {
    test('progress=0.0 is fully opaque', () {
      expect(starOpacity(0.0), 1.0);
    });

    test('progress=0.435 is the boundary where the raw formula hits ~0', () {
      expect(starOpacity(0.435), closeTo(0.0, 0.01));
    });

    test('progress=0.6 is clamped to 0.0, not negative', () {
      expect(starOpacity(0.6), 0.0);
    });

    test('stays within 0..1 across a 0.0->1.0 sweep', () {
      for (var p = 0.0; p <= 1.0; p += 0.05) {
        final value = starOpacity(p);
        expect(value, greaterThanOrEqualTo(0.0));
        expect(value, lessThanOrEqualTo(1.0));
      }
    });
  });

  group('moonOpacity', () {
    test('progress=0.0 is fully opaque', () {
      expect(moonOpacity(0.0), 1.0);
    });

    test('progress=0.588 is the boundary where the raw formula hits ~0', () {
      expect(moonOpacity(0.588), closeTo(0.0, 0.01));
    });

    test('progress=0.9 is clamped to 0.0, not negative', () {
      expect(moonOpacity(0.9), 0.0);
    });

    test('stays within 0..1 across a 0.0->1.0 sweep', () {
      for (var p = 0.0; p <= 1.0; p += 0.05) {
        final value = moonOpacity(p);
        expect(value, greaterThanOrEqualTo(0.0));
        expect(value, lessThanOrEqualTo(1.0));
      }
    });
  });

  group('starOpacity/moonOpacity sweep table', () {
    for (final p in [0.0, 0.2, 0.435, 0.5, 0.588, 0.75, 1.0]) {
      test('progress=$p stays within 0..1 for both formulas', () {
        expect(starOpacity(p), inInclusiveRange(0.0, 1.0));
        expect(moonOpacity(p), inInclusiveRange(0.0, 1.0));
      });
    }
  });

  group('sunTopFraction', () {
    test('progress=0.0 is 0.86 (86% of height)', () {
      expect(sunTopFraction(0.0), 0.86);
    });

    test('progress=1.0 is 0.22 (22% of height)', () {
      expect(sunTopFraction(1.0), closeTo(0.22, 1e-9));
    });
  });

  group('hillColor', () {
    test('progress=0.0 is the locked night-blue', () {
      expect(hillColor(0.0), const Color(0xFF26314F));
    });

    test('progress=1.0 is the locked warm green', () {
      expect(hillColor(1.0), const Color(0xFF6E9060));
    });
  });

  group('SunrisePainter.shouldRepaint', () {
    test('returns false when neither progress nor twinklePhase changed', () {
      final a = SunrisePainter(progress: 0.4, twinklePhase: 0.2);
      final b = SunrisePainter(progress: 0.4, twinklePhase: 0.2);
      expect(a.shouldRepaint(b), isFalse);
    });

    test('returns true when progress changed', () {
      final a = SunrisePainter(progress: 0.4, twinklePhase: 0.2);
      final b = SunrisePainter(progress: 0.6, twinklePhase: 0.2);
      expect(a.shouldRepaint(b), isTrue);
    });

    test('returns true when twinklePhase changed', () {
      final a = SunrisePainter(progress: 0.4, twinklePhase: 0.2);
      final b = SunrisePainter(progress: 0.4, twinklePhase: 0.9);
      expect(a.shouldRepaint(b), isTrue);
    });
  });
}
