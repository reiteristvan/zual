import 'package:flutter_test/flutter_test.dart';

import 'package:zual/scenes/scene_preview.dart';
import 'package:zual/scenes/scene_theme.dart';

/// Pins the D-05/D-06 contract for the scene-preview abstraction: exactly
/// four themes in a fixed order, and every concrete painter is static
/// (`shouldRepaint` always false) and extends the shared abstraction rather
/// than being a standalone type.
void main() {
  group('SceneTheme', () {
    test('values are disc, sunrise, walk, car in that order', () {
      expect(SceneTheme.values, [
        SceneTheme.disc,
        SceneTheme.sunrise,
        SceneTheme.walk,
        SceneTheme.car,
      ]);
    });
  });

  group('ScenePreviewPainter', () {
    test('every concrete painter reports shouldRepaint == false (static previews)', () {
      expect(
        const DiscPreviewPainter().shouldRepaint(const DiscPreviewPainter()),
        isFalse,
      );
      expect(
        const SunrisePreviewPainter().shouldRepaint(const SunrisePreviewPainter()),
        isFalse,
      );
      expect(
        const WalkPreviewPainter().shouldRepaint(const WalkPreviewPainter()),
        isFalse,
      );
      expect(
        const CarPreviewPainter().shouldRepaint(const CarPreviewPainter()),
        isFalse,
      );
    });

    test('every concrete painter extends the shared abstraction', () {
      expect(const DiscPreviewPainter(), isA<ScenePreviewPainter>());
      expect(const SunrisePreviewPainter(), isA<ScenePreviewPainter>());
      expect(const WalkPreviewPainter(), isA<ScenePreviewPainter>());
      expect(const CarPreviewPainter(), isA<ScenePreviewPainter>());
    });
  });
}
