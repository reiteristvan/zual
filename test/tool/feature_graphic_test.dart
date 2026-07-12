import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:zual/scenes/sunrise/sunrise_painter.dart';

import 'generate_feature_graphic.dart';
import 'icon_renderer.dart';

/// Read-only drift-detecting regression test for the committed Play Store
/// feature graphic (`store_assets/feature_graphic.png`).
///
/// This file DOES end in `_test.dart` and runs on every plain `flutter
/// test`, but unlike `generate_feature_graphic.dart` it never writes to
/// `store_assets/` -- it only re-renders the graphic in memory (using the
/// identical [kHeroProgress]/[kFeatureGraphicSize] inputs, imported rather
/// than restated so the two files cannot drift independently) and
/// byte-diffs it against the committed PNG. This implements
/// `05-REVIEW.md` WR-04 fix option (b) and closes the WR-05 regression-lock
/// gap without repeating the "silently overwrite a committed binary on
/// every test run" anti-pattern.
void main() {
  testWidgets(
    'store_assets/feature_graphic.png matches a fresh SunrisePainter render '
    '(05-REVIEW.md WR-04/WR-05)',
    (tester) async {
      await tester.runAsync(() async {
        final painter = SunrisePainter(
          progress: kHeroProgress,
          twinklePhase: 0.0,
        );
        final freshBytes = await renderPainterToPng(
          painter,
          kFeatureGraphicSize,
        );

        final committedFile = File('store_assets/feature_graphic.png');
        final committedBytes = await committedFile.readAsBytes();

        expect(
          freshBytes,
          equals(committedBytes),
          reason:
              'store_assets/feature_graphic.png has drifted from a fresh '
              'SunrisePainter render. If this is an intentional visual '
              'change, re-run `flutter test '
              'test/tool/generate_feature_graphic.dart` to regenerate the '
              'file, visually review store_assets/feature_graphic.png, '
              'then commit the new bytes.',
        );

        final codec = await ui.instantiateImageCodec(committedBytes);
        final frame = await codec.getNextFrame();
        expect(frame.image.width, equals(1024));
        expect(frame.image.height, equals(500));
        frame.image.dispose();
      });
    },
  );
}
