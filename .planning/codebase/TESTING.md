# Testing Patterns

**Analysis Date:** 2026-08-19

## Test Framework

**Runner:**
- `flutter_test` (part of Flutter SDK)
- Config: `pubspec.yaml` dev_dependencies section
- No separate test configuration file (uses Flutter defaults)

**Assertion Library:**
- Dart's built-in `expect()` function from `flutter_test`
- Uses `find.*` matchers for widget discovery
- Uses `findsOneWidget`, `findsWidgets`, `findsNothing` matchers
- Uses `closeTo()`, `greaterThan()`, `isA()` for precise matching

**Run Commands:**
```bash
flutter test                   # Run all tests (134 tests, 21 _test.dart files)
flutter test test/timer/timer_controller_test.dart  # Run a specific test file
flutter test --name "T-02-02"  # Run tests whose name matches a requirement/threat ID
flutter analyze               # Run static analysis (no issues currently)
# flutter test --coverage would work but coverage reporting is not configured
# NOTE: `flutter test` has no --watch flag. Use your IDE's test runner for re-run-on-save.
```

**Current Status:**
- 134 tests, all passing
- 21 `_test.dart` files + 4 non-suffixed helper/generator files
- ~2,846 lines of test code in `test/` directory
- No CI/CD pipeline configured (no `.github/workflows/`)

## Test File Organization

**Location:**
- Mirrors source structure under `test/` directory
- `lib/widgets/hold_repeat_button.dart` → `test/widgets/hold_repeat_button_test.dart`
- `lib/timer/timer_controller.dart` → `test/timer/timer_controller_test.dart`
- Shared test support in `test/support/` (e.g., `progress_sweep.dart`)
- Tool/generator code in `test/tool/` (headless PNG rendering)

**Naming:**
- `*_test.dart` suffix for all discoverable test files (matched by `flutter test`)
- Special case: `test/tool/generate_feature_graphic.dart` deliberately omits `_test.dart` suffix to prevent auto-run (see Gotchas)

**Structure:**
```
test/
├── audio/
│   └── chime_synth_test.dart
├── scenes/
│   ├── car/
│   │   ├── car_painter_test.dart
│   │   └── car_scene_test.dart
│   ├── disc/
│   ├── sunrise/
│   ├── walk/
│   ├── scene_preview_test.dart
│   ├── scene_registry_test.dart
│   ├── scene_renderer_test.dart
├── screens/
│   ├── running_screen_test.dart
│   └── setup_screen_test.dart
├── settings/
│   └── setup_preferences_test.dart
├── timer/
│   └── timer_controller_test.dart
├── widgets/
│   └── hold_repeat_button_test.dart
├── support/
│   └── progress_sweep.dart      # Shared helper for painter sweep tests
├── tool/
│   ├── generate_launcher_icon_test.dart     # PNG generator (runs via flutter test)
│   ├── generate_store_icon_test.dart        # PNG generator (runs via flutter test)
│   ├── generate_feature_graphic.dart        # PNG generator (no _test suffix, manual run)
│   ├── icon_painters.dart                   # Helper for icon rendering
│   └── icon_renderer.dart                   # Helper: renderPainterToPng()
├── widget_test.dart             # Root integration test
```

## Test Structure

**Suite Organization — Unit Tests:**
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:zual/timer/timer_controller.dart';

