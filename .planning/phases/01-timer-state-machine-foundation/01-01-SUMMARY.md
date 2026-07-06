---
phase: 01-timer-state-machine-foundation
plan: 01
subsystem: state-machine
tags: [flutter, dart, changenotifier, provider, wakelock_plus, wall-clock, timer]

# Dependency graph
requires: []
provides:
  - "TimerPhase enum (setup, running, paused, done)"
  - "TimerController extends ChangeNotifier — wall-clock progress engine with injected clock"
  - "syncToWallClock() reconcile pattern for tick-independent done detection"
  - "provider ^6.1.5+1 and wakelock_plus ^1.6.1 added to pubspec.yaml"
affects: [02-pause-resume-and-app-wiring, screens, scenes]

# Tech tracking
tech-stack:
  added: [provider ^6.1.5+1, wakelock_plus ^1.6.1]
  patterns:
    - "Injected clock (DateTime Function()) as sole elapsed-time source of truth — enables drift-free progress and deterministic unit tests without real delays"
    - "syncToWallClock() as the single reconcile path: recomputes progress and detects done, callable from both the periodic ticker and (in Plan 02) an app-lifecycle resume hook"
    - "Monotonic progress via a stored high-water mark — guards against backward device-clock movement"
    - "Domain-layer isolation: lib/timer/*.dart imports only package:flutter/foundation.dart and dart:async, never Material/Widgets"

key-files:
  created:
    - lib/timer/timer_phase.dart
    - lib/timer/timer_controller.dart
    - test/timer/timer_controller_test.dart
  modified:
    - pubspec.yaml

key-decisions:
  - "Used DateTime.now() wall-clock deltas via an injected clock, not Stopwatch, per locked decision D-01 — Stopwatch does not reliably count time while the device is backgrounded/asleep on Android, but the countdown must keep advancing (and be able to reach done) while backgrounded."
  - "provider resolved to ^6.1.5+1 (not the plan's literal ^6.1.5) — flutter pub add selected the exact current pub.dev release string for the same 6.1.5 version; semver-compatible, no behavior difference."

patterns-established:
  - "Pattern: single public syncToWallClock() reconcile method is the only place phase transitions and progress high-water-mark updates happen — periodic ticker and (future) lifecycle hooks both funnel through it"
  - "Pattern: TimerController constructor accepts optional clock/tickInterval for test injection, defaulting to DateTime.now / 200ms in production"

requirements-completed: [TIMER-01, TIMER-02]

coverage:
  - id: D1
    description: "TimerPhase enum with exactly setup, running, paused, done in canonical order, zero Material/Widgets imports"
    requirement: "TIMER-01"
    verification:
      - kind: unit
        ref: "flutter analyze lib/timer/timer_phase.dart"
        status: pass
    human_judgment: false
  - id: D2
    description: "TimerController constructs in setup phase with progress 0.0"
    requirement: "TIMER-01"
    verification:
      - kind: unit
        ref: "test/timer/timer_controller_test.dart#a freshly constructed controller reports setup phase and zero progress"
        status: pass
    human_judgment: false
  - id: D3
    description: "start(minutes) transitions to running; progress tracks real elapsed wall-clock time (halfway ≈0.5 within tolerance)"
    requirement: "TIMER-02"
    verification:
      - kind: unit
        ref: "test/timer/timer_controller_test.dart#start(minutes) transitions to running with progress 0.0 at t0"
        status: pass
      - kind: unit
        ref: "test/timer/timer_controller_test.dart#progress advances to ~0.5 at the halfway point of elapsed wall-clock time"
        status: pass
    human_judgment: false
  - id: D4
    description: "Reaching total elapsed time transitions to done with progress exactly 1.0, independent of tick cadence"
    requirement: "TIMER-02"
    verification:
      - kind: unit
        ref: "test/timer/timer_controller_test.dart#reaching total elapsed time transitions to done with progress exactly 1.0, independent of tick cadence (proven via manual clock advance + single syncToWallClock call)"
        status: pass
    human_judgment: false
  - id: D5
    description: "Progress never decreases while a run is active, even if the device clock is moved backward"
    requirement: "TIMER-02"
    verification:
      - kind: unit
        ref: "test/timer/timer_controller_test.dart#progress never decreases when the injected clock moves backward"
        status: pass
    human_judgment: false
  - id: D6
    description: "start() clamps its minutes argument into the inclusive range 1..120"
    requirement: "TIMER-01"
    verification:
      - kind: unit
        ref: "test/timer/timer_controller_test.dart#start() clamps minutes into the inclusive range 1..120"
        status: pass
    human_judgment: false

