---
phase: 01-timer-state-machine-foundation
plan: 02
subsystem: state-machine
tags: [flutter, dart, changenotifier, provider, wakelock_plus, widgetsbindingobserver, timer]

# Dependency graph
requires:
  - phase: 01-timer-state-machine-foundation (Plan 01)
    provides: "TimerPhase enum, wall-clock TimerController with start()/syncToWallClock()/progress"
provides:
  - "TimerController.pause()/resume()/endTimer() completing the setup/running/paused/done machine"
  - "pausedAt-based elapsed freeze so pause/resume excludes paused wall-clock time"
  - "ScreenWake interface + NoopScreenWake default (lib/timer/screen_wake.dart)"
  - "WakelockScreenWake adapter over wakelock_plus (lib/timer/wakelock_screen_wake.dart)"
  - "TimerLifecycleBinder — WidgetsBindingObserver that reconciles on resumed (lib/timer/timer_lifecycle_binder.dart)"
  - "Single TimerController exposed at app root via ChangeNotifierProvider (lib/main.dart)"
affects: [02-setup-screen, 03-scene-themes, 04-parent-controls]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "pausedAt nullable timestamp freezes _elapsed while paused; pausedTotal accumulates the paused interval on resume() so it is permanently excluded — the correctness core of pause/resume + backgrounding"
    - "ScreenWake interface/adapter split: domain layer (TimerController, screen_wake.dart) has zero platform-plugin imports; only wakelock_screen_wake.dart touches wakelock_plus"
    - "ScreenWake.enable()/disable() paired strictly to running-phase entry/exit (start, resume enable; pause, done, endTimer disable) — never app-wide"
    - "TimerLifecycleBinder mixes in WidgetsBindingObserver and is the single hook wiring AppLifecycleState.resumed to syncToWallClock(); all other lifecycle states are deliberate no-ops per D-01"

key-files:
  created:
    - lib/timer/screen_wake.dart
    - lib/timer/wakelock_screen_wake.dart
    - lib/timer/timer_lifecycle_binder.dart
  modified:
    - lib/timer/timer_controller.dart
    - lib/main.dart
    - test/timer/timer_controller_test.dart
    - test/widget_test.dart

key-decisions:
  - "Used a private pausedAt DateTime field (not a Stopwatch) to freeze elapsed while paused, consistent with Plan 01's injected-clock design — resume() folds the paused interval into pausedTotal so it's permanently excluded from elapsed active time."
  - "ScreenWake enable/disable calls are fire-and-forget (not awaited) inside the synchronous transition methods, per the plan's explicit instruction — transitions must stay synchronous and testable without async test wrappers."
  - "test/widget_test.dart updated to pass a required TimerController to MyApp — a direct compile break from wiring the provider into main.dart, fixed inline (Rule 3)."

patterns-established:
  - "Pattern: screenWake is an injectable constructor dependency on TimerController (like clock/tickInterval in Plan 01), defaulting to NoopScreenWake so the domain layer stays framework/plugin-free and trivially unit-testable via a FakeScreenWake test double."
  - "Pattern: app-layer lifecycle glue (TimerLifecycleBinder) lives in lib/timer/ but is the one file besides wakelock_screen_wake.dart permitted to import Widgets — it is explicitly documented as app-layer, not domain layer."

requirements-completed: [TIMER-01, TIMER-03, TIMER-04, TIMER-05]

