import 'package:flutter/widgets.dart';

import 'car/car_scene.dart';
import 'disc/disc_scene.dart';
import 'scene_theme.dart';
import 'sunrise/sunrise_scene.dart';
import 'walk/walk_scene.dart';

/// The one place allowed to name concrete scene widgets by type -- mirrors
/// [lib/widgets/scene_grid.dart]'s `SceneGrid._painters` precedent (D-06).
/// [RunningScreen] depends only on this function, never on a concrete scene
/// type, so `RunningScreen` never needs to change as more scenes land.
///
/// Exhaustive over every [SceneTheme] value as of Plan 03-03: disc->
/// [DiscScene] (Plan 03-01), sunrise->[SunriseScene] (Plan 03-02), walk->
/// [WalkScene] and car->[CarScene] (Plan 03-03). There is no interim
/// fallback branch left -- all four themes render their real scene.
Widget sceneFor(SceneTheme theme) {
  switch (theme) {
    case SceneTheme.disc:
      return const DiscScene();
    case SceneTheme.sunrise:
      return const SunriseScene();
    case SceneTheme.walk:
      return const WalkScene();
    case SceneTheme.car:
      return const CarScene();
  }
}
