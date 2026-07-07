import 'package:flutter_test/flutter_test.dart';

import 'package:zual/main.dart';
import 'package:zual/timer/timer_controller.dart';

void main() {
  testWidgets('Displays the Zual wordmark on launch', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp(timerController: TimerController()));

    expect(find.text('Zual'), findsOneWidget);
  });
}
