import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zual/widgets/hold_repeat_button.dart';

/// Wraps [HoldRepeatButton] in a minimal harness. The button carries a
/// [ValueKey] so gestures can be targeted precisely without depending on the
/// child content.
Widget _harness({required VoidCallback onStep, required bool enabled}) {
  return MaterialApp(
    home: Scaffold(
      body: HoldRepeatButton(
        key: const ValueKey('hold-button'),
        onStep: onStep,
        enabled: enabled,
        child: const Text('+'),
      ),
    ),
  );
}

void main() {
  group('HoldRepeatButton', () {
    testWidgets('a quick tap fires onStep exactly once, with no repeat', (
      WidgetTester tester,
    ) async {
      var count = 0;
      await tester.pumpWidget(_harness(onStep: () => count++, enabled: true));

      await tester.tap(find.byKey(const ValueKey('hold-button')));
      await tester.pump();
      expect(count, 1);

      // No repeat should follow a quick tap even once time passes.
      await tester.pump(const Duration(seconds: 1));
      expect(count, 1);
    });

    testWidgets(
      'a long-press held across the acceleration thresholds fires onStep '
      'more frequently the longer it is held',
      (WidgetTester tester) async {
        var count = 0;
        await tester.pumpWidget(
          _harness(onStep: () => count++, enabled: true),
        );

        final gesture = await tester.startGesture(
          tester.getCenter(find.byKey(const ValueKey('hold-button'))),
        );

        // Hold from t=0 to ~1.9s (still under the 2s mid-acceleration mark):
        // the ~500ms long-press threshold step plus repeats at ~350ms.
        await tester.pump(const Duration(milliseconds: 1900));
        final countAfterFirstWindow = count;
        expect(
          countAfterFirstWindow,
          greaterThanOrEqualTo(2),
          reason:
              'the ~500ms threshold step plus at least one ~350ms repeat '
              'should have fired by 1.9s of holding',
        );

        // Hold for an equal further window, now crossing past the 2s mark
        // into the faster ~150ms repeat interval.
        await tester.pump(const Duration(milliseconds: 1900));
        final secondWindowCalls = count - countAfterFirstWindow;

        expect(
          secondWindowCalls,
          greaterThan(countAfterFirstWindow),
          reason:
              'the accelerated (~150ms) interval should produce more steps '
              'in an equal time window than the initial (~350ms) interval',
        );

        await gesture.up();
      },
    );

    testWidgets('releasing (long-press end) stops further repeat steps', (
      WidgetTester tester,
    ) async {
      var count = 0;
      await tester.pumpWidget(_harness(onStep: () => count++, enabled: true));

      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('hold-button'))),
      );
      await tester.pump(const Duration(milliseconds: 900)); // a few ticks
      final countBeforeRelease = count;
      expect(countBeforeRelease, greaterThanOrEqualTo(1));

      await gesture.up();
      await tester.pump(const Duration(seconds: 2));

      expect(count, countBeforeRelease);
    });

    testWidgets('when enabled is false, neither tap nor hold fires onStep', (
      WidgetTester tester,
    ) async {
      var count = 0;
      await tester.pumpWidget(
        _harness(onStep: () => count++, enabled: false),
      );

      await tester.tap(find.byKey(const ValueKey('hold-button')));
      await tester.pump();
      expect(count, 0);

      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('hold-button'))),
      );
      await tester.pump(const Duration(seconds: 3));
      await gesture.up();

      expect(count, 0);
    });

    testWidgets(
      'unmounting the widget mid-hold cancels the repeat Timer cleanly '
      '(no exception, no further onStep calls)',
      (WidgetTester tester) async {
        var count = 0;
        await tester.pumpWidget(
          _harness(onStep: () => count++, enabled: true),
        );

        final gesture = await tester.startGesture(
          tester.getCenter(find.byKey(const ValueKey('hold-button'))),
        );
        await tester.pump(const Duration(milliseconds: 900));
        final countBeforeUnmount = count;
        expect(countBeforeUnmount, greaterThanOrEqualTo(1));

        // Replace the tree entirely -- disposes HoldRepeatButton's State
        // without ever firing onLongPressEnd/onLongPressCancel, exactly the
        // scenario dispose() must guard against (Pitfalls 1/2).
        await tester.pumpWidget(const MaterialApp(home: SizedBox()));

        // No exception thrown by the pumpWidget above, and no further
        // onStep calls even after more time passes.
        await tester.pump(const Duration(seconds: 2));
        expect(count, countBeforeUnmount);

        await gesture.up();
      },
    );
  });
}
