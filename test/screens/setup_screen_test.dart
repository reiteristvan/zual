import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:zual/scenes/scene_theme.dart';
import 'package:zual/screens/placeholder_running_screen.dart';
import 'package:zual/screens/setup_screen.dart';
import 'package:zual/settings/setup_preferences.dart';
import 'package:zual/timer/timer_controller.dart';
import 'package:zual/timer/timer_phase.dart';
import 'package:zual/widgets/hold_repeat_button.dart';

/// Wraps [SetupScreen] with the [TimerController] provider it expects in
/// production (mirrors the real `main.dart` wiring), using an injected-clock
/// controller so this suite never depends on wall-clock time.
Widget _harness(
  TimerController controller, {
  int initialDurationMin = 5,
  SceneTheme initialTheme = SceneTheme.disc,
}) {
  return ChangeNotifierProvider<TimerController>.value(
    value: controller,
    child: MaterialApp(
      home: SetupScreen(
        initialDurationMin: initialDurationMin,
        initialTheme: initialTheme,
      ),
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

  group('SetupScreen custom stepper (SETUP-02, V5)', () {
    testWidgets('tapping Custom reveals the stepper row and moves the selection ring', (
      WidgetTester tester,
    ) async {
      final controller = TimerController(clock: () => DateTime(2026, 1, 1));
      await tester.pumpWidget(_harness(controller));

      expect(find.byKey(const ValueKey('custom-ring')), findsNothing);
      expect(find.byKey(const ValueKey('stepper-minus')), findsNothing);

      await tester.tap(find.text('Custom'));
      await tester.pump();

      expect(find.byKey(const ValueKey('custom-ring')), findsOneWidget);
      expect(find.byKey(const ValueKey('preset-ring-5')), findsNothing);
      expect(find.byKey(const ValueKey('stepper-minus')), findsOneWidget);
      expect(find.byKey(const ValueKey('stepper-plus')), findsOneWidget);
      expect(find.text('3'), findsOneWidget); // customMin default (D-09/UI-SPEC)

      controller.dispose();
    });

    testWidgets(
      'tapping + increments customMin; Start launches the timer with the custom value',
      (WidgetTester tester) async {
        var now = DateTime(2026, 1, 1, 12, 0, 0);
        final controller = TimerController(clock: () => now);
        await tester.pumpWidget(_harness(controller));

        await tester.tap(find.text('Custom'));
        await tester.pump();

        await tester.ensureVisible(find.byKey(const ValueKey('stepper-plus')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('stepper-plus')));
        await tester.pump();
        expect(find.text('4'), findsOneWidget);
        expect(find.text('· 4 min'), findsOneWidget);

        await tester.tap(find.byKey(const ValueKey('start-button')));
        await tester.pumpAndSettle();
        expect(controller.phase, TimerPhase.running);

        // Prove the *custom* value (4), not the stale preset default (5),
        // was actually passed to TimerController.start(): advancing exactly
        // 4 minutes must already reach done.
        now = now.add(const Duration(minutes: 4, seconds: 1));
        controller.syncToWallClock();
        expect(controller.phase, TimerPhase.done);

        controller.dispose();
      },
    );

    testWidgets(
      'stepping - down to the 1-minute floor disables it, and calling onStep '
      'directly still cannot push customMin below 1 (V5, T-02-01)',
      (WidgetTester tester) async {
        final controller = TimerController(clock: () => DateTime(2026, 1, 1));
        await tester.pumpWidget(_harness(controller));

        await tester.tap(find.text('Custom'));
        await tester.pump();

        await tester.ensureVisible(find.byKey(const ValueKey('stepper-minus')));
        await tester.pumpAndSettle();

        // Default customMin is 3 -- two taps reach the 1-minute floor.
        // (The stepper value's own key is used rather than find.text('1')
        // because "1" also matches the unrelated "1 min" preset card.)
        final stepperValue = find.byKey(const ValueKey('stepper-value'));
        await tester.tap(find.byKey(const ValueKey('stepper-minus')));
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('stepper-minus')));
        await tester.pump();
        expect(tester.widget<Text>(stepperValue).data, '1');

        final minusButton = tester.widget<HoldRepeatButton>(
          find.byKey(const ValueKey('stepper-minus')),
        );
        expect(minusButton.enabled, isFalse);

        // Direct-state assertion: invoke onStep directly, bypassing the
        // disabled gesture layer entirely (as if the disable logic itself
        // had a bug) -- the clamp inside the setter must still hold at 1.
        minusButton.onStep();
        await tester.pump();
        expect(tester.widget<Text>(stepperValue).data, '1');

        controller.dispose();
      },
    );

    testWidgets(
      'stepping + up to the 120-minute ceiling disables it, and calling onStep '
      'directly still cannot push customMin above 120 (V5, T-02-01)',
      (WidgetTester tester) async {
        final controller = TimerController(clock: () => DateTime(2026, 1, 1));
        await tester.pumpWidget(_harness(controller));

        await tester.tap(find.text('Custom'));
        await tester.pump();

        // Drive customMin from the 3-minute default well past 120 by
        // invoking the stepper's onStep directly -- equivalent to many
        // taps/holds without ~130 individual gesture round-trips, and also
        // exercising the clamp regardless of the disabled-button gating.
        final plusButton = tester.widget<HoldRepeatButton>(
          find.byKey(const ValueKey('stepper-plus')),
        );
        for (var i = 0; i < 130; i++) {
          plusButton.onStep();
          await tester.pump();
        }

        expect(find.text('120'), findsOneWidget);
        expect(find.text('121'), findsNothing);

        final plusButtonAtCeiling = tester.widget<HoldRepeatButton>(
          find.byKey(const ValueKey('stepper-plus')),
        );
        expect(plusButtonAtCeiling.enabled, isFalse);

        controller.dispose();
      },
    );

    testWidgets('selecting a preset while Custom is open hides the stepper row', (
      WidgetTester tester,
    ) async {
      final controller = TimerController(clock: () => DateTime(2026, 1, 1));
      await tester.pumpWidget(_harness(controller));

      await tester.tap(find.text('Custom'));
      await tester.pump();
      expect(find.byKey(const ValueKey('stepper-minus')), findsOneWidget);

      await tester.tap(find.text('10'));
      await tester.pump();

      expect(find.byKey(const ValueKey('stepper-minus')), findsNothing);
      expect(find.byKey(const ValueKey('preset-ring-10')), findsOneWidget);
      expect(find.byKey(const ValueKey('custom-ring')), findsNothing);

      controller.dispose();
    });

    testWidgets(
      'customMin is not reset when toggling the Custom row closed and reopened',
      (WidgetTester tester) async {
        final controller = TimerController(clock: () => DateTime(2026, 1, 1));
        await tester.pumpWidget(_harness(controller));

        await tester.tap(find.text('Custom'));
        await tester.pump();
        await tester.ensureVisible(find.byKey(const ValueKey('stepper-plus')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('stepper-plus')));
        await tester.pump();
        expect(find.text('4'), findsOneWidget);

        await tester.ensureVisible(find.text('10'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('10')); // closes Custom
        await tester.pump();
        expect(find.byKey(const ValueKey('stepper-minus')), findsNothing);

        await tester.ensureVisible(find.text('Custom'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Custom')); // reopens
        await tester.pump();

        expect(find.text('4'), findsOneWidget);

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

  group('SetupScreen persistence (PERSIST-01)', () {
    testWidgets(
      'seeds the scene selection from initialTheme (no default->restored flash)',
      (WidgetTester tester) async {
        final controller = TimerController(clock: () => DateTime(2026, 1, 1));
        await tester.pumpWidget(
          _harness(controller, initialTheme: SceneTheme.walk),
        );

        await tester.ensureVisible(find.text('Walking home'));
        await tester.pumpAndSettle();

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

    testWidgets(
      'Start persists theme and duration when a preset is selected (D-10)',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({});
        final controller = TimerController(clock: () => DateTime(2026, 1, 1));
        await tester.pumpWidget(_harness(controller));

        await tester.tap(find.text('10'));
        await tester.pump();
        await tester.ensureVisible(find.text('Walking home'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Walking home'));
        await tester.pump();

        await tester.tap(find.byKey(const ValueKey('start-button')));
        await tester.pumpAndSettle();

        final restored = await SetupPreferences.load();
        expect(restored.durationMin, 10);
        expect(restored.theme, SceneTheme.walk);

        controller.dispose();
      },
    );

    testWidgets(
      'Start persists theme but leaves durationMin untouched when Custom '
      'is selected (D-10, Pitfall 4)',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({
          'durationMin': 10,
          'theme': 'disc',
        });
        final controller = TimerController(clock: () => DateTime(2026, 1, 1));
        await tester.pumpWidget(_harness(controller));

        await tester.tap(find.text('Custom'));
        await tester.pump();
        await tester.ensureVisible(find.byKey(const ValueKey('stepper-plus')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('stepper-plus')));
        await tester.pump();

        await tester.tap(find.byKey(const ValueKey('start-button')));
        await tester.pumpAndSettle();

        final restored = await SetupPreferences.load();
        expect(restored.durationMin, 10); // untouched -- custom never persisted
        expect(restored.theme, SceneTheme.disc);

        controller.dispose();
      },
    );
  });
}
