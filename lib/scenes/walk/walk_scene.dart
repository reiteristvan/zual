import 'package:flutter/widgets.dart';

import '../scene_renderer.dart';
import 'walk_painter.dart';

/// The Walking Home scene (SCENE-03): a full-bleed [WalkPainter] driven by
/// [progress] and the shared per-scene ticker's bob-loop phase from
/// [SceneRendererState]. No `Scaffold`, no `GestureDetector`, no `Text`
/// anywhere in this scene (SCENE-05) -- the composition root
/// (`RunningScreen`) owns chrome and the back affordance.
class WalkScene extends SceneRenderer {
  const WalkScene({super.key});

  @override
  State<WalkScene> createState() => _WalkSceneState();
}

class _WalkSceneState extends SceneRendererState<WalkScene> {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: WalkPainter(
        progress: progress,
        bobPhase: loopPhase(const Duration(milliseconds: 620)),
      ),
    );
  }
}
