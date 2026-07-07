import 'dart:math';

import 'package:flutter/widgets.dart';

import '../scene_renderer.dart';
import 'car_painter.dart';

/// The Car on a Road scene (SCENE-04): a full-bleed [CarPainter] driven by
/// [progress] and the shared per-scene ticker's spin-loop phase from
/// [SceneRendererState]. No `Scaffold`, no `GestureDetector`, no `Text`
/// anywhere in this scene (SCENE-05) -- the composition root
/// (`RunningScreen`) owns chrome and the back affordance.
class CarScene extends SceneRenderer {
  const CarScene({super.key});

  @override
  State<CarScene> createState() => _CarSceneState();
}

class _CarSceneState extends SceneRendererState<CarScene> {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: CarPainter(
        progress: progress,
        spinAngle: 2 * pi * loopPhase(const Duration(milliseconds: 700)),
      ),
    );
  }
}
