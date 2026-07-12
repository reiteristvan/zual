# Phase 2: Setup Screen - Pattern Map

**Mapped:** 2026-07-07
**Files analyzed:** 13 (new) + 2 (modified)
**Analogs found:** 6 strong-structural / 0 exact-role (no prior UI code exists) out of 15

## Context

This is the first UI-building phase. Phase 1 (`lib/timer/`, `lib/main.dart`) is a **headless
domain layer + scaffold app shell** — there are no existing screens, widgets, or painters in
this codebase to copy layout/rendering patterns from. Analogs below are therefore drawn from
Phase 1's **structural and stylistic conventions** (file-per-responsibility, abstract
interface + concrete adapter, doc-comment density, test-double style, clamping-on-write) rather
than from same-role prior art, which doesn't exist yet. Where no reasonable analog exists at
all, the file is listed under "No Analog Found" and the planner should lean on
`02-RESEARCH.md`'s Code Examples instead.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/main.dart` (modified) | config/entry-point | request-response (one-shot init) | `lib/main.dart` (current version) | exact (self-modify) |
| `lib/screens/setup_screen.dart` | screen/component | request-response (local widget state) | none in-repo; `lib/timer/timer_controller.dart` for state-transition/doc style only | no-analog (style-only) |
| `lib/screens/placeholder_running_screen.dart` | screen/component | event-driven (reacts to `ChangeNotifier`) | `lib/timer/timer_controller.dart` (consumer side of its own `notifyListeners()` contract) | role-match (partial) |
| `lib/widgets/hold_repeat_button.dart` | component (stateful widget) | event-driven (gesture + self-rescheduling `Timer`) | `lib/timer/timer_controller.dart` (`Timer.periodic`/`Timer` lifecycle + `dispose()` cancellation pattern) | role-match (mechanism, not UI) |
| `lib/widgets/duration_grid.dart` | component | CRUD-like (local selection state) | none in-repo | no-analog |
| `lib/widgets/scene_grid.dart` | component | CRUD-like (local selection state) | none in-repo | no-analog |
| `lib/scenes/scene_preview.dart` | abstraction + service (painter contract) | transform (paint) | `lib/timer/screen_wake.dart` (abstract interface + concrete adapters pattern) | strong role-match (abstraction shape) |
| `lib/theme/app_tokens.dart` | config | n/a (constants) | none in-repo | no-analog |
| `lib/settings/setup_preferences.dart` | service (persistence wrapper) | CRUD (read/write scalars) | `lib/timer/screen_wake.dart` (interface-wrapping-a-plugin pattern, same shape as wrapping `shared_preferences`) | strong role-match |
| `test/screens/setup_screen_test.dart` | test | request-response | `test/widget_test.dart` | exact (widget test scaffold) |
| `test/widgets/hold_repeat_button_test.dart` | test | event-driven | `test/timer/timer_controller_test.dart` (fake-clock/fake-timer style, `group`/`test` structure) | role-match |
| `test/settings/setup_preferences_test.dart` | test | CRUD | `test/timer/timer_controller_test.dart` (test-double pattern — see `FakeScreenWake`) | role-match |
| `test/widget_test.dart` (modified) | test | request-response | `test/widget_test.dart` (current version) | exact (self-modify) |
| `pubspec.yaml` (modified — add `shared_preferences`, font assets) | config | n/a | `pubspec.yaml` (current version) | exact (self-modify) |
| `lib/timer/timer_lifecycle_binder.dart`, `lib/timer/wakelock_screen_wake.dart` | — | — | **DO NOT MODIFY** (out of phase scope per RESEARCH.md Anti-Patterns) | n/a |

## Pattern Assignments

### `lib/main.dart` (modified)

**Analog:** `lib/main.dart` (current, read in full — 55 lines)

**Current shape to extend, not replace** (full file):
```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'timer/timer_controller.dart';
import 'timer/timer_lifecycle_binder.dart';
import 'timer/wakelock_screen_wake.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final timerController = TimerController(screenWake: const WakelockScreenWake());
  TimerLifecycleBinder(timerController).attach();

  runApp(MyApp(timerController: timerController));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.timerController});

  final TimerController timerController;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<TimerController>.value(
      value: timerController,
      child: MaterialApp(
        title: 'Zual',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        home: const MyHomePage(),
      ),
    );
  }
}
```

**Required changes per RESEARCH.md Pitfall 3 / Code Example "Preload Prefs Before First Frame":**
- `main()` becomes `Future<void> main() async`, awaits `SharedPreferences.getInstance()` before
  `runApp()` — same "construct dependency, then `runApp`" shape already established (compare how
  `timerController`/`TimerLifecycleBinder` are built before `runApp` today).
- `MyApp` gains `initialDurationMin`/`initialTheme` constructor params (same named-required-param
  style as `timerController` above), passed down into `SetupScreen`.
- `home: const MyHomePage()` (the "Hello, World!" scaffold) is replaced with `SetupScreen(...)`.
- The deep-purple `ColorScheme.fromSeed` theme should be replaced/overridden by
  `lib/theme/app_tokens.dart`'s tokens per UI-SPEC — do not leave the scaffold's Material seed
  color as the effective theme.
