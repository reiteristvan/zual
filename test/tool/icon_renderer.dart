import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

/// Renders a [CustomPainter] headlessly to PNG bytes.
///
/// Builds a [ui.PictureRecorder]-backed [Canvas], invokes the painter's
/// `paint(canvas, size)` directly (no widget tree, no `BuildContext`), then
/// rasterizes the recorded picture to a PNG-encoded byte buffer via
/// `Picture.toImage` + `Image.toByteData(format: ui.ImageByteFormat.png)`.
///
/// `dart:ui`'s `PictureRecorder`/`Image` APIs have no headless backend
/// outside a Flutter engine embedder, so this must run inside `flutter
/// test`'s Skia binding (`TestWidgetsFlutterBinding`) -- the same mechanism
/// golden-file tests rely on -- not a plain `dart run` script
/// (05-RESEARCH.md Pattern 2 / Pitfall 2).
///
/// Deliberately painter-agnostic (no `SunrisePainter` import here) so
/// plan 05-04 can reuse it for the icon foreground/background painters.
Future<Uint8List> renderPainterToPng(CustomPainter painter, Size size) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  painter.paint(canvas, size);
  final picture = recorder.endRecording();
  final image = await picture.toImage(size.width.toInt(), size.height.toInt());
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  return byteData!.buffer.asUint8List();
}
