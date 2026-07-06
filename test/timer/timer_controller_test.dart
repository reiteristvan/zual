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