void main() {
  group('TimerController', () {
    test('a freshly constructed controller reports setup phase and zero progress', () {
      final controller = TimerController(clock: () => DateTime(2026, 1, 1));
      
      expect(controller.phase, TimerPhase.setup);
      expect(controller.progress, 0.0);
      
      controller.dispose();
    });
    
    test('progress clamps when injected clock moves backward', () {
      var now = DateTime(2026, 1, 1, 12, 0, 0);
      final controller = TimerController(clock: () => now);
      
      controller.start(10);
      now = now.add(const Duration(minutes: 6)); // 60% elapsed
      controller.syncToWallClock();
      final progressAtSixtyPercent = controller.progress;
      
      now = now.subtract(const Duration(minutes: 4)); // clock moved backward
      controller.syncToWallClock();
      
      expect(controller.progress, progressAtSixtyPercent); // no regression
    });
  });
}
```

**Suite Organization — Widget Tests:**
```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HoldRepeatButton', () {
    testWidgets('a quick tap fires onStep exactly once, with no repeat', (
      WidgetTester tester,
    ) async {
      var count = 0;
      await tester.pumpWidget(_harness(onStep: () => count++, enabled: true));
      
      await tester.tap(find.byKey(const ValueKey('hold-button')));
      await tester.pump(); // pump, never sleep()
      expect(count, 1);
      
      await tester.pump(const Duration(seconds: 1)); // fake time advance
      expect(count, 1);
    });
  });
}
```

**Patterns:**
- `void main()` entry point containing all test suites
- `group(name, () { ... })` for test organization
- `test()` for unit tests (pure Dart, no widget tree)
- `testWidgets()` for widget tests (requires `WidgetTester`)
- Setup: Call `tester.pumpWidget(widget)` to render widget, or inject dependencies
- Assertions: Use `expect(actual, matcher)` pattern
- Async: All widget tests use `async/await`

**Test Naming Convention — Requirement/Threat IDs:**
Every test name includes one or more IDs tying it to a planning artifact:
- `SETUP-01`, `SETUP-02` — Setup screen behavior (from 04-PLAN.md or later)
- `V5` — Input Validation control (see `lib/screens/setup_screen.dart` lines 90, 114: the
  single clamped write path that holds regardless of any button's disabled state)
- `T-02-01`, `T-02-02` — Tampering/security threats (T-02 = stored data tampering)
- `PERSIST-01` — Persistence requirement (from D-10, D-09)
- `CTRL-03`, `CTRL-04` — Timer control transitions (from 03-UI-SPEC.md)
- `D-04`, `D-09`, `D-10` — Design requirement IDs (from 03-UI-SPEC.md)
- `SCENE-04`, `SCENE-05` — Scene rendering constraints
- `CR-01` — Content Requirement / regression guard (e.g., wheel spin visibility)
- `WR-01` — Write/asset requirement (icon generation)

Examples from actual tests:
```dart
test('renders the five duration presets and selects the tapped one (SETUP-01)', ...)
test('reaching TimerPhase.done dwells on RunningScreen showing the "All done" pill, and tapping it returns to Setup (CTRL-03/CTRL-04)', ...)
test('load() clamps an out-of-range stored durationMin (Tampering, T-02-02)', ...)
test('Start persists theme and duration when a preset is selected (D-10)', ...)
```

## Mocking

**Framework & Strategy:**
- NO `mockito`, `mocktail`, or similar mocking libraries in dependencies
- Hand-written fakes implementing real interfaces (preferred for this codebase)
- Built-in mock support from `shared_preferences` package: `SharedPreferences.setMockInitialValues()`
- Injected dependencies via constructor parameters or provider pattern

**Hand-Written Fakes:**
These are production-like doubles that implement the real interface:

`test/timer/timer_controller_test.dart`:
```dart
class FakeScreenWake implements ScreenWake {
  int enableCalls = 0;
  int disableCalls = 0;

  @override
  Future<void> enable() async {
    enableCalls++;
  }

  @override
  Future<void> disable() async {
    disableCalls++;
  }
}

// Used like:
final fakeWake = FakeScreenWake();
final controller = TimerController(
  clock: () => DateTime(2026, 1, 1),
  screenWake: fakeWake,
);
```

Production no-op doubles available for testing (in `lib/`, not test-only):
- `lib/timer/screen_wake.dart`: `NoopScreenWake` (does nothing, safe for tests)
- `lib/audio/chime_player.dart`: `NoopChimePlayer` (silent, safe for tests)

**Built-in Mock Support:**
`test/settings/setup_preferences_test.dart`:
```dart
test('load() with no stored values returns durationMin 5 and theme disc (D-09)', () async {
  SharedPreferences.setMockInitialValues({});
  
  final prefs = await SetupPreferences.load();
  
  expect(prefs.durationMin, 5);
  expect(prefs.theme, SceneTheme.disc);
});

