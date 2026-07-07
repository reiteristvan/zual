import 'package:flutter/widgets.dart';

import '../scene_renderer.dart';
import 'disc_painter.dart';

/// The Shrinking Disc scene (SCENE-01): a full-bleed [DiscPainter] driven by
/// [progress] from the shared per-scene ticker in [SceneRendererState]. No
/// `Scaffold`, no `GestureDetector`, no `Text` anywhere in this scene
/// (SCENE-05) -- the composition root (`RunningScreen`) owns chrome and the
/// back affordance.
class DiscScene extends SceneRenderer {
  const DiscScene({super.key});

  @override
  State<DiscScene> createState() => _DiscSceneState();
}

class _DiscSceneState extends SceneRendererState<DiscScene> {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: DiscPainter(progress: progress),
    );
  }
}
