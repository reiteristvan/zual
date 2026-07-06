import 'package:flutter_test/flutter_test.dart';

import 'package:zual/main.dart';

void main() {
  testWidgets('Displays Hello, World!', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Hello, World!'), findsOneWidget);
  });
}