test('load() clamps an out-of-range stored durationMin (Tampering, T-02-02)', () async {
  SharedPreferences.setMockInitialValues({'durationMin': 999});
  final tooHigh = await SetupPreferences.load();
  expect(tooHigh.durationMin, 120);
});
```

**What to Mock/Fake:**
- Platform-specific services (screen wake, audio, storage) → Use Noop doubles
- Time-dependent behavior → Inject `clock: () => DateTime` to control time
- Heavy external dependencies → Hand-written fakes are preferred over mockito

**What NOT to Mock:**
- Flutter widgets (Material, Scaffold, etc.) — use real widget tree
- Simple utility functions (no mocking overhead worth it)
- Painters and rendering logic — test with real rasterization

## Fake Time & Deterministic Testing

**Critical Pattern — Never Use `sleep()`:**

Widget tests advance Flutter's fake timer clock, not real wall time. Using `sleep()` would deadlock the fake timer:

```dart
// WRONG: This will hang or timeout in tests
await Future.delayed(const Duration(milliseconds: 500));

// RIGHT: Use tester.pump(duration) to advance fake time
await tester.pump(const Duration(milliseconds: 500));
```

**Time Injection Pattern:**
Classes that need time implement a `clock` parameter:

```dart
// lib/timer/timer_controller.dart
class TimerController {
  TimerController({
    DateTime Function()? clock,
    Duration? tickInterval,
    ScreenWake? screenWake,
  })
    : _clock = clock ?? DateTime.now,
      _tickInterval = tickInterval ?? const Duration(milliseconds: 200),
      _screenWake = screenWake ?? const NoopScreenWake();
}
```

Tests inject a controlled clock:
```dart
var now = DateTime(2026, 1, 1, 12, 0, 0);
final controller = TimerController(clock: () => now);
controller.start(5); // 5 minutes
now = now.add(const Duration(minutes: 2, seconds: 30)); // halfway
controller.syncToWallClock();
expect(controller.progress, closeTo(0.5, 0.01));
```

**HoldRepeatButton Acceleration Testability:**
`lib/widgets/hold_repeat_button.dart` deliberately accumulates scheduled durations instead of reading wall-clock time (lines 49–55):

```dart
/// Total time held so far, tracked as the sum of already-elapsed repeat
/// intervals rather than read from a wall clock (e.g. `DateTime.now()`).
/// A wall-clock read would desync from Flutter's test-time `Timer`
/// scheduling under `tester.pump(duration)` (widget tests advance a fake
/// timer clock, not real wall-clock time), making acceleration
/// untestable; accumulating scheduled durations is deterministic under
/// both real and fake time.
Duration _heldDuration = Duration.zero;

