import 'package:flutter_test/flutter_test.dart';

import 'package:zual/timer/timer_controller.dart';
import 'package:zual/timer/timer_phase.dart';

void main() {
  group('TimerController', () {
    test('a freshly constructed controller reports setup phase and zero progress', () {
      final controller = TimerController(clock: () => DateTime(2026, 1, 1));

      expect(controller.phase, TimerPhase.setup);
      expect(controller.progress, 0.0);

      controller.dispose();
    });

    test('start(minutes) transitions to running with progress 0.0 at t0', () {
      var now = DateTime(2026, 1, 1, 12, 0, 0);
      final controller = TimerController(clock: () => now);

      controller.start(5);

      expect(controller.phase, TimerPhase.running);
      expect(controller.progress, 0.0);

      controller.dispose();
    });

    test('progress advances to ~0.5 at the halfway point of elapsed wall-clock time', () {
      var now = DateTime(2026, 1, 1, 12, 0, 0);
      final controller = TimerController(clock: () => now);

      controller.start(10); // 10 minutes = 600 seconds total
      now = now.add(const Duration(minutes: 5)); // halfway
      controller.syncToWallClock();

      expect(controller.progress, closeTo(0.5, 0.01));
      expect(controller.phase, TimerPhase.running);

      controller.dispose();
    });

    test(
      'reaching total elapsed time transitions to done with progress exactly 1.0, '
      'independent of tick cadence (proven via manual clock advance + single syncToWallClock call)',
      () {
        var now = DateTime(2026, 1, 1, 12, 0, 0);
        final controller = TimerController(clock: () => now);

        controller.start(1); // 1 minute total
        now = now.add(const Duration(minutes: 1, seconds: 5)); // past completion
        controller.syncToWallClock();

        expect(controller.phase, TimerPhase.done);
        expect(controller.progress, 1.0);

        controller.dispose();
      },
    );

    test('progress never decreases when the injected clock moves backward', () {
      var now = DateTime(2026, 1, 1, 12, 0, 0);
      final controller = TimerController(clock: () => now);

      controller.start(10); // 10 minutes total
      now = now.add(const Duration(minutes: 6)); // 60% elapsed
      controller.syncToWallClock();
      final progressAtSixtyPercent = controller.progress;
      expect(progressAtSixtyPercent, closeTo(0.6, 0.01));

      now = now.subtract(const Duration(minutes: 4)); // clock moved backward
      controller.syncToWallClock();

      expect(controller.progress, progressAtSixtyPercent);
      expect(controller.phase, TimerPhase.running);

      controller.dispose();
    });

    test('pause() from running freezes progress at the paused instant', () {
      var now = DateTime(2026, 1, 1, 12, 0, 0);
      final controller = TimerController(clock: () => now);

      controller.start(10); // 10 minutes total
      now = now.add(const Duration(minutes: 3));
      controller.syncToWallClock();
      final progressAtPause = controller.progress;

      controller.pause();
      expect(controller.phase, TimerPhase.paused);

      now = now.add(const Duration(minutes: 5)); // time passes while paused
      expect(controller.progress, progressAtPause);
      expect(controller.phase, TimerPhase.paused);

      controller.dispose();
    });

    test('pause() is a no-op unless running; resume() is a no-op unless paused', () {
      final controller = TimerController(clock: () => DateTime(2026, 1, 1));

      controller.pause(); // no-op from setup
      expect(controller.phase, TimerPhase.setup);

      controller.resume(); // no-op from setup
      expect(controller.phase, TimerPhase.setup);

      controller.start(5);
      controller.resume(); // no-op from running (not paused)
      expect(controller.phase, TimerPhase.running);

      controller.dispose();
    });

    test('resume() excludes the paused interval from elapsed active time', () {
      var now = DateTime(2026, 1, 1, 12, 0, 0);
      final controller = TimerController(clock: () => now);

      controller.start(5); // 5 minutes total
      now = now.add(const Duration(minutes: 1));
      controller.syncToWallClock();

      controller.pause();
      now = now.add(const Duration(minutes: 2)); // paused interval, excluded
      controller.syncToWallClock(); // still paused; no phase transition
      expect(controller.phase, TimerPhase.paused);

      controller.resume();
      expect(controller.phase, TimerPhase.running);

      now = now.add(const Duration(minutes: 4)); // 1 + 4 = 5 min of active time
      controller.syncToWallClock();

      // The paused interval (2 min) is excluded: only 1 + 4 = 5 min of active
      // time elapsed, so the timer is exactly done here — 2 minutes later in
      // wall-clock terms (1 + 2 + 4 = 7 min total) than an uninterrupted run.
      expect(controller.phase, TimerPhase.done);
      expect(controller.progress, 1.0);

      controller.dispose();
    });

    test(
      'backgrounding past total duration reaches done via a single syncToWallClock() call',
      () {
        var now = DateTime(2026, 1, 1, 12, 0, 0);
        final controller = TimerController(clock: () => now);

        controller.start(5);
        now = now.add(const Duration(minutes: 5, seconds: 1)); // no ticks fire
        controller.syncToWallClock();

        expect(controller.phase, TimerPhase.done);
        expect(controller.progress, 1.0);

        controller.dispose();
      },
    );

    test('backgrounding mid-run reconciles to real elapsed progress with no reset', () {
      var now = DateTime(2026, 1, 1, 12, 0, 0);
      final controller = TimerController(clock: () => now);

      controller.start(10);
      now = now.add(const Duration(minutes: 4)); // clock jumps, no ticks fire
      controller.syncToWallClock();

      expect(controller.phase, TimerPhase.running);
      expect(controller.progress, closeTo(0.4, 0.01));

      controller.dispose();
    });

    test('endTimer() resets to setup and progress 0.0 from running, paused, and done', () {
      var now = DateTime(2026, 1, 1, 12, 0, 0);
      final runningController = TimerController(clock: () => now);
      runningController.start(5);
      runningController.endTimer();
      expect(runningController.phase, TimerPhase.setup);
      expect(runningController.progress, 0.0);
      runningController.dispose();

      var now2 = DateTime(2026, 1, 1, 12, 0, 0);
      final pausedController = TimerController(clock: () => now2);
      pausedController.start(5);
      pausedController.pause();
      pausedController.endTimer();
      expect(pausedController.phase, TimerPhase.setup);
      expect(pausedController.progress, 0.0);
      pausedController.dispose();

      var now3 = DateTime(2026, 1, 1, 12, 0, 0);
      final doneController = TimerController(clock: () => now3);
      doneController.start(1);
      now3 = now3.add(const Duration(minutes: 1, seconds: 5));
      doneController.syncToWallClock();
      expect(doneController.phase, TimerPhase.done);
      doneController.endTimer();
      expect(doneController.phase, TimerPhase.setup);
      expect(doneController.progress, 0.0);
      doneController.dispose();
    });

    test('start() clamps minutes into the inclusive range 1..120', () {
      var now = DateTime(2026, 1, 1, 12, 0, 0);
      final controllerLow = TimerController(clock: () => now);
      controllerLow.start(0);
      now = now.add(const Duration(minutes: 1));
      controllerLow.syncToWallClock();
      expect(controllerLow.phase, TimerPhase.done); // clamped to 1 minute total
      controllerLow.dispose();

      var now2 = DateTime(2026, 1, 1, 12, 0, 0);
      final controllerHigh = TimerController(clock: () => now2);
      controllerHigh.start(500);
      now2 = now2.add(const Duration(minutes: 120));
      controllerHigh.syncToWallClock();
      expect(controllerHigh.phase, TimerPhase.done); // clamped to 120 minutes total
      controllerHigh.dispose();

      var now3 = DateTime(2026, 1, 1, 12, 0, 0);
      final controllerMid = TimerController(clock: () => now3);
      controllerMid.start(500);
      now3 = now3.add(const Duration(minutes: 119));
      controllerMid.syncToWallClock();
      expect(controllerMid.phase, TimerPhase.running); // not yet done at 119 of 120
      controllerMid.dispose();
    });
  });
}
