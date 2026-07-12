import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zual/scenes/sunrise/sunrise_painter.dart';

import 'icon_renderer.dart';

/// Generates the Play Store feature graphic (1024x500 PNG banner) at
/// `store_assets/feature_graphic.png` by headlessly rendering the real
/// in-app [SunrisePainter] at a late/near-done "hero" progress -- reusing
/// [renderPainterToPng] verbatim, exactly like
/// `test/tool/generate_store_icon_test.dart` composites the app icon.
///
/// Deliberately named WITHOUT the `_test.dart` suffix: a bare `flutter test`
/// only discovers `test/**/*_test.dart`, so this generator is never
/// auto-run and therefore never silently overwrites the committed PNG on a
/// routine test run (05-REVIEW.md WR-04 fix option (a): "not matched by
/// `flutter test`"). It must still be invoked explicitly via
/// `flutter test test/tool/generate_feature_graphic.dart` -- not
/// `dart run` -- because `dart:ui`'s rasterization APIs have no headless
/// backend outside the Flutter test engine (see the header note in
/// `test/tool/icon_renderer.dart`).
///
/// The Play Store feature-graphic dimensions (1024x500, per Play Console
/// listing requirements).
const kFeatureGraphicSize = Size(1024, 500);

/// A late/near-done sunrise state: the sun is visible above a warm green
/// hill and stars/moon have faded out (`starOpacity`/`moonOpacity` clamp to
/// 0 well before this progress -- see `sunrise_painter.dart`), which reads
/// best as a warm hero banner.
const kHeroProgress = 0.85;

void main() {
  const pngSignature = <int>[0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];

  testWidgets(
    'composites SunrisePainter at progress $kHeroProgress into a flat '
    '1024x500 RGBA PNG at store_assets/feature_graphic.png',
    (tester) async {
      await tester.runAsync(() async {
        final painter = SunrisePainter(
          progress: kHeroProgress,
          twinklePhase: 0.0,
        );
        final pngBytes = await renderPainterToPng(painter, kFeatureGraphicSize);

        final outputFile = File('store_assets/feature_graphic.png');
        await outputFile.create(recursive: true);
        await outputFile.writeAsBytes(pngBytes);

        expect(outputFile.existsSync(), isTrue);

        final writtenBytes = await outputFile.readAsBytes();
        expect(writtenBytes.sublist(0, 8), equals(pngSignature));

        final codec = await ui.instantiateImageCodec(writtenBytes);
        final frame = await codec.getNextFrame();
        expect(frame.image.width, equals(1024));
        expect(frame.image.height, equals(500));
        frame.image.dispose();
      });
    },
  );
}