// Updated on every repeat tick:
_heldDuration += interval; // line 79
```

This allows tests to verify acceleration thresholds by holding across wall-time boundaries:
```dart
await tester.pump(const Duration(milliseconds: 1900)); // approach 2s threshold
final countAfterFirstWindow = count;
await tester.pump(const Duration(milliseconds: 1900)); // cross 2s threshold
final secondWindowCalls = count - countAfterFirstWindow;
expect(secondWindowCalls, greaterThan(countAfterFirstWindow));
```

## Fixtures and Factories

**Test Data & Helpers:**

`test/support/progress_sweep.dart` — Shared painter-test helper:
```dart
/// Pumps [scene] wrapped with a running [TimerController] provider across a
/// fixed series of progress checkpoints (default 0.0, 0.25, 0.5, 0.75, 1.0),
/// driving an injected-clock controller so progress advances deterministically.
Future<void> pumpProgressSweep(
  WidgetTester tester,
  Widget scene, {
  List<double> checkpoints = const [0.0, 0.25, 0.5, 0.75, 1.0],
  int totalMinutes = 1,
}) async {
  final startTime = DateTime(2026, 1, 1);
  var now = startTime;
  final controller = TimerController(clock: () => now);

  controller.start(totalMinutes);

  await tester.pumpWidget(
    ChangeNotifierProvider<TimerController>.value(
      value: controller,
      child: MaterialApp(home: scene),
    ),
  );

  final totalMs = Duration(minutes: totalMinutes).inMilliseconds;
  for (final checkpoint in checkpoints) {
    now = startTime.add(
      Duration(milliseconds: (totalMs * checkpoint).round()),
    );
    controller.syncToWallClock();
    await tester.pump(const Duration(milliseconds: 16));
  }

  controller.dispose(); // Must dispose before test invariant check
}
```

**Usage — Painter Tests:**
Every scene painter is tested by sweeping through 0.0 → 1.0 progress:
```dart
testWidgets(
  'renders without throwing across the full 0.0->1.0 progress sweep, '
  'including exactly 1.0 (SCENE-04)',
  (WidgetTester tester) async {
    await pumpProgressSweep(tester, const CarScene());
    expect(tester.takeException(), isNull);
  },
);
```

**Painter Rendering Helper:**

`test/tool/icon_renderer.dart` — Headless PNG rasterization:
```dart
/// Renders a [CustomPainter] headlessly to PNG bytes.
/// Builds a PictureRecorder-backed Canvas, invokes paint(canvas, size) directly,
/// then rasterizes to PNG via Picture.toImage + Image.toByteData.
Future<Uint8List> renderPainterToPng(CustomPainter painter, Size size) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  painter.paint(canvas, size);
  final picture = recorder.endRecording();
  final image = await picture.toImage(
    size.width.toInt(),
    size.height.toInt(),
  );
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  return byteData!.buffer.asUint8List();
}
```

Used by painter regressions tests:
```dart
test(
  'rendered rasters at spinAngle 0.0 vs pi/2 are NOT byte-identical',
  () async {
    const size = Size(200, 400);
    final bytesAtZero = await renderRawRgba(0.0, size);
    final bytesAtHalfPi = await renderRawRgba(pi / 2, size);
    
    // Fails if wheel spin marking is missing (regression guard CR-01)
    expect(listEquals(bytesAtZero, bytesAtHalfPi), isFalse);
  },
);
```

**Location:**
- Shared helpers: `test/support/`
- Tool/generators: `test/tool/`
- Painter utilities: `test/tool/icon_renderer.dart`, `icon_painters.dart`
- Co-located test harnesses: Same file as test (e.g., `_harness()` in `setup_screen_test.dart`)

## Test Types

**Unit Tests** (using `test()`):
- Scope: Single class/function in isolation
- Examples: `TimerController`, `SetupPreferences`, `ChimeSynth`
- Location: `test/timer/`, `test/settings/`, `test/audio/`
- Setup: Inject dependencies via constructor; use `SharedPreferences.setMockInitialValues()` for storage
- 134 total tests include both unit and widget tests mixed

**Widget Tests** (using `testWidgets()`):
- Scope: Single widget or short interaction chain
- Examples: `HoldRepeatButton` tap/hold sequences, `SetupScreen` preset selection, scene rendering
- Location: `test/widgets/`, `test/screens/`, `test/scenes/`
- Setup: `tester.pumpWidget(_harness(...))` to render under test
- Key methods: `tap()`, `pump(duration)`, `startGesture()`, `pumpWidget()`

**Integration Tests:**
- Scope: Full app or user journey (not yet configured)
- `test/widget_test.dart` is closest to integration (tests root app)
- No `integration_test/` package configured
- To add: Create `integration_test/app_test.dart`, run with `flutter test integration_test/`

## Coverage

**Requirements:** 
- Not enforced via `analysis_options.yaml`
- No coverage tooling configured in `pubspec.yaml`
- Command `flutter test --coverage` is available but results not tracked

**View Coverage (if needed):**
```bash
flutter test --coverage
# Results in: coverage/lcov.info

# View in browser (requires lcov tools):
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## Known Coverage Gaps

**Entry Point & Wiring:**
- `lib/main.dart` — Not directly tested; covered indirectly by `test/widget_test.dart`
- `lib/timer/timer_lifecycle_binder.dart` — Untested (wires lifecycle to timer, low risk)

