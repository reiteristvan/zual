import 'package:flutter_test/flutter_test.dart';

import 'package:zual/scenes/disc/disc_scene.dart';
import 'package:zual/scenes/scene_registry.dart';
import 'package:zual/scenes/scene_theme.dart';

void main() {
  group('sceneFor', () {
    test('SceneTheme.disc returns a DiscScene', () {
      expect(sceneFor(SceneTheme.disc), isA<DiscScene>());
    });

    test('sunrise/walk/car return a non-null Widget (pending fallback)', () {
      expect(sceneFor(SceneTheme.sunrise), isNotNull);
      expect(sceneFor(SceneTheme.walk), isNotNull);
      expect(sceneFor(SceneTheme.car), isNotNull);
    });

    test('sunrise/walk/car do not return a DiscScene', () {
      expect(sceneFor(SceneTheme.sunrise), isNot(isA<DiscScene>()));
      expect(sceneFor(SceneTheme.walk), isNot(isA<DiscScene>()));
      expect(sceneFor(SceneTheme.car), isNot(isA<DiscScene>()));
    });
  });
}
