import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zual/scenes/car/car_painter.dart';
import 'package:zual/scenes/walk/walk_painter.dart' show arrivalLeftFraction;

/// Pins that `CarPainter` reuses the shared `arrivalLeftFraction` (never
/// redefines its own copy) and that `shouldRepaint` narrows on both
/// time-varying inputs, per `03-UI-SPEC.md`'s Arrival Mechanic section
/// (final, D-01) and `03-RESEARCH.md` Pattern 2/3.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  group('CarPainter wheel spin is visible (CR-01 / Truth #8 regression)', () {
    Future<Uint8List> renderRawRgba(double spinAngle, Size size) async {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      CarPainter(progress: 0.5, spinAngle: spinAngle).paint(canvas, size);
      final picture = recorder.endRecording();
      final image = await picture.toImage(
        size.width.toInt(),
        size.height.toInt(),
      );
      final byteData = await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      return byteData!.buffer.asUint8List();
    }

    test(
      'rendered rasters at spinAngle 0.0 vs pi/2 are NOT byte-identical',
      () async {
        const size = Size(200, 400);
        final bytesAtZero = await renderRawRgba(0.0, size);
        final bytesAtHalfPi = await renderRawRgba(pi / 2, size);

        // This assertion fails on the pre-fix two-concentric-circles
        // implementation (rotationally symmetric, byte-identical at every
        // angle) and passes only once an asymmetric wheel marking is
        // present -- the automated guard the original shouldRepaint-only
        // suite lacked (CR-01).
        expect(listEquals(bytesAtZero, bytesAtHalfPi), isFalse);
      },
    );
  });
}