coverage:
  - id: D1
    description: "pause() freezes progress (no-op unless running); resume() excludes the paused interval from elapsed active time (1+4 min of active time completes a 5-min timer paused for 2 min)"
    requirement: "TIMER-03"
    verification:
      - kind: unit
        ref: "test/timer/timer_controller_test.dart#pause() from running freezes progress at the paused instant"
        status: pass
      - kind: unit
        ref: "test/timer/timer_controller_test.dart#pause() is a no-op unless running; resume() is a no-op unless paused"
        status: pass
      - kind: unit
        ref: "test/timer/timer_controller_test.dart#resume() excludes the paused interval from elapsed active time"
        status: pass
    human_judgment: false
  - id: D2
    description: "Backgrounding: clock jumps forward with no ticks, then a single syncToWallClock() reconciles progress/phase to real elapsed time, including reaching done while backgrounded (D-02) and no reset/drift mid-run (D-01)"
    requirement: "TIMER-04"
    verification:
      - kind: unit
        ref: "test/timer/timer_controller_test.dart#backgrounding past total duration reaches done via a single syncToWallClock() call"
        status: pass
      - kind: unit
        ref: "test/timer/timer_controller_test.dart#backgrounding mid-run reconciles to real elapsed progress with no reset"
        status: pass
    human_judgment: false
  - id: D3
    description: "endTimer() returns the controller to setup and resets progress to 0 from running, paused, and done"
    requirement: "TIMER-01"
    verification:
      - kind: unit
        ref: "test/timer/timer_controller_test.dart#endTimer() resets to setup and progress 0.0 from running, paused, and done"
        status: pass
    human_judgment: false
  - id: D4
    description: "Screen wake is enabled exactly on running-phase entry (start, resume) and disabled on every exit (pause, done, endTimer), proven via a FakeScreenWake test double"
    requirement: "TIMER-05"
    verification:
      - kind: unit
        ref: "test/timer/timer_controller_test.dart#TimerController screen wake (4 tests: start enables once, pause disables/resume re-enables, done disables, endTimer disables)"
        status: pass
    human_judgment: false
  - id: D5
    description: "A single TimerController is provided at the app root via ChangeNotifierProvider, wired to a WakelockScreenWake and a TimerLifecycleBinder that reconciles on foreground return"
    requirement: "TIMER-01"
    verification:
      - kind: unit
        ref: "flutter analyze (whole project clean) + test/widget_test.dart#Displays Hello, World! (MyApp constructs and pumps successfully with the provider wiring)"
        status: pass
    human_judgment: false

duration: 32min
completed: 2026-07-06
status: complete
---

# Phase 1 Plan 2: Pause/Resume, Backgrounding, Screen Wake & App Wiring Summary

**Completed the timer state machine — pausedAt-based pause/resume excluding paused time, wall-clock backgrounding reconciliation (including done-while-backgrounded), a ScreenWake abstraction paired to running-phase lifecycle via wakelock_plus, and a single TimerController wired into the app root through provider + a WidgetsBindingObserver lifecycle binder.**

## Performance

- **Duration:** 32 min
- **Started:** 2026-07-06T17:22:00Z
- **Completed:** 2026-07-06T17:53:35Z
- **Tasks:** 2 completed
- **Files modified:** 8 (3 created, 5 modified)

## Accomplishments
- `pause()`/`resume()`/`endTimer()` completing the `setup → running → (paused) → done` machine, all no-ops from invalid phases
- Paused wall-clock time is provably excluded from elapsed active time: a timer paused for 2 minutes finishes exactly 2 minutes later in wall-clock terms than an uninterrupted run
- Backgrounding reconciliation proven deterministically: a clock jump past total duration with zero ticks fired, followed by one `syncToWallClock()` call, reaches `done`; a mid-run jump reconciles progress with no reset and no drift
- `ScreenWake` interface + `NoopScreenWake` default keep `TimerController` plugin-free; `WakelockScreenWake` is the sole adapter touching `wakelock_plus`
- Screen wake is paired strictly to running-phase entry/exit (enabled on `start`/`resume`, disabled on `pause`/`done`/`endTimer`) — proven via a `FakeScreenWake` test double counting calls
- `TimerLifecycleBinder` (`WidgetsBindingObserver`) reconciles the controller to real time only on `AppLifecycleState.resumed`, handling the enum exhaustively (including `hidden`) with explicit no-ops elsewhere per D-01
- `lib/main.dart` constructs one `TimerController` with a `WakelockScreenWake`, attaches a `TimerLifecycleBinder`, and exposes it via `ChangeNotifierProvider<TimerController>` wrapping `MaterialApp`
- 10 new deterministic unit tests (16 total in the suite), all clock-injected — no real delays, no `pumpAndSettle`
- `flutter analyze` clean across the whole project; domain files (`timer_controller.dart`, `timer_phase.dart`, `screen_wake.dart`) still import neither Material, Widgets, nor `wakelock_plus`

## Task Commits

Each task was committed atomically:

1. **Task 1: Pause/resume, endTimer, and backgrounding reconciliation + tests** - `1f0edab` (test, RED), `cdfa1b4` (feat, GREEN)
2. **Task 2: ScreenWake abstraction, wakelock wiring, lifecycle binder, and app root wiring** - `3e03a9f` (test, RED), `4ec691a` (feat, GREEN)

_Both TDD tasks passed clean on first GREEN attempt (`flutter test` + `flutter analyze` both clean); no refactor commits needed._