- `MyHomePage` class is deleted once `SetupScreen` replaces it as `home`.

---

### `lib/scenes/scene_preview.dart` — abstraction + 4 concrete painters (D-05/D-06)

**Analog:** `lib/timer/screen_wake.dart` (full file, 32 lines) — same **interface + swappable
concrete implementations** shape that D-06 explicitly asks for ("Setup screen depends on a
per-theme preview abstraction, not literal implementation details" mirrors "`TimerController`
depends on `ScreenWake`, not `wakelock_plus` directly").

**Abstraction pattern to mirror** (`lib/timer/screen_wake.dart` lines 1-31):
```dart
/// Abstraction over keeping the device screen awake while a timer runs.
///
/// Kept as a pure interface with no Material, Widgets, or wakelock_plus
/// imports, so the domain-layer [TimerController][] can enable/disable
/// screen wake without depending on a platform plugin, keeping it trivially
/// unit-testable with a fake implementation.
abstract interface class ScreenWake {
  Future<void> enable();
  Future<void> disable();
}

class NoopScreenWake implements ScreenWake {
  const NoopScreenWake();
  @override
  Future<void> enable() async {}
  @override
  Future<void> disable() async {}
}
```

**Applied shape for scene_preview.dart** (per RESEARCH.md Pattern 2 — combine with the doc-comment
density/rationale style above):
```dart
/// Shared contract every scene's mini-preview painter implements, so
/// SceneCard/SceneGrid depend only on this abstraction — not on any theme's
/// literal painting details. Phase 3 extends this same base for the real
/// scene-at-progress-0 renderer, mirroring [ScreenWake]'s
/// interface-then-adapter shape.
abstract class ScenePreviewPainter extends CustomPainter {
  const ScenePreviewPainter();
}

class DiscPreviewPainter extends ScenePreviewPainter {
  const DiscPreviewPainter();
  @override
  void paint(Canvas canvas, Size size) { /* ... */ }
  @override
  bool shouldRepaint(covariant DiscPreviewPainter oldDelegate) => false;
}
// SunrisePreviewPainter, WalkPreviewPainter, CarPreviewPainter — same shape.
```

**Doc-comment convention to replicate:** every public class/member gets a `///` doc explaining
*why* (rationale), not just what — see `screen_wake.dart` and `timer_controller.dart` throughout.

---

### `lib/settings/setup_preferences.dart` — persistence wrapper (PERSIST-01)

**Analog:** `lib/timer/screen_wake.dart` (interface-wraps-a-plugin shape) combined with
RESEARCH.md's own Code Examples ("Preload Prefs Before First Frame", "Persisting Only Presets,
Never Custom") which are the concrete implementation to use verbatim as a starting point.

**Validation-on-read pattern to replicate** (from `timer_controller.dart` lines 83-84 — clamp on
write is already established here; apply the same clamp on *read* for PERSIST-01 per RESEARCH.md's
Security Domain note):
```dart
void start(int minutes) {
  final clampedMinutes = minutes.clamp(_minMinutes, _maxMinutes);
  _total = Duration(minutes: clampedMinutes);
  ...
}
```
Apply identically: `prefs.getInt('durationMin')?.clamp(1, 120) ?? 5`, and
`SceneTheme.values.firstWhere((t) => t.name == prefs.getString('theme'), orElse: () => SceneTheme.disc)`
(already given in full in RESEARCH.md's Code Examples section — use as-is).

---

### `lib/widgets/hold_repeat_button.dart` (D-07/D-08)

**Analog:** `lib/timer/timer_controller.dart` for **Timer lifecycle discipline only** (not for
UI/gesture code, which has no in-repo analog).

**Timer-cancellation-on-dispose pattern to replicate** (lines 167-174):
```dart
@override
void dispose() {
  _ticker?.cancel();
  if (_phase == TimerPhase.running) {
    _screenWake.disable();
  }
  super.dispose();
}
```
Apply the same rule to `HoldRepeatButton`: cancel `_repeatTimer` in `dispose()` **and** in
`onLongPressEnd`/`onLongPressCancel` (per RESEARCH.md Pitfall 1/2) — never rely on exactly one
path. Full widget implementation is given in RESEARCH.md's Architecture Patterns "Pattern 1" —
use that code example directly; there is no closer in-repo source since gesture/gesture-timer
code doesn't exist yet in this codebase.

---

### `test/screens/setup_screen_test.dart`, `test/widgets/hold_repeat_button_test.dart`, `test/settings/setup_preferences_test.dart`

**Analog:** `test/widget_test.dart` (full file, for widget-test scaffolding) and
`test/timer/timer_controller_test.dart` (for fake-double + `group`/`test` structure).

**Widget test scaffold pattern** (`test/widget_test.dart`, full file):
```dart
import 'package:flutter_test/flutter_test.dart';

import 'package:zual/main.dart';
import 'package:zual/timer/timer_controller.dart';

void main() {
  testWidgets('Displays Hello, World!', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp(timerController: TimerController()));

    expect(find.text('Hello, World!'), findsOneWidget);
  });
}
```
This file must be **updated, not left as-is** — replace the `find.text('Hello, World!')`
assertion since `SetupScreen` removes that scaffold text entirely (RESEARCH.md Wave 0 Gaps).
Update it to assert on something `SetupScreen` actually renders (e.g. the wordmark text "Zual"
or the "Start" button), and update `MyApp(...)` construction if new constructor params
(`initialDurationMin`, `initialTheme`) become required.

**Fake test-double pattern** (`test/timer/timer_controller_test.dart` lines 10-23):
```dart
/// Test double recording enable()/disable() call counts, so screen-wake
/// pairing to running-phase entry/exit can be asserted without touching the
/// real wakelock_plus plugin.
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
```
For `setup_preferences_test.dart`, prefer `SharedPreferences.setMockInitialValues()` (the
official test helper cited in RESEARCH.md's Wave 0 Gaps) over hand-rolling a fake — this is the
one place a hand-rolled fake-double (the pattern above) should NOT be copied, since an official
mock exists.

**`group`/`test` + injected-fake-clock structure to replicate** (lines 25-46):
```dart
void main() {
  group('TimerController', () {
    test('a freshly constructed controller reports setup phase and zero progress', () {
      final controller = TimerController(clock: () => DateTime(2026, 1, 1));
      expect(controller.phase, TimerPhase.setup);
      expect(controller.progress, 0.0);
      controller.dispose();
    });
    ...
  });
}
```
Apply this same `group(ClassName, ...)` / descriptive-sentence `test(...)` naming and explicit
teardown (`.dispose()`/`Timer` cancellation) style to all three new test files.

---

## Shared Patterns

### Doc-comment density and rationale-first style
**Source:** `lib/timer/timer_controller.dart`, `lib/timer/screen_wake.dart` (every public
member has a `///` doc explaining *why*, e.g. lines 42-61 of `timer_controller.dart`)
**Apply to:** All new files — `CLAUDE.md`'s "Comments should explain WHY, not WHAT" convention
is already consistently followed in Phase 1 code; new screen/widget/service files should match
this density, not the sparser style of the original `main.dart` scaffold.

### Interface + concrete-adapter separation for platform/plugin-touching code
**Source:** `lib/timer/screen_wake.dart` (interface) + `lib/timer/wakelock_screen_wake.dart`
(adapter)
**Apply to:** `lib/scenes/scene_preview.dart` (abstraction + 4 painters) and
`lib/settings/setup_preferences.dart` (if the planner chooses to wrap `shared_preferences` behind
a thin interface for testability, matching how `ScreenWake` wraps `wakelock_plus`) — same
motivation: keep the domain/UI layer testable without a real plugin/painter in tests.

### Timer lifecycle discipline (create → cancel-on-every-exit-path → cancel-in-dispose)
**Source:** `lib/timer/timer_controller.dart` (`start()`, `pause()`, `resume()`, `endTimer()`,
`dispose()` — every one of these cancels `_ticker` before creating a new one or exiting)
**Apply to:** `lib/widgets/hold_repeat_button.dart`'s `_repeatTimer` — cancel in
`onLongPressEnd`, `onLongPressCancel`, and `dispose()` (RESEARCH.md Pitfalls 1 & 2).

### Clamp-on-write AND clamp-on-read for bounded values
**Source:** `lib/timer/timer_controller.dart` line 84 (`minutes.clamp(_minMinutes, _maxMinutes)`)
**Apply to:** `lib/settings/setup_preferences.dart`'s read path (clamp restored `durationMin` into
1..120) and `lib/widgets/hold_repeat_button.dart`'s step logic (never let `customMin` leave
1..120 even if disable-button logic has a bug) — per RESEARCH.md's Security Domain V5 note.

## No Analog Found

Files with no close structural match in the codebase — planner should rely on `02-RESEARCH.md`'s
Code Examples and `02-UI-SPEC.md`'s exact visual contract instead:

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `lib/screens/setup_screen.dart` | screen | request-response | First screen in the codebase; no prior Scaffold/layout code beyond the deleted scaffold `MyHomePage` |
| `lib/widgets/duration_grid.dart` | component | CRUD-like | No grid/selection widgets exist yet |
| `lib/widgets/scene_grid.dart` | component | CRUD-like | Same — no grid/selection widgets exist yet |
| `lib/theme/app_tokens.dart` | config | n/a | No design-token/constants file exists yet; source directly from `02-UI-SPEC.md`'s Color/Typography/Spacing tables |
| Font asset bundling (`assets/fonts/*.ttf`, `pubspec.yaml` `flutter: fonts:` block) | config | file-I/O | No `assets/` directory or font declarations exist yet; use RESEARCH.md's "Custom Fonts in pubspec.yaml" code example verbatim, verifying exact filenames at implementation time (Pitfall 5) |

## Metadata

**Analog search scope:** `lib/`, `test/` (entire repository — small enough for exhaustive read)
**Files scanned:** 6 lib files, 2 test files, `pubspec.yaml`
**Pattern extraction date:** 2026-07-07
</content>
</invoke>
