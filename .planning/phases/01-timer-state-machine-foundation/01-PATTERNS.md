# Phase 1: Timer State-Machine Foundation - Pattern Map

**Mapped:** 2026-07-06
**Files analyzed:** 4 (new)
**Analogs found:** 0 exact / 1 conventions-only / 4 total

## Summary

This phase is greenfield within the codebase. The entire repo (`lib/main.dart`, `test/widget_test.dart`)
is a single-file, stateless "Hello World" scaffold — no `ChangeNotifier`, no `enum`, no `Stopwatch`/`Timer`
usage, no domain/service layer, no non-widget test exists anywhere in the tree. A targeted search
confirms zero hits for state-machine-relevant patterns:

- No `extends ChangeNotifier` anywhere in `lib/`
- No `Stopwatch`, `Timer.periodic`, or `enum` declarations anywhere in `lib/`
- No directories under `lib/` other than the file `lib/main.dart` itself
- The only existing test (`test/widget_test.dart`) is a `WidgetTester`-based widget test, not a plain
  `dart test`/`flutter_test` unit test of a non-widget class — the pattern this phase actually needs
  (unit-testing a pure-Dart `ChangeNotifier` with no widget tree) does not exist yet either.

Because there is no in-repo analog for the controller/enum/service files this phase creates, do **not**
force a weak match. Instead, this phase's concrete code shape should come from `.planning/research/ARCHITECTURE.md`'s
worked example (Pattern 1: `TimerController extends ChangeNotifier`, Pattern 2: `SceneRenderer` contract) —
already reviewed and locked in via `01-CONTEXT.md`'s Claude's Discretion section (Stopwatch, `provider ^6.1.5`).
The only things genuinely reusable *from the existing codebase* are naming/formatting conventions and the
test-file skeleton shape (import style, `void main()` + `test(...)`/`testWidgets(...)` structure).

## File Classification

| New File | Role | Data Flow | Closest Analog | Match Quality |
|----------|------|-----------|-----------------|----------------|
| `lib/timer/timer_phase.dart` | model (enum) | N/A (pure data) | none | no analog |
| `lib/timer/timer_controller.dart` | service/state (ChangeNotifier) | event-driven (tick-based state machine) | none | no analog |
| `lib/main.dart` (modified) | config/composition root | request-response (widget tree wiring) | `lib/main.dart` (current) | exact (self — modify in place) |
| `test/timer/timer_controller_test.dart` | test | event-driven | `test/widget_test.dart` | role-match only (widget test, not unit test — structure/import convention transferable, content pattern is not) |

Note: `lib/timer/scene_theme.dart` (the `SceneTheme` enum) is listed in RESEARCH's recommended structure
but is Phase 3 (Scene Themes) territory per PROJECT scope; Phase 1's `01-CONTEXT.md` domain boundary is
`phase` + `progress` only. If the planner decides `SceneTheme` needs to exist as a stub in this phase
(e.g., `TimerController.start()` takes a theme parameter), it is the same "no analog" case as `timer_phase.dart` —
treat identically.

## Pattern Assignments

### `lib/timer/timer_phase.dart` (model/enum, no analog)

**No existing analog.** This is a plain Dart `enum`, the simplest possible file — no pattern extraction
needed beyond the naming convention already established (`snake_case.dart` file name, `PascalCase` type name),
confirmed in `.planning/codebase/STRUCTURE.md`:

```dart
enum TimerPhase { setup, running, paused, done }
```

Source: `.planning/research/ARCHITECTURE.md` line 133 (research code example, not a codebase analog).

---

### `lib/timer/timer_controller.dart` (service, event-driven state machine)

**No existing analog in this codebase.** No `ChangeNotifier` subclass, `Stopwatch`, or `Timer.periodic`
usage exists anywhere in `lib/`. Build this from the RESEARCH.md worked example (already vetted and
referenced as canonical in `01-CONTEXT.md`'s Claude's Discretion section), adjusted per this phase's
locked decisions:

