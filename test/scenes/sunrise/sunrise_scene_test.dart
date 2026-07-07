import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zual/scenes/sunrise/sunrise_scene.dart';

import '../../support/progress_sweep.dart';

void main() {
  group('SunriseScene', () {
    testWidgets(
      'renders without throwing across the full 0.0->1.0 progress sweep, '
      'including past p=0.435 (stars) and p=0.588 (moon) where the raw '
      'fade formulas go negative (SCENE-02)',
      (WidgetTester tester) async {
        await pumpProgressSweep(
          tester,
          const SunriseScene(),
          checkpoints: const [0.0, 0.2, 0.435, 0.5, 0.588, 0.75, 1.0],
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'has no gesture-reactive ancestor and no visible text in its subtree '
      '(SCENE-05)',
      (WidgetTester tester) async {
        await pumpProgressSweep(
          tester,
          const SunriseScene(),
          checkpoints: const [0.5],
        );

        final sceneSubtree = find.byType(SunriseScene);
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
