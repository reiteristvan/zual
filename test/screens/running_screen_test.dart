import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:zual/audio/chime_player.dart';
import 'package:zual/scenes/scene_theme.dart';
import 'package:zual/screens/running_screen.dart';
import 'package:zual/timer/timer_controller.dart';
import 'package:zual/timer/timer_phase.dart';

/// A [ChimePlayer] fake that counts invocations, so tests can assert on
/// how many times the chime was triggered without touching a real platform
/// channel (`04-RESEARCH.md` Common Pitfall 5).
class _FakeChimePlayer implements ChimePlayer {
  int playCount = 0;

  @override
  Future<void> play(Uint8List wavBytes) async {
    playCount++;
  }
}

/// Wraps [RunningScreen] with the [TimerController] provider it expects in
/// production (mirrors the real `main.dart` wiring), using an injected-clock
/// controller so this suite never depends on wall-clock time. Mirrors
/// `test/screens/setup_screen_test.dart`'s `_harness` shape.
Widget _harness(
  TimerController controller, {
  SceneTheme theme = SceneTheme.disc,
  ChimePlayer? chimePlayer,
  ValueNotifier<bool>? soundOn,
}) {
  return ChangeNotifierProvider<TimerController>.value(
    value: controller,
    child: MaterialApp(
      home: RunningScreen(
        theme: theme,
        chimePlayer: chimePlayer ?? const NoopChimePlayer(),
        soundOn: soundOn ?? ValueNotifier<bool>(true),
      ),
    ),
  );
}

/// Pumps just enough frames for the widget tree to settle, instead of
/// `pumpAndSettle()` -- which hangs against `RunningScreen`'s hosted scene,
/// whose per-scene `Ticker` schedules frames continuously while the timer is
/// running (`03-RESEARCH.md` Pitfall 4).
Future<void> _pumpPastTransition(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  group('RunningScreen Parent Controls long-press gate (CTRL-01)', () {
    testWidgets(
      'a sustained ~850ms press opens the Parent Controls sheet',
      (WidgetTester tester) async {
        final controller = TimerController(clock: () => DateTime(2026, 1, 1));
        controller.start(5);
        await tester.pumpWidget(_harness(controller));
        await _pumpPastTransition(tester);

        final gesture = await tester.startGesture(
          tester.getCenter(find.byType(RunningScreen)),
        );
        await tester.pump(const Duration(milliseconds: 900));
        await gesture.up();
        await tester.pump();

        expect(find.text('Parent controls'), findsOneWidget);

        controller.dispose();
      },
    );

    testWidgets(
      'a press released before 850ms opens nothing',
      (WidgetTester tester) async {
        final controller = TimerController(clock: () => DateTime(2026, 1, 1));
        controller.start(5);
        await tester.pumpWidget(_harness(controller));
        await _pumpPastTransition(tester);

        final gesture = await tester.startGesture(
          tester.getCenter(find.byType(RunningScreen)),
        );
        await tester.pump(const Duration(milliseconds: 400));
        await gesture.up();
        await tester.pump();

        expect(find.text('Parent controls'), findsNothing);

        controller.dispose();
      },
    );

    testWidgets(
      'long-press does nothing once TimerPhase.done (D-09)',
      (WidgetTester tester) async {
        var now = DateTime(2026, 1, 1, 12, 0, 0);
        final controller = TimerController(clock: () => now);
        controller.start(5);
        await tester.pumpWidget(_harness(controller));
        await _pumpPastTransition(tester);

        now = now.add(const Duration(minutes: 5, seconds: 1));
        controller.syncToWallClock();
        await tester.pump();

        final gesture = await tester.startGesture(
          tester.getCenter(find.byType(RunningScreen)),
        );
        await tester.pump(const Duration(milliseconds: 900));
        await gesture.up();
        await tester.pump();

        expect(find.text('Parent controls'), findsNothing);

        controller.dispose();
      },
    );
  });

  group('RunningScreen Parent Controls sheet actions (CTRL-02)', () {
    Future<void> openSheet(WidgetTester tester) async {
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(RunningScreen)),
      );
      await tester.pump(const Duration(milliseconds: 900));
      await gesture.up();
      await tester.pump();
    }

    testWidgets(
      'tapping the primary button while running calls pause() and the '
      'label reads Pause then Resume',
      (WidgetTester tester) async {
        final controller = TimerController(clock: () => DateTime(2026, 1, 1));
        controller.start(5);
        await tester.pumpWidget(_harness(controller));
        await _pumpPastTransition(tester);

        await openSheet(tester);
        expect(find.text('Pause'), findsOneWidget);

        await tester.tap(find.text('Pause'));
        await tester.pump();

        expect(controller.phase, TimerPhase.paused);
        expect(find.text('Resume'), findsOneWidget);

        controller.dispose();
      },
    );

    testWidgets(
      'tapping End timer calls endTimer() and pops RunningScreen',
      (WidgetTester tester) async {
        final controller = TimerController(clock: () => DateTime(2026, 1, 1));
        controller.start(5);
        await tester.pumpWidget(_harness(controller));
        await _pumpPastTransition(tester);

        await openSheet(tester);
        await tester.tap(find.text('End timer'));
        await tester.pumpAndSettle();

        expect(controller.phase, TimerPhase.setup);
        expect(find.byType(RunningScreen), findsNothing);

        controller.dispose();
      },
    );

    testWidgets(
      'tapping Keep watching dismisses the sheet without changing phase',
      (WidgetTester tester) async {
        final controller = TimerController(clock: () => DateTime(2026, 1, 1));
        controller.start(5);
        await tester.pumpWidget(_harness(controller));
        await _pumpPastTransition(tester);

        await openSheet(tester);
        await tester.tap(find.text('Keep watching'));
        await tester.pumpAndSettle();

        expect(controller.phase, TimerPhase.running);
        expect(find.byType(RunningScreen), findsOneWidget);
        expect(find.text('Parent controls'), findsNothing);

        controller.dispose();
      },
    );

    testWidgets(
      'tapping the mute icon flips soundOn and swaps the volume glyph',
      (WidgetTester tester) async {
        final controller = TimerController(clock: () => DateTime(2026, 1, 1));
        controller.start(5);
        final soundOn = ValueNotifier<bool>(true);
        await tester.pumpWidget(_harness(controller, soundOn: soundOn));
        await _pumpPastTransition(tester);

        await openSheet(tester);
        expect(find.byIcon(Icons.volume_up), findsOneWidget);

        await tester.tap(find.byIcon(Icons.volume_up));
        await tester.pump();

        expect(soundOn.value, isFalse);
        expect(find.byIcon(Icons.volume_off), findsOneWidget);

        controller.dispose();
      },
    );
  });
}