**Reference shape** (`.planning/research/ARCHITECTURE.md` lines 136-199 — research example, use as
starting skeleton, not a copy-paste-verbatim source):
```dart
class TimerController extends ChangeNotifier {
  TimerPhase _phase = TimerPhase.setup;
  Duration _total = Duration.zero;
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _ticker;

  TimerPhase get phase => _phase;
  double get progress => _total.inMilliseconds == 0
      ? 0.0
      : (_stopwatch.elapsedMilliseconds / _total.inMilliseconds).clamp(0.0, 1.0);

  void start(int minutes) {
    _total = Duration(minutes: minutes);
    _phase = TimerPhase.running;
    _stopwatch..reset()..start();
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) => _tick());
    notifyListeners();
  }

  void _tick() {
    if (progress >= 1.0) {
      _stopwatch.stop();
      _ticker?.cancel();
      _phase = TimerPhase.done;
    }
    notifyListeners();
  }

  void pause() { /* stopwatch.stop(); phase = paused */ }
  void resume() { /* stopwatch.start(); phase = running */ }
  void endTimer() { /* reset everything to setup */ }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
```

**Decisions this phase must layer on top of the research skeleton** (from `01-CONTEXT.md`):
- **D-01 (no auto-pause on backgrounding):** The `Stopwatch`-based design already gives this for free —
  do NOT add any `AppLifecycleState`-triggered `pause()` call. `progress`/`phase` must be derived purely
  from `_stopwatch.elapsedMilliseconds`, which keeps advancing regardless of app foreground/background state.
- **D-02 (done detection is foreground-only side-effect, computed on resume):** The chime-playing side
  effect (deferred to a later phase per this phase's no-UI/no-audio scope, but the *phase transition*
  itself) must be computed correctly whether or not `_tick()` fired while backgrounded — i.e., `phase`
  should be derivable as a pure function of elapsed time (`_computePhase()`) callable both from the
  periodic tick AND from an `AppLifecycleState.resumed` hook (added by whichever phase wires lifecycle
  observation — confirm with planner whether that hook belongs in this phase or Phase 2/4).