**Production Implementations (Fakes Tested Instead):**
- `lib/audio/audioplayers_chime_player.dart` — Not tested; relies on `NoopChimePlayer` in tests
- `lib/timer/wakelock_screen_wake.dart` — Not tested; relies on `FakeScreenWake` in tests

**UI Components (Indirectly Tested via Screens):**
- `lib/widgets/pressable_surface.dart` — Not directly tested; exercised by `SetupScreen` and scene tapping
- `lib/widgets/scene_grid.dart` — Not directly tested; exercised by `SetupScreen` scene card selection
- `lib/theme/app_tokens.dart` — Not directly tested; applied throughout UI

**Placeholder/Unused:**
- `lib/screens/placeholder_running_screen.dart` — Confirmed dead code, not "likely": no import
  of it exists anywhere in `lib/` or `test/`. Slated for deletion; see `CONCERNS.md`.

**Strategies to Improve Coverage:**
1. Add unit tests for `TimerLifecycleBinder` if its logic grows complex
2. Add explicit widget tests for `PressableSurface` and `SceneGrid` if behavior becomes critical
3. Consider `integration_test/` for full app journeys (e.g., "select scene → set timer → run → complete")
4. Enable coverage tooling if coverage targets are set (currently not required)

## Test Naming Conventions & Artifacts

**Requirement/Threat IDs in Test Names:**

Test names deliberately reference planning artifacts so test intent is traceable. Key ID families:

| Prefix | Source | Examples |
|--------|--------|----------|
| `SETUP-NN` | 04-PLAN.md or setup phase plan | `SETUP-01` (preset selection), `SETUP-02` (custom stepper) |
| `D-NN` | 03-UI-SPEC.md design requirements | `D-04` (sound default), `D-09` (duration default), `D-10` (persistence) |
| `V5` | Input Validation control | Custom stepper cannot exceed 1–120 even if `onStep` is called directly |
| `T-NN-MM` | 03-RESEARCH.md threats | `T-02-02` (stored data tampering), `T-04-03` (wrong-type stored data) |
| `PERSIST-01` | Persistence requirement | Round-trip storage test |
| `CTRL-NN` | Timer control/lifecycle | `CTRL-03`, `CTRL-04` (done state transitions) |
| `SCENE-NN` | Scene rendering constraints | `SCENE-04` (render full sweep), `SCENE-05` (no gesture/text) |
| `CR-01` | Content regression guard | Wheel spin visible (raster diff) |
| `WR-01` | Write/asset requirements | Icon generation output |

Find all IDs currently referenced in test names:
```bash
grep -rhoE '\b(SETUP|PERSIST|CTRL|SCENE|CR|WR|D|T)-[0-9]{2}(-[0-9]{2})?\b' test | sort -u
```

## Important Gotchas

### PNG Generators Run as Tests (Side Effect)

`test/tool/generate_launcher_icon_test.dart` and `test/tool/generate_store_icon_test.dart` carry the `_test.dart` suffix, so `flutter test` discovers and runs them. **Side effect: they rewrite committed PNG files as part of the test run.**

This is **known tech debt, not a feature** — flagged as WR-04/WR-05 in `05-REVIEW.md` and
recorded in `.planning/codebase/CONCERNS.md`. Do not rely on it:
- Output is byte-stable today (same input → same PNG bytes), so the tree normally stays clean
- But that is a property of the current painters, not a guarantee. Any change to rendering
  logic, encoding, or dependency versions makes a routine `flutter test` silently mutate
  committed binaries.
- A test run should have no side effects on tracked files, full stop.

The intended fix is the pattern `generate_feature_graphic.dart` already demonstrates: drop the
`_test.dart` suffix so the generator is never auto-discovered, and pair it with a read-only
drift-lock `_test.dart` that re-renders in memory and byte-diffs against the committed file,
failing loudly instead of overwriting.

### Feature Graphic Generator Avoids Auto-Run

