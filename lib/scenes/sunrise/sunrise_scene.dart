import 'package:flutter/widgets.dart';

import '../scene_renderer.dart';
import 'sunrise_painter.dart';

/// The Night to Sunrise scene (SCENE-02): a full-bleed [SunrisePainter]
/// driven by [progress] and the shared per-scene ticker's twinkle-loop
/// phase from [SceneRendererState]. No `Scaffold`, no `GestureDetector`, no
/// `Text` anywhere in this scene (SCENE-05) -- the composition root
/// (`RunningScreen`) owns chrome and the back affordance.
class SunriseScene extends SceneRenderer {
  const SunriseScene({super.key});

  @override
  State<SunriseScene> createState() => _SunriseSceneState();
}

class _SunriseSceneState extends SceneRendererState<SunriseScene> {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: SunrisePainter(
        progress: progress,
        twinklePhase: loopPhase(const Duration(seconds: 3)),
      ),
    );
  }
}