## Files Created/Modified
- `lib/timer/timer_controller.dart` - Added `_pausedAt` field, reworked `_elapsed` to freeze at `_pausedAt` while paused; added `pause()`, `resume()`, `endTimer()`; added optional `ScreenWake` constructor param, wired `enable()`/`disable()` into every running-phase entry/exit point
- `lib/timer/screen_wake.dart` - `abstract interface class ScreenWake` + `NoopScreenWake` (const, pure default)
- `lib/timer/wakelock_screen_wake.dart` - `WakelockScreenWake implements ScreenWake`, wraps `WakelockPlus.enable()/disable()`
- `lib/timer/timer_lifecycle_binder.dart` - `TimerLifecycleBinder with WidgetsBindingObserver`; `attach()`/`detach()`; `didChangeAppLifecycleState` calls `syncToWallClock()` only on `resumed`, exhaustive over all `AppLifecycleState` values
- `lib/main.dart` - Constructs `TimerController(screenWake: WakelockScreenWake())`, attaches `TimerLifecycleBinder`, wraps `MaterialApp` in `ChangeNotifierProvider<TimerController>.value`; `MyApp` now takes a required `timerController`
- `test/timer/timer_controller_test.dart` - 10 new tests: pause/resume/no-op guards, paused-interval exclusion, done-while-backgrounded, mid-run backgrounding, `endTimer()` from all three non-setup phases, and a `FakeScreenWake` test double with 4 wakelock-pairing tests
- `test/widget_test.dart` - Updated to construct `MyApp(timerController: TimerController())` (see Deviations)

## Decisions Made
- Elapsed-time freeze while paused is implemented via a nullable `_pausedAt` timestamp checked in the `_elapsed` getter, not a separate `Stopwatch` — keeps the single injected-clock model from Plan 01 intact and requires no new time-source abstraction.
- `ScreenWake` calls in transition methods are fire-and-forget `Future`s (not awaited), per the plan's explicit instruction, so `pause()`/`resume()`/`start()`/`endTimer()` remain synchronous and unit-testable without async test wrappers.
- `TimerLifecycleBinder` lives under `lib/timer/` (not a separate `lib/app/` layer) since it is tightly coupled to `TimerController` and this phase's scope; it is explicitly documented as app-layer glue permitted to import Widgets, distinct from the domain layer.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Updated `test/widget_test.dart` for the new required `TimerController` parameter**
- **Found during:** Task 2 (app root wiring)
- **Issue:** Wrapping `MaterialApp` in a provider required `MyApp` to take a `timerController` parameter; the existing default `test/widget_test.dart` constructed `const MyApp()` with no arguments, which no longer compiles.
- **Fix:** Updated the test to construct `MyApp(timerController: TimerController())` and pump that instead.
- **Files modified:** `test/widget_test.dart`
- **Verification:** `flutter test` passes (17/17) including this widget test; `flutter analyze` clean.
- **Committed in:** `4ec691a` (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (blocking compile break from provider wiring)
**Impact on plan:** Directly caused by this plan's own main.dart change; fixing it was necessary to keep the test suite compiling. No scope creep.

## Issues Encountered
None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- The full timer state machine (`setup → running → paused → done`) is complete, provider-wired, and lifecycle-reconciled — ready for Phase 2 (Setup Screen) to call `start()`, Phase 3 (Scene Themes) to read `progress`/`phase`, and Phase 4 (Parent Controls) to call `pause()`/`resume()`/`endTimer()`.
- `lib/main.dart` deliberately ships no new child-facing UI this phase (per plan scope) — the existing placeholder home screen remains until Phase 2.
- No blockers. Domain layer (`lib/timer/timer_controller.dart`, `lib/timer/screen_wake.dart`) remains fully isolated from Material/Widgets/wakelock_plus, confirmed by `flutter analyze` and the unit-test-only test suite for the controller.

---
*Phase: 01-timer-state-machine-foundation*
*Completed: 2026-07-06*

## Self-Check: PASSED

All created/modified files verified present: `lib/timer/screen_wake.dart`, `lib/timer/wakelock_screen_wake.dart`, `lib/timer/timer_lifecycle_binder.dart`, `lib/main.dart`, `test/timer/timer_controller_test.dart`.
All task commits verified present in git log: `1f0edab`, `cdfa1b4`, `3e03a9f`, `4ec691a`, `02ccb2b`.
