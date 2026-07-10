import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zual/scenes/sunrise/sunrise_painter.dart';

import 'icon_renderer.dart';

/// Spike test (05-02-PLAN.md Task 1): proves the headless
/// CustomPainter -> PNG render path works against the real
/// [SunrisePainter], with no device and no live Ticker/TimerController.
///
/// If `renderPainterToPng`/`picture.toImage`/`toByteData` throws a
/// binding/unsupported-operation error, this spike has FAILED and plan
/// 05-04 must fall back to a live-device screenshot as the icon source
/// (RESEARCH.md Assumption A1) instead of the programmatic path.
void main() {
  const pngSignature = <int>[0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];

  testWidgets(
    'renderPainterToPng renders SunrisePainter to a valid PNG file '
    'headlessly, with no device and no live Ticker',
    (tester) async {
      await tester.runAsync(() async {
        final bytes = await renderPainterToPng(
          SunrisePainter(progress: 0.75, twinklePhase: 0),
          const Size(432, 432),
        );

        // The buffer itself is a real, non-empty PNG.
        expect(bytes.length, greaterThan(1000));
        expect(bytes.sublist(0, 8), equals(pngSignature));

        // Writing it to disk and reading it back yields an existing,
        // non-empty file with the PNG header intact.
        final file = File('build/spike_icon.png');
        await file.create(recursive: true);
        await file.writeAsBytes(bytes);

        expect(file.existsSync(), isTrue);
        final readBack = await file.readAsBytes();
        expect(readBack.length, greaterThan(1000));
        expect(readBack.sublist(0, 8), equals(pngSignature));
      });
    },
  );
}
