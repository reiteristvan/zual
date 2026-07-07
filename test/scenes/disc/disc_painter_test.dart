import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zual/scenes/disc/disc_painter.dart';

/// Pins `discColorForRemaining`'s zone thresholds exactly per
/// `03-UI-SPEC.md`'s Shrinking Disc color table (locked, D-01) and the
/// mathematical continuity between zone boundaries.
void main() {
  group('discColorForRemaining', () {
    const green = Color(0xFF7FA87A);
    const yellow = Color(0xFFE8B75A);
    const red = Color(0xFFDE6A4B);

    test('remaining=0.6 is pure green (remaining > 0.5)', () {
      expect(discColorForRemaining(0.6), green);
    });

    test('remaining=0.5 boundary is pure green (yellow->green lerp, t=1.0)', () {
      expect(discColorForRemaining(0.5), Color.lerp(yellow, green, 1.0));
      expect(discColorForRemaining(0.5), green);
    });

    test('remaining=0.35 is a yellow->green lerp with t=(0.35-0.2)/0.3', () {
      final t = (0.35 - 0.2) / 0.3;
      expect(discColorForRemaining(0.35), Color.lerp(yellow, green, t));
    });

    test(
      'remaining=0.2 boundary is pure yellow (red->yellow lerp, t=1.0) -- '
      'continuous with the yellow->green zone, which also evaluates to '
      'yellow at its t=0 boundary at the same remaining value',
      () {
        expect(discColorForRemaining(0.2), Color.lerp(red, yellow, 1.0));
        expect(discColorForRemaining(0.2), yellow);
      },
    );

    test('remaining=0.1 is a red->yellow lerp with t=0.1/0.2', () {
      expect(discColorForRemaining(0.1), Color.lerp(red, yellow, 0.5));
    });

    test(
      'remaining=0.0 is pure red -- matches the done criterion that the '
      'disc is pure red at progress=1',
      () {
        expect(discColorForRemaining(0.0), red);
      },
    );
  });

  group('DiscPainter.shouldRepaint', () {
    test('returns false when progress is unchanged', () {
      final a = DiscPainter(progress: 0.4);
      final b = DiscPainter(progress: 0.4);
      expect(a.shouldRepaint(b), isFalse);
    });

    test('returns true when progress changed', () {
      final a = DiscPainter(progress: 0.4);
      final b = DiscPainter(progress: 0.6);
      expect(a.shouldRepaint(b), isTrue);
    });
  });
}
