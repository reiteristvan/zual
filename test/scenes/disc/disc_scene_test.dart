import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zual/scenes/disc/disc_scene.dart';

import '../../support/progress_sweep.dart';

void main() {
  group('DiscScene', () {
    testWidgets(
      'renders without throwing across the full 0.0->1.0 progress sweep, '
      'including exactly 1.0 (SCENE-01)',
      (WidgetTester tester) async {
        await pumpProgressSweep(tester, const DiscScene());
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'has no gesture-reactive ancestor and no visible text in its subtree '
      '(SCENE-05)',
      (WidgetTester tester) async {
        await pumpProgressSweep(
          tester,
          const DiscScene(),
          checkpoints: const [0.5],
        );

        final sceneSubtree = find.byType(DiscScene);
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
