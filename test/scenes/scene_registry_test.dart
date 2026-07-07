import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:zual/scenes/car/car_scene.dart';
import 'package:zual/scenes/disc/disc_scene.dart';
import 'package:zual/scenes/scene_registry.dart';
import 'package:zual/scenes/scene_theme.dart';
import 'package:zual/scenes/sunrise/sunrise_scene.dart';
import 'package:zual/scenes/walk/walk_scene.dart';

void main() {
  group('sceneFor', () {
    test('SceneTheme.disc returns a DiscScene', () {
      expect(sceneFor(SceneTheme.disc), isA<DiscScene>());
    });

    test('SceneTheme.sunrise returns a SunriseScene', () {
      expect(sceneFor(SceneTheme.sunrise), isA<SunriseScene>());
    });

    test('SceneTheme.walk returns a WalkScene', () {
      expect(sceneFor(SceneTheme.walk), isA<WalkScene>());
    });

    test('SceneTheme.car returns a CarScene', () {
      expect(sceneFor(SceneTheme.car), isA<CarScene>());
    });

    test('every scene is distinct from every other scene type', () {
      expect(sceneFor(SceneTheme.disc), isNot(isA<SunriseScene>()));
      expect(sceneFor(SceneTheme.disc), isNot(isA<WalkScene>()));
      expect(sceneFor(SceneTheme.disc), isNot(isA<CarScene>()));
      expect(sceneFor(SceneTheme.sunrise), isNot(isA<DiscScene>()));
      expect(sceneFor(SceneTheme.sunrise), isNot(isA<WalkScene>()));
      expect(sceneFor(SceneTheme.sunrise), isNot(isA<CarScene>()));
      expect(sceneFor(SceneTheme.walk), isNot(isA<DiscScene>()));
      expect(sceneFor(SceneTheme.walk), isNot(isA<SunriseScene>()));
      expect(sceneFor(SceneTheme.walk), isNot(isA<CarScene>()));
      expect(sceneFor(SceneTheme.car), isNot(isA<DiscScene>()));
      expect(sceneFor(SceneTheme.car), isNot(isA<SunriseScene>()));
      expect(sceneFor(SceneTheme.car), isNot(isA<WalkScene>()));
    });
  });

  test(
    'the interim _PendingScene fallback no longer exists in the registry '
    'source (Plan 03-03 removes it once the switch is exhaustive)',
    () {
      final source = File('lib/scenes/scene_registry.dart').readAsStringSync();
      expect(source.contains('_PendingScene'), isFalse);
    },
  );
}
