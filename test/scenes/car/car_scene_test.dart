import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zual/scenes/car/car_scene.dart';

import '../../support/progress_sweep.dart';

void main() {
  group('CarScene', () {
    testWidgets(
      'renders without throwing across the full 0.0->1.0 progress sweep, '
      'including exactly 1.0 (SCENE-04)',
      (WidgetTester tester) async {
        await pumpProgressSweep(tester, const CarScene());
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'has no gesture-reactive ancestor and no visible text in its subtree '
      '(SCENE-05)',
      (WidgetTester tester) async {
        await pumpProgressSweep(
          tester,
          const CarScene(),
          checkpoints: const [0.5],
        );

        final sceneSubtree = find.byType(CarScene);
        expect(sceneSubtree, findsOneWidget);
        expect(
          find.descendant(
            of: sceneSubtree,
            matching: find.byType(GestureDetector),
          ),
          findsNothing,
        );
        expect(
          find.descendant(of: sceneSubtree, matching: find.byType(InkWell)),
          findsNothing,
        );
        expect(
          find.descendant(of: sceneSubtree, matching: find.byType(Text)),
          findsNothing,
        );
      },
    );
  });
}
