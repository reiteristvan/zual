# Testing Patterns

**Analysis Date:** 2026-07-06

## Test Framework

**Runner:**
- `flutter_test` (part of Flutter SDK)
- Config: `pubspec.yaml` dev_dependencies section
- No separate test configuration file (uses Flutter defaults)

**Assertion Library:**
- Dart's built-in `expect()` function from `flutter_test`
- Uses `find.*` matchers for widget discovery
- Uses `findsOneWidget`, `findsWidgets`, `findsNothing` matchers

**Run Commands:**
```bash
flutter test                    # Run all tests
flutter test test/widget_test.dart  # Run specific test file
flutter test --watch           # Watch mode
flutter test --coverage        # Generate coverage report
flutter analyze               # Run static analysis (linting)
```

## Test File Organization

**Location:**
- Co-located with source in `test/` directory at project root
- Mirror source structure: `lib/widgets/my_widget.dart` → `test/widgets/my_widget_test.dart`

**Naming:**
- `*_test.dart` suffix for all test files
- Example: `widget_test.dart`, `app_test.dart`

**Structure:**
```
test/
├── widget_test.dart          # Widget/integration tests
├── widgets/
│   └── my_widget_test.dart   # Widget-specific tests (future)
├── screens/
│   └── home_screen_test.dart # Screen-specific tests (future)
└── services/
    └── api_service_test.dart # Service/unit tests (future)
```

## Test Structure

**Suite Organization:**
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:zual/main.dart';

void main() {
  testWidgets('Displays Hello, World!', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    
    expect(find.text('Hello, World!'), findsOneWidget);
  });
}
```

**Patterns:**
- `void main()` entry point containing all test suites
- `testWidgets()` for widget tests (name, async callback with WidgetTester)
- `test()` for unit tests (not yet used, available for non-widget tests)
- Setup: Call `tester.pumpWidget(widget)` to render widget under test
- Assertions: Use `expect(finder, matcher)` pattern
- Async: All widget tests use `async/await`

## Mocking

**Framework:** 
- No explicit mocking framework currently configured
- When needed, consider: `mockito` package for Dart mocking
- Flutter provides built-in mocking via `Mock` classes in `flutter_test`

**Patterns:**
- Not yet demonstrated in current codebase
- Future pattern when needed:
  ```dart
  import 'package:mockito/mockito.dart';
  
  class MockService extends Mock implements MyService {}
  
  void main() {
    test('uses mocked service', () {
      final mockService = MockService();
      when(mockService.getData()).thenAnswer((_) async => []);
      // test code
    });
  }
  ```

**What to Mock:**
- External API calls and HTTP requests
- Database access and data repositories
- Complex service dependencies
- Timer and async operations for deterministic testing

**What NOT to Mock:**
- Built-in Flutter widgets and framework classes
- Simple utility functions
- The widget under test itself
- Navigation (can mock, but often better to use real navigation in integration tests)

## Fixtures and Factories

**Test Data:**
- Not yet implemented in current codebase
- When needed, create helper functions or factory classes:
  ```dart
  // In test/fixtures/app_fixtures.dart
  class AppFixtures {
    static MyApp createApp() => const MyApp();
    static MyHomePage createHomePage() => const MyHomePage();
  }
  ```

**Location:**
- `test/fixtures/` for shared test data
- `test/helpers/` for test helper functions
- Co-locate in test file if used by single test only

## Coverage

**Requirements:** 
- Not enforced in `analysis_options.yaml`
- Recommend: Minimum 70% for critical paths, 80% for new features
- Coverage reports generated to `coverage/` directory

**View Coverage:**
```bash
flutter test --coverage
# Results in: coverage/lcov.info

# View in browser (requires lcov tools):
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## Test Types

**Unit Tests:**
- Scope: Single function or class in isolation
- Framework: `test()` function
- Use when: Testing business logic, algorithms, calculations
- Example: Testing data models, utilities, calculations
- Future location: `test/services/`, `test/utils/`, `test/models/`

**Widget Tests:**
- Scope: Single widget and its immediate children
- Framework: `testWidgets()` with `WidgetTester`
- Use when: Testing widget rendering, user interactions, state changes
- Example: Testing button presses, text display, navigation
- Current location: `test/widget_test.dart`
- Key methods: `pumpWidget()`, `pump()`, `enterText()`, `tap()`

**Integration Tests (Not yet configured):**
- Scope: Full app or major user flow
- Framework: `integration_test/` package (separate from flutter_test)
- Use when: Testing complete user journeys, app startup, multi-screen flows
- Not currently configured; add `integration_test/` directory when needed

## Common Patterns

**Async Testing:**
```dart
testWidgets('Async operation completes', (WidgetTester tester) async {
  await tester.pumpWidget(MyApp());
  
  // Trigger async operation
  await tester.tap(find.byIcon(Icons.add));
  
  // Wait for frames to complete
  await tester.pumpAndSettle();  // Waits for all animations
  
  expect(find.text('Complete'), findsOneWidget);
});
```

**Error Testing:**
```dart
test('Throws exception on invalid input', () {
  expect(
    () => MyFunction.process(null),
    throwsA(isA<ArgumentError>()),
  );
});

// Or with async:
testWidgets('Handles network error', (WidgetTester tester) async {
  await tester.pumpWidget(MyApp());
  
  // Simulate error
  // expect error handling
});
```

**Widget Finding:**
```dart
find.text('Hello')                    // Find by text
find.byType(FloatingActionButton)     // Find by widget type
find.byIcon(Icons.add)                // Find by icon
find.byWidgetPredicate((w) => ...)    // Find by custom predicate
find.descendant(of: parent, matching: child)  // Find descendants
```

**Interactions:**
```dart
await tester.tap(find.byType(FloatingActionButton));
await tester.enterText(find.byType(TextField), 'text');
await tester.drag(find.byType(Scrollable), Offset(0, -300));
await tester.pumpAndSettle();  // Wait for animations
```

---

*Testing analysis: 2026-07-06*
