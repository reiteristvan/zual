import 'package:flutter_test/flutter_test.dart';

import 'package:zual/scenes/disc/disc_scene.dart';
import 'package:zual/scenes/scene_registry.dart';
import 'package:zual/scenes/scene_theme.dart';
import 'package:zual/scenes/sunrise/sunrise_scene.dart';

void main() {
  group('sceneFor', () {
    test('SceneTheme.disc returns a DiscScene', () {
      expect(sceneFor(SceneTheme.disc), isA<DiscScene>());
    });

    test('SceneTheme.sunrise returns a SunriseScene', () {
      expect(sceneFor(SceneTheme.sunrise), isA<SunriseScene>());
    });

    test('walk/car return a non-null Widget (pending fallback)', () {
      expect(sceneFor(SceneTheme.walk), isNotNull);
      expect(sceneFor(SceneTheme.car), isNotNull);
    });

    test('walk/car do not return a DiscScene or SunriseScene', () {
      expect(sceneFor(SceneTheme.walk), isNot(isA<DiscScene>()));
      expect(sceneFor(SceneTheme.walk), isNot(isA<SunriseScene>()));
      expect(sceneFor(SceneTheme.car), isNot(isA<DiscScene>()));
      expect(sceneFor(SceneTheme.car), isNot(isA<SunriseScene>()));
    });
  });
}
