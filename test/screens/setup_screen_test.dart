import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:zual/screens/placeholder_running_screen.dart';
import 'package:zual/screens/setup_screen.dart';
import 'package:zual/timer/timer_controller.dart';
import 'package:zual/timer/timer_phase.dart';

/// Wraps [SetupScreen] with the [TimerController] provider it expects in
/// production (mirrors the real `main.dart` wiring), using an injected-clock
/// controller so this suite never depends on wall-clock time.
Widget _harness(TimerController controller, {int initialDurationMin = 5}) {
  return ChangeNotifierProvider<TimerController>.value(
    value: controller,
    child: MaterialApp(
      home: SetupScreen(initialDurationMin: initialDurationMin),
    ),
  );
}

void main() {
  group('SetupScreen', () {
    testWidgets('renders the five duration presets and selects the tapped one (SETUP-01)', (
      WidgetTester tester,
    ) async {
      final controller = TimerController(clock: () => DateTime(2026, 1, 1));
      await tester.pumpWidget(_harness(controller));

      for (final label in ['1', '5', '10', '15', '30']) {
        expect(find.text(label), findsOneWidget);
      }

      // No selection ring on "10" before it is tapped.
      expect(find.byKey(const ValueKey('preset-ring-10')), findsNothing);

      await tester.tap(find.text('10'));
      await tester.pump();

      expect(find.byKey(const ValueKey('preset-ring-10')), findsOneWidget);
      expect(find.byKey(const ValueKey('preset-ring-5')), findsNothing);

      controller.dispose();
    });

    testWidgets(
      'tapping Start after selecting a preset calls TimerController.start and '
      'navigates to the placeholder running screen (SETUP-04)',
      (WidgetTester tester) async {
        final controller = TimerController(clock: () => DateTime(2026, 1, 1));
        await tester.pumpWidget(_harness(controller));

        await tester.tap(find.text('10'));
        await tester.pump();

        await tester.tap(find.byKey(const ValueKey('start-button')));
        await tester.pumpAndSettle();

        expect(controller.phase, TimerPhase.running);
        expect(find.byType(PlaceholderRunningScreen), findsOneWidget);

        controller.dispose();
      },
    );

    testWidgets('the 5 min preset is selected by default before any tap', (
      WidgetTester tester,
    ) async {
      final controller = TimerController(clock: () => DateTime(2026, 1, 1));
      await tester.pumpWidget(_harness(controller));

      expect(find.byKey(const ValueKey('preset-ring-5')), findsOneWidget);

      controller.dispose();
    });
  });

  group('SetupScreen scene selection (SETUP-03)', () {
    testWidgets(
      'shows all four scene cards with exact labels; Shrinking disc selected by default',
      (WidgetTester tester) async {
        final controller = TimerController(clock: () => DateTime(2026, 1, 1));
        await tester.pumpWidget(_harness(controller));

        for (final label in [
          'Shrinking disc',
          'Night to sunrise',
          'Walking home',
          'Car on a road',
        ]) {
          expect(find.text(label), findsOneWidget);
        }

        expect(
          find.byKey(const ValueKey('scene-ring-shrinking disc')),
          findsOneWidget,
        );

        controller.dispose();
      },
    );

    testWidgets(
      'tapping a scene card single-selects it, clearing the previous selection',
      (WidgetTester tester) async {
        final controller = TimerController(clock: () => DateTime(2026, 1, 1));
        await tester.pumpWidget(_harness(controller));

        await tester.ensureVisible(find.text('Walking home'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Walking home'));
        await tester.pump();

        expect(
          find.byKey(const ValueKey('scene-ring-walking home')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('scene-ring-shrinking disc')),
          findsNothing,
        );

        controller.dispose();
      },
    );
  });

  group('SetupScreen -> PlaceholderRunningScreen', () {
    testWidgets(
      'the back control ends the timer and returns to Setup with phase set to setup',
      (WidgetTester tester) async {
        final semantics = tester.ensureSemantics();
        final controller = TimerController(clock: () => DateTime(2026, 1, 1));
        await tester.pumpWidget(_harness(controller));

        await tester.tap(find.byKey(const ValueKey('start-button')));
        await tester.pumpAndSettle();
        expect(controller.phase, TimerPhase.running);

        await tester.tap(find.bySemanticsLabel('End timer and return to setup'));
        await tester.pumpAndSettle();

        expect(controller.phase, TimerPhase.setup);
        expect(find.byType(SetupScreen), findsOneWidget);
        expect(find.byType(PlaceholderRunningScreen), findsNothing);

        semantics.dispose();
        controller.dispose();
      },
    );

    testWidgets('reaching TimerPhase.done auto-returns to Setup', (
      WidgetTester tester,
    ) async {
      var now = DateTime(2026, 1, 1, 12, 0, 0);
      final controller = TimerController(clock: () => now);
      await tester.pumpWidget(_harness(controller));

      await tester.tap(find.byKey(const ValueKey('start-button')));
      await tester.pumpAndSettle();
      expect(find.byType(PlaceholderRunningScreen), findsOneWidget);

      now = now.add(const Duration(minutes: 5, seconds: 1)); // default 5-min preset
      controller.syncToWallClock();
      await tester.pumpAndSettle();

      expect(controller.phase, TimerPhase.done);
      expect(find.byType(SetupScreen), findsOneWidget);
      expect(find.byType(PlaceholderRunningScreen), findsNothing);

      controller.dispose();
    });
  });
}