duration: 12min
completed: 2026-07-06
status: complete
---

# Phase 1 Plan 1: Timer State-Machine Foundation Summary

**Wall-clock `TimerController extends ChangeNotifier` with an injected-clock progress engine, drift-free `setup → running → done` transitions, and monotonic progress proven by 6 deterministic unit tests.**

## Performance

- **Duration:** 12 min
- **Started:** 2026-07-06T17:14:00Z
- **Completed:** 2026-07-06T17:26:25Z
- **Tasks:** 2 completed
- **Files modified:** 4 (3 created, 1 modified)

## Accomplishments
- `TimerPhase` enum with the four canonical states (`setup`, `running`, `paused`, `done`), zero framework imports
- `TimerController` deriving progress from real elapsed wall-clock time via an injected `DateTime Function()` clock (not `Stopwatch`, per locked decision D-01) so the countdown keeps advancing correctly even while the app is backgrounded
- `syncToWallClock()` as the single reconcile path: recomputes progress, detects completion, and transitions to `done` independent of how many ticks fired
- Monotonic non-decreasing `progress` via a stored high-water mark, guarding against a device clock moved backward
- 6 deterministic clock-injected unit tests (no real delays, no `pumpAndSettle`) covering every behavior in the plan's behavior block
- `provider` and `wakelock_plus` added to `pubspec.yaml` for Plan 02

## Task Commits

Each task was committed atomically:

1. **Task 1: Add state/wakelock dependencies and create the TimerPhase enum** - `2870fa4` (feat)
2. **Task 2: Wall-clock TimerController — progress, phase, done transition + deterministic tests** - `77dd416` (test, RED), `ccd9751` (feat, GREEN)

_TDD task produced 2 commits (test → feat); no refactor commit needed — implementation passed on first attempt with clean `flutter analyze`._

## Files Created/Modified
- `pubspec.yaml` - Added `provider ^6.1.5+1` and `wakelock_plus ^1.6.1` dependencies
- `lib/timer/timer_phase.dart` - `enum TimerPhase { setup, running, paused, done }`, zero Material/Widgets imports
- `lib/timer/timer_controller.dart` - `TimerController extends ChangeNotifier`; injected clock as elapsed-time source; `start()`, `syncToWallClock()`, `progress`/`phase` getters, `dispose()`
- `test/timer/timer_controller_test.dart` - 6 deterministic unit tests using a mutable closure-captured `DateTime` as the injected clock

## Decisions Made
- Wall-clock `DateTime` deltas (via injected clock) instead of `Stopwatch`, per the plan's locked decision D-01 — required so the countdown keeps advancing and can reach `done` while the app is backgrounded/device asleep, which a monotonic `Stopwatch` does not reliably do on Android.
- `provider` pinned to `^6.1.5+1` rather than the plan's literal `^6.1.5` string — `flutter pub add` resolved to the exact currently-published version constraint for the same 6.1.5 release; semver-equivalent, no functional difference.

## Deviations from Plan

None - plan executed exactly as written. The `provider` version-string difference (`^6.1.5+1` vs `^6.1.5`) is a cosmetic artifact of `flutter pub add`'s auto-generated constraint and not a deviation in dependency selection or behavior.

## Issues Encountered
None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- `TimerController` and `TimerPhase` are ready for Plan 02 to add `pause()`/`resume()`, `AppLifecycleState` backgrounding reconciliation (calling the same `syncToWallClock()` reconcile path on foreground return per locked decision D-02), `wakelock_plus` enable/disable lifecycle wiring, and app/Provider composition-root wiring.
- No blockers. Domain layer (`lib/timer/`) remains fully isolated from Material/Widgets, confirmed by `flutter analyze` and the unit-test-only test suite (no widget tree pumped).

---
*Phase: 01-timer-state-machine-foundation*
*Completed: 2026-07-06*

## Self-Check: PASSED

All created files verified present: `pubspec.yaml`, `lib/timer/timer_phase.dart`, `lib/timer/timer_controller.dart`, `test/timer/timer_controller_test.dart`.
All task commits verified present in git log: `2870fa4`, `77dd416`, `ccd9751`.
