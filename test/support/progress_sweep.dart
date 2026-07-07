import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:zual/timer/timer_controller.dart';

/// Pumps [scene] wrapped with a running [TimerController] provider across a
/// fixed series of progress checkpoints (default `0.0, 0.25, 0.5, 0.75,
/// 1.0`), driving an injected-clock controller so progress advances
/// deterministically.
///
/// Uses `tester.pump(fixedDuration)` at each checkpoint rather than
/// `tester.pumpAndSettle()`, which would hang against any scene hosting a
/// continuously-ticking [SceneRendererState] (`03-RESEARCH.md` Pitfall 4).
///
/// Shared across every scene's widget-test file so the pump-at-fixed-
/// durations sweep is defined in exactly one place (`03-RESEARCH.md`'s Wave
/// 0 Gaps).
Future<void> pumpProgressSweep(
  WidgetTester tester,
  Widget scene, {
  List<double> checkpoints = const [0.0, 0.25, 0.5, 0.75, 1.0],
  int totalMinutes = 1,
}) async {
  final startTime = DateTime(2026, 1, 1);
  var now = startTime;
  final controller = TimerController(clock: () => now);

  controller.start(totalMinutes);

  await tester.pumpWidget(
    ChangeNotifierProvider<TimerController>.value(
      value: controller,
      child: MaterialApp(home: scene),
    ),
  );

  final totalMs = Duration(minutes: totalMinutes).inMilliseconds;
  for (final checkpoint in checkpoints) {
    now = startTime.add(
      Duration(milliseconds: (totalMs * checkpoint).round()),
    );
    controller.syncToWallClock();
    await tester.pump(const Duration(milliseconds: 16));
  }

  // Dispose synchronously here (rather than via `addTearDown`) so
  // [TimerController]'s internal 200ms reconcile `Timer.periodic` is
  // cancelled before `testWidgets`' pending-timer invariant check runs --
  // `addTearDown` callbacks execute too late in the fake-async test zone to
  // satisfy that check for a controller that never reached `done`.
  controller.dispose();
}
