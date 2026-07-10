import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// Generates the flattened 512x512 Play Console "App icon" / hi-res
/// store-listing graphic (WR-01 follow-up, 05-REVIEW.md): a single flat
/// RGBA PNG compositing the on-device adaptive background and foreground
/// layers, distinct from the adaptive icon pair itself.
///
/// `dart:ui`'s rasterization APIs have no headless backend outside the
/// Flutter test engine (see the header note in `test/tool/icon_renderer.dart`),
/// so this generation runs inside `flutter test`, mirroring the existing
/// pipeline in `test/tool/generate_launcher_icon_test.dart`.
void main() {
  const pngSignature = <int>[0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
  const size = 512.0;

  testWidgets(
    'composites icon_background.png + icon_foreground.png into a flat '
    '512x512 RGBA PNG at store_assets/icon_512.png (05-REVIEW.md WR-01)',
    (tester) async {
      await tester.runAsync(() async {
        Future<ui.Image> decodeFile(String path) async {
          final bytes = await File(path).readAsBytes();
          final codec = await ui.instantiateImageCodec(bytes);
          final frame = await codec.getNextFrame();
          return frame.image;
        }

        final background = await decodeFile('assets/icon/icon_background.png');
        final foreground = await decodeFile('assets/icon/icon_foreground.png');

        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        const dstRect = Rect.fromLTWH(0, 0, size, size);

        for (final image in [background, foreground]) {
          final srcRect = Rect.fromLTWH(
            0,
            0,
            image.width.toDouble(),
            image.height.toDouble(),
          );
          canvas.drawImageRect(image, srcRect, dstRect, Paint());
        }

        final picture = recorder.endRecording();
        final flattened = await picture.toImage(size.toInt(), size.toInt());
        final byteData = await flattened.toByteData(
          format: ui.ImageByteFormat.png,
        );
        final pngBytes = byteData!.buffer.asUint8List();

        background.dispose();
        foreground.dispose();
        flattened.dispose();

        final outputFile = File('store_assets/icon_512.png');
        await outputFile.create(recursive: true);
        await outputFile.writeAsBytes(pngBytes);

        expect(outputFile.existsSync(), isTrue);

        final writtenBytes = await outputFile.readAsBytes();
        expect(writtenBytes.sublist(0, 8), equals(pngSignature));
        // IHDR color type byte: offset 25. 6 = truecolor with alpha (RGBA).
        expect(writtenBytes[25], equals(6));

        final codec = await ui.instantiateImageCodec(writtenBytes);
        final frame = await codec.getNextFrame();
        expect(frame.image.width, equals(512));
        expect(frame.image.height, equals(512));
        frame.image.dispose();
      });
    },
  );
}
