import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:zual/scenes/scene_renderer.dart';
import 'package:zual/timer/timer_controller.dart';

/// Minimal concrete [SceneRenderer] used only to exercise
/// [SceneRendererState]'s ticker start/stop lifecycle and `progress`
/// polling, independent of any real scene's painting logic.
class _TestScene extends SceneRenderer {
  const _TestScene();

  @override
  State<_TestScene> createState() => _TestSceneState();
}

class _TestSceneState extends SceneRendererState<_TestScene> {
  @override
  Widget build(BuildContext context) {
    return const SizedBox(key: ValueKey('test-scene-body'), width: 10, height: 10);
  }
}

Widget _harness(TimerController controller) {
  return ChangeNotifierProvider<TimerController>.value(
    value: controller,
    child: const MaterialApp(home: _TestScene()),
  );
}

void main() {
  group('SceneRendererState', () {
    testWidgets(
      'ticker starts on TimerPhase.running and polls progress via context.read',
      (WidgetTester tester) async {
        var now = DateTime(2026, 1, 1);
        final controller = TimerController(clock: () => now);
        controller.start(1);

        await tester.pumpWidget(_harness(controller));

        final state = tester.state<_TestSceneState>(find.byType(_TestScene));
        expect(state.progress, 0.0);

        now = now.add(const Duration(seconds: 30));
        controller.syncToWallClock();
        await tester.pump(const Duration(milliseconds: 16));

        expect(state.progress, closeTo(0.5, 0.02));

        controller.dispose();
      },
    );

    testWidgets(
      'ticker stops on TimerPhase.paused, freezing the last-sampled progress',
      (WidgetTester tester) async {
        var now = DateTime(2026, 1, 1);
        final controller = TimerController(clock: () => now);
        controller.start(1);

        await tester.pumpWidget(_harness(controller));

        now = now.add(const Duration(seconds: 15));
        controller.syncToWallClock();
        await tester.pump(const Duration(milliseconds: 16));

        final state = tester.state<_TestSceneState>(find.byType(_TestScene));
        final progressBeforePause = state.progress;
        expect(progressBeforePause, closeTo(0.25, 0.02));

        controller.pause();
        await tester.pump();

        // Wall clock keeps advancing, but the ticker is stopped -- no
        // further sampling/repaint should occur.
        now = now.add(const Duration(seconds: 15));
        await tester.pump(const Duration(milliseconds: 16));

        expect(state.progress, progressBeforePause);

        controller.dispose();
      },
    );

    testWidgets(
      'ticker stops on TimerPhase.done, freezing the last-sampled progress',
      (WidgetTester tester) async {
        var now = DateTime(2026, 1, 1, 12, 0, 0);
        final controller = TimerController(clock: () => now);
        controller.start(1);

        await tester.pumpWidget(_harness(controller));

        now = now.add(const Duration(minutes: 1, seconds: 1));
        controller.syncToWallClock();
        await tester.pump(const Duration(milliseconds: 16));

        final state = tester.state<_TestSceneState>(find.byType(_TestScene));
        expect(state.progress, 1.0);

        final progressAtDone = state.progress;

        now = now.add(const Duration(seconds: 10));
        await tester.pump(const Duration(milliseconds: 16));

        expect(state.progress, progressAtDone);

        controller.dispose();
      },
    );
  });
}
