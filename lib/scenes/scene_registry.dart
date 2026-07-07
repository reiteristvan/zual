import 'package:flutter/widgets.dart';

import 'disc/disc_scene.dart';
import 'scene_theme.dart';
import 'sunrise/sunrise_scene.dart';

/// The one place allowed to name concrete scene widgets by type -- mirrors
/// [lib/widgets/scene_grid.dart]'s `SceneGrid._painters` precedent (D-06).
/// [RunningScreen] depends only on this function, never on a concrete scene
/// type, so `RunningScreen` never needs to change as more scenes land.
///
/// Plan 03-01 wired the real [DiscScene] for [SceneTheme.disc]; Plan 03-02
/// wires the real [SunriseScene] for [SceneTheme.sunrise]. Walk/Car still
/// map to [_PendingScene], an interim, calm, non-crashing placeholder
/// replaced by the real scenes in Plan 03-03 -- not a shipped scope
/// reduction.
Widget sceneFor(SceneTheme theme) {
  switch (theme) {
    case SceneTheme.disc:
      return const DiscScene();
    case SceneTheme.sunrise:
      return const SunriseScene();
    case SceneTheme.walk:
      // TODO(03-03): replace with the real WalkScene.
      return const _PendingScene(Color(0xFFBFE0EE));
    case SceneTheme.car:
      // TODO(03-03): replace with the real CarScene.
      return const _PendingScene(Color(0xFFF6D9A8));
  }
}

/// Interim fallback for themes not yet implemented in this plan: a calm,
/// full-bleed flat background at that theme's locked base color
/// (`03-UI-SPEC.md` §§D/E/F), with no text, gestures, or motion.
class _PendingScene extends StatelessWidget {
  const _PendingScene(this.color);

  final Color color;

  @override
  Widget build(BuildContext context) => ColoredBox(color: color);
}
