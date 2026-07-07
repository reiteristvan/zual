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
}