`test/tool/generate_feature_graphic.dart` deliberately omits `_test.dart` suffix (lines 16–19):
```dart
/// Deliberately named WITHOUT the `_test.dart` suffix: a bare `flutter test`
/// only discovers `test/**/*_test.dart`, so this generator is never
/// auto-run and therefore never silently overwrites the committed PNG on a
/// routine test run (05-REVIEW.md WR-04 fix option (a): "not matched by
/// `flutter test`"). It must still be invoked explicitly via
```

Run manually when needed — via `flutter test`, **not** `dart run`. The file's own header
explains why: `dart:ui`'s rasterization APIs have no headless backend outside the Flutter test
engine, so `dart run` cannot execute it.

```bash
flutter test test/tool/generate_feature_graphic.dart
```

Its committed output is guarded by the read-only drift-lock test
`test/tool/feature_graphic_test.dart`, which verifies the PNG without rewriting it.

### No CI/CD Pipeline

No `.github/workflows/` directory exists. Tests are run locally. If CI is added later:
- Ensure PNG generators don't dirty the tree (make output byte-stable)
- Run `flutter analyze` and `flutter test` in CI workflow
- Consider adding coverage reporting if targets are set

## Common Patterns

**Async Testing (Widget Tests):**
```dart
testWidgets('async operation completes', (WidgetTester tester) async {
  var completed = false;
  await tester.pumpWidget(_harness(
    onComplete: () => completed = true,
  ));

  // Trigger async operation
  await tester.tap(find.byKey(const ValueKey('button')));
  
  // Advance fake time for Future to complete
  await tester.pump(const Duration(milliseconds: 500));

  expect(completed, isTrue);
});
```

**Gesture Testing (Long Press with Acceleration):**
```dart
testWidgets('long-press accelerates firing', (WidgetTester tester) async {
  var count = 0;
  await tester.pumpWidget(_harness(onStep: () => count++));

  final gesture = await tester.startGesture(tester.getCenter(find.byKey(...)));
  
  // Hold for 1.9 seconds (under 2s acceleration threshold)
  await tester.pump(const Duration(milliseconds: 1900));
  final countAfterFirstThreshold = count;
  
  // Hold for another 1.9 seconds (crosses 2s, hits faster interval)
  await tester.pump(const Duration(milliseconds: 1900));
  final countInSecondWindow = count - countAfterFirstThreshold;
  
  // Verify second window produces more counts (faster interval)
  expect(countInSecondWindow, greaterThan(countAfterFirstThreshold));
  
  await gesture.up();
});
```

**State Clamping & Validation (Unit Test):**
```dart
test('progress clamps to [0, 1]', () {
  var now = DateTime(2026, 1, 1);
  final controller = TimerController(clock: () => now);
  
  controller.start(5);
  now = now.subtract(const Duration(minutes: 1)); // backward
  controller.syncToWallClock();
  
  expect(controller.progress, greaterThanOrEqualTo(0.0));
  expect(controller.progress, lessThanOrEqualTo(1.0));
});
```

**Widget Mounting & Cleanup (Robustness):**
```dart
testWidgets(
  'unmounting the widget mid-hold cancels the repeat Timer cleanly',
  (WidgetTester tester) async {
    var count = 0;
    await tester.pumpWidget(_harness(onStep: () => count++));

    final gesture = await tester.startGesture(...);
    await tester.pump(const Duration(milliseconds: 900));
    final countBeforeUnmount = count;

    // Replace the tree entirely -- disposes without onLongPressEnd
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));

    // No exception, no further onStep calls
    await tester.pump(const Duration(seconds: 2));
    expect(count, countBeforeUnmount);

    await gesture.up();
  },
);
```

**Painter Rendering (Raster Comparison):**
```dart
test('wheel spin is visible (CR-01 regression)', () async {
  const size = Size(200, 400);
  
  final bytesAtZero = await renderRawRgba(0.0, size);
  final bytesAtHalfPi = await renderRawRgba(pi / 2, size);
  
  // Rasters must differ if spin marking is present
  expect(listEquals(bytesAtZero, bytesAtHalfPi), isFalse);
});
```

---

*Testing analysis: 2026-08-19*