- **D-03 (no cross-process persistence):** Do not add any `shared_preferences`/serialization calls inside
  `TimerController` for `phase`/`start time`/`duration` — those must not survive a process kill. (Contrast
  with `PERSIST-01`'s separate, out-of-scope-for-this-phase duration/theme persistence for the Setup screen.)

**Error handling / validation:** No existing codebase convention to draw from (no error handling exists
anywhere in `lib/main.dart` per `.planning/codebase/ARCHITECTURE.md`'s "Error Handling: None currently
implemented"). Recommend simple defensive guards (e.g., `pause()` no-ops unless `phase == running`, per
the research example's `if (_phase != TimerPhase.running) return;` idiom) rather than throwing — no
project convention establishes exception types yet.

**Import pattern:** No project convention exists for non-widget files. Follow the general Dart-idiomatic
minimal-import style already visible in `lib/main.dart` line 1 (`import 'package:flutter/material.dart';`)
but note `timer_controller.dart` and `timer_phase.dart` must NOT import `material.dart` — only
`package:flutter/foundation.dart` (for `ChangeNotifier`) and `dart:async` (for `Timer`)/`dart:async` or
core Dart. This "zero Material imports in the domain layer" rule is explicitly called out in
`.planning/research/ARCHITECTURE.md` line 115 as the single most important structural boundary for this
phase's testability goal — enforce it even though no existing file demonstrates it yet.

---

### `lib/main.dart` (modified — composition root wiring)

**Analog:** itself, current state (`D:\Projects\zual\lib\main.dart`, full file, 41 lines — already read in full).

**Current pattern to extend, not replace:**
```dart
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zual',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple)),
      home: const MyHomePage(),
    );
  }
}
```
Since this phase is explicitly "no UI" (per `01-CONTEXT.md` Phase Boundary), `main.dart` changes in this
phase should be minimal-to-none — likely just wiring a `ChangeNotifierProvider<TimerController>` above
`MaterialApp` if the planner wants the controller instantiated/testable end-to-end this phase, per
`.planning/research/ARCHITECTURE.md`'s "App Shell" line: `MaterialApp → ChangeNotifierProvider<TimerController>(root)`.
If this phase's scope is strictly the controller + tests with no app wiring, leave `main.dart` untouched
and defer Provider wiring to Phase 2 (Setup Screen). Flag this ambiguity to the planner explicitly.

---

### `test/timer/timer_controller_test.dart` (test, event-driven)

**Analog:** `test/widget_test.dart` (full file, 12 lines — already read in full) — role-match only, not
a content match.

**Transferable convention** (import style + `void main()` structure):
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

**What does NOT transfer:** `timer_controller_test.dart` should be a plain `test()`-based unit test (no
`WidgetTester`, no `pumpWidget`), since `TimerController` has zero Material/widget dependencies per its
own design constraint above. Import `package:flutter_test/flutter_test.dart` still works for plain `test()`
blocks (it re-exports `package:test`), so no new test package dependency is needed — but the body pattern
should look like:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:zual/timer/timer_controller.dart';
import 'package:zual/timer/timer_phase.dart';

void main() {
  test('starts in setup phase', () {
    final controller = TimerController();
    expect(controller.phase, TimerPhase.setup);
  });

  // Use fake_async or a controllable clock to test Timer.periodic-driven
  // progress/pause/resume without real wall-clock delays — see
  // .planning/research/PITFALLS.md for wall-clock testing pitfalls.
}
```
This is the first non-widget unit test in the repo — there is no existing file to model the
`fake_async`/clock-control pattern on; consult `.planning/research/PITFALLS.md` (referenced in
`01-CONTEXT.md` canonical refs) for the wall-clock/drift testing pitfall this phase must guard against.

## Shared Patterns

### Domain-layer isolation (zero Material imports)
**Source:** `.planning/research/ARCHITECTURE.md` line 115 (no in-codebase source exists yet)
**Apply to:** `lib/timer/timer_phase.dart`, `lib/timer/timer_controller.dart`
Only `package:flutter/foundation.dart` (ChangeNotifier) and core `dart:async` may be imported — never
`package:flutter/material.dart` — so these files remain unit-testable via plain `dart test` without
pumping a widget tree.

### Stopwatch-based elapsed time (not manual DateTime bookkeeping)
**Source:** `.planning/research/ARCHITECTURE.md` Pattern 1 and Anti-Pattern 3; locked by `01-CONTEXT.md` Claude's Discretion
**Apply to:** `lib/timer/timer_controller.dart`
`_stopwatch.stop()`/`.start()` naturally exclude paused duration from `elapsedMilliseconds` — do not
hand-track `pausedTotal`/`pauseStart` fields (that was the HTML prototype's approach per `design/README.md`,
explicitly rejected for the Flutter reimplementation).

### Naming/formatting conventions
**Source:** `.planning/codebase/STRUCTURE.md` "Naming Conventions" section
**Apply to:** all new files
`snake_case.dart` file names, `PascalCase` class/enum names — already established, no deviation.

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `lib/timer/timer_phase.dart` | model (enum) | N/A | Codebase has zero enums; first one introduced this phase |
| `lib/timer/timer_controller.dart` | service (ChangeNotifier) | event-driven | Codebase has zero state-management/ChangeNotifier code; entire scaffold is `StatelessWidget`-only |
| `test/timer/timer_controller_test.dart` | test | event-driven | Codebase has zero non-widget unit tests; only existing test is a `WidgetTester`-based widget test |

Planner should rely on `.planning/research/ARCHITECTURE.md` (Patterns 1-3, Anti-Patterns 1-3) and
`.planning/research/PITFALLS.md` as the primary pattern source for this phase's plan files, since the
codebase itself offers no reusable analog beyond basic naming/formatting/import-style conventions.

## Metadata

**Analog search scope:** `lib/` (recursive), `test/` (recursive) — entire Dart source tree (2 files total: `lib/main.dart`, `test/widget_test.dart`)
**Search methods used:** `Grep` for `extends ChangeNotifier`, `Stopwatch`, `Timer.periodic`, `enum` across `lib/`; `Glob` for directory structure under `lib/`; full read of both existing Dart files (each ≤ 41 lines, single-pass read)
**Files scanned:** 2 (`lib/main.dart`, `test/widget_test.dart`) + `pubspec.yaml` (dependency check — confirms `provider`/`audioplayers`/`wakelock_plus` not yet added, per `01-CONTEXT.md`/STACK.md expectations)
**Pattern extraction date:** 2026-07-06
