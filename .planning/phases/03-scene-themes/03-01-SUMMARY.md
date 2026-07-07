---
phase: 03-scene-themes
plan: 01
subsystem: ui
tags: [flutter, customPainter, ticker, animation, timer]

# Dependency graph
requires:
  - phase: 02-setup-screen
    provides: SceneTheme enum, SetupScreen scene picker, PlaceholderRunningScreen navigation slot, TimerController (Phase 1)
provides:
  - SceneRenderer/SceneRendererState contract (per-scene Ticker polling TimerController.progress fresh every frame)
  - scene_registry.dart's sceneFor(theme) -- the one place mapping SceneTheme to a concrete scene widget
  - Real, fully animated Shrinking Disc scene (DiscPainter + DiscScene)
  - RunningScreen (real Start destination, replaces PlaceholderRunningScreen)
  - test/support/progress_sweep.dart shared widget-test helper
affects: [03-02-sunrise-scene, 03-03-walk-car-scenes, 04-parent-controls]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Per-scene Ticker (TickerProviderStateMixin) polls TimerController.progress via context.read every frame -- never via context.watch's 200ms notify cadence"
    - "Pure top-level color/geometry functions (discColorForRemaining) kept separate from CustomPainter.paint for unit-testability without pumping a widget tree"
    - "scene_registry.dart is the single switch mapping SceneTheme -> concrete scene widget (mirrors SceneGrid._painters, D-06)"
    - "Widget tests pump scenes via tester.pump(fixedDuration) at fixed checkpoints, never pumpAndSettle() (infinite Ticker hangs it)"

key-files:
  created:
    - lib/scenes/scene_renderer.dart
    - lib/scenes/disc/disc_painter.dart
    - lib/scenes/disc/disc_scene.dart
    - lib/scenes/scene_registry.dart
    - lib/screens/running_screen.dart
    - test/support/progress_sweep.dart
  modified:
    - lib/screens/setup_screen.dart
    - test/screens/setup_screen_test.dart

key-decisions:
  - "discColorForRemaining(0.2) is pure yellow (not pure red) -- corrected from the plan's literal <behavior> wording to match the UI-SPEC color-zone table's own formula and the plan's own 'done' criterion (pure red only at remaining=0/progress=1); the two lerp zones are continuous at that boundary"
  - "pumpAndSettle() replaced with a bounded tester.pump(duration) after Start in setup_screen_test.dart -- RunningScreen's default Disc scene now runs a continuously-ticking Ticker while the timer is running, which pumpAndSettle waits forever against"
  - "Dashed track ring drawn via repeated canvas.drawArc segments (no native dashed-circle primitive in Canvas)"

patterns-established:
  - "SceneRendererState<T>: base State every future scene (Sunrise/Walk/Car) extends, owning the single Ticker + phase-driven start/stop + loopPhase() decorative-loop helper"

requirements-completed: [SCENE-01, SCENE-05]

coverage:
  - id: D1
    description: "discColorForRemaining pure function implements the locked green/yellow/red color-zone thresholds and lerps"
    requirement: "SCENE-01"
    verification:
      - kind: unit
        ref: "test/scenes/disc/disc_painter_test.dart#discColorForRemaining"
        status: pass
    human_judgment: false
  - id: D2
    description: "DiscScene renders without throwing across the full 0.0->1.0 progress sweep, including exactly 1.0, driven by a per-scene Ticker"
    requirement: "SCENE-01"
    verification:
      - kind: widget
        ref: "test/scenes/disc/disc_scene_test.dart#DiscScene renders without throwing"
        status: pass
    human_judgment: false
  - id: D3
    description: "DiscScene subtree has no gesture-reactive ancestor and no visible text (SCENE-05)"
    requirement: "SCENE-05"
    verification:
      - kind: widget
        ref: "test/scenes/disc/disc_scene_test.dart#no gesture-reactive ancestor and no visible text"
        status: pass
    human_judgment: false
  - id: D4
    description: "SceneRendererState's Ticker starts on TimerPhase.running and stops on paused/done, freezing the last-sampled progress"
    requirement: "SCENE-05"
    verification:
      - kind: widget
        ref: "test/scenes/scene_renderer_test.dart#SceneRendererState"
        status: pass
    human_judgment: false
  - id: D5
    description: "scene_registry.sceneFor returns DiscScene for SceneTheme.disc and a non-null pending fallback for sunrise/walk/car"
    requirement: "SCENE-05"
    verification:
      - kind: unit
        ref: "test/scenes/scene_registry_test.dart#sceneFor"
        status: pass
    human_judgment: false
  - id: D6
    description: "Pressing Start with Disc selected navigates to RunningScreen hosting the real animated Disc scene; back-nav and auto-pop-on-done behave as before"
    requirement: "SCENE-01"
    verification:
      - kind: widget
        ref: "test/screens/setup_screen_test.dart#SetupScreen -> RunningScreen"
        status: pass
    human_judgment: false
  - id: D7
    description: "Perceptual smoothness ('no visible jank') of the Disc scale animation on a real low/mid-end Android device (D-03)"
    verification: []
    human_judgment: true
    rationale: "No pixel-diff/frame-timing tooling exists in this project; D-03 explicitly designates this as an end-of-phase human check on a real low/mid-end Android device (API 24-28), not an automated gate."

# Metrics
duration: 18min
completed: 2026-07-07
status: complete
---

# Phase 3 Plan 1: Scene Rendering Spine + Shrinking Disc Summary

**SceneRenderer/SceneRendererState per-scene-ticker contract, scene_registry.dart, and a fully animated Shrinking Disc scene wired into a new RunningScreen that replaces PlaceholderRunningScreen as Start's destination.**

## Performance

- **Duration:** 18 min
- **Started:** 2026-07-07T16:32:04+02:00
- **Completed:** 2026-07-07T16:50:19+02:00
- **Tasks:** 2
- **Files modified:** 12 (10 created, 2 modified)

## Accomplishments
- `SceneRenderer`/`SceneRendererState<T>`: a `TickerProviderStateMixin`-hosted `Ticker` that polls `TimerController.progress` fresh every frame via `context.read` (not the 200ms `notifyListeners` cadence), started on `TimerPhase.running` and stopped otherwise, plus a `loopPhase(Duration)` helper for future scenes' decorative loops
- `discColorForRemaining`: pure, unit-tested green/yellow/red color-zone function, continuous across both zone boundaries
- `DiscPainter`: full-bleed dashed track ring + progress-driven disc (0.001-floor radius, cached `Paint` fields, `shouldRepaint` comparing `progress`)
- `DiscScene`: the real Shrinking Disc scene, no `Scaffold`/`GestureDetector`/`Text` anywhere in its subtree (SCENE-05)
- `scene_registry.dart`'s `sceneFor(theme)`: the one switch naming concrete scene widgets; Disc is real, Sunrise/Walk/Car are a calm `_PendingScene` placeholder at each theme's locked base color until Plans 02/03
- `RunningScreen`: replaces `PlaceholderRunningScreen` as Start's destination, hosting `sceneFor(widget.theme)`; back-nav and auto-pop-on-done ported verbatim
- `test/support/progress_sweep.dart`: shared `tester.pump(fixedDuration)`-based sweep helper, reused by every scene's widget tests in this and future plans

## Task Commits

Each task was committed atomically:

1. **Task 1: Scene contract + per-scene ticker mixin + Shrinking Disc renderer** - `c613f36` (feat)
2. **Task 2: Wire Disc into the running app (registry + RunningScreen + Setup navigation)** - `8215802` (feat)

_Note: no TDD-style multi-commit tasks in this plan; each task's tests + implementation landed together._

## Files Created/Modified
- `lib/scenes/scene_renderer.dart` - `SceneRenderer`/`SceneRendererState<T>` shared per-scene ticker contract
- `lib/scenes/disc/disc_painter.dart` - `discColorForRemaining` + `DiscPainter`
- `lib/scenes/disc/disc_scene.dart` - `DiscScene`
- `lib/scenes/scene_registry.dart` - `sceneFor(theme)` + interim `_PendingScene`
- `lib/screens/running_screen.dart` - `RunningScreen`, replaces `PlaceholderRunningScreen`
- `lib/screens/setup_screen.dart` - `_handleStart` now navigates to `RunningScreen(theme: _theme)`
- `test/support/progress_sweep.dart` - shared progress-sweep pump helper
- `test/scenes/disc/disc_painter_test.dart` - color-zone + `shouldRepaint` tests
- `test/scenes/disc/disc_scene_test.dart` - progress-sweep + no-gesture/no-text tests
- `test/scenes/scene_renderer_test.dart` - ticker start/stop lifecycle tests
- `test/scenes/scene_registry_test.dart` - `sceneFor` contract tests
- `test/screens/setup_screen_test.dart` - retargeted to `RunningScreen`; `pumpAndSettle()` → bounded `pump()` after Start

## Decisions Made
- `discColorForRemaining(0.2)` implemented as pure yellow, not the plan's literally-stated "pure red at the boundary" — see Deviations below.
- Dashed track ring drawn via repeated `canvas.drawArc` segments rather than a `PathDashEffect` (Flutter's `Canvas`/`Paint` API has no native dashed-circle primitive).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected `discColorForRemaining(0.2)` boundary color from the plan's literal wording**
- **Found during:** Task 1 (writing `disc_painter_test.dart`)
- **Issue:** The plan's `<behavior>` block states `discColorForRemaining(0.2) == const Color(0xFFDE6A4B) (pure red at the boundary)`. Implementing this literally contradicts (a) the plan's own Pattern-3-verbatim formula (`t = remaining/0.2` evaluates to `t=1.0` at `remaining=0.2`, i.e. `lerp(red, yellow, 1.0) = yellow`), (b) `03-UI-SPEC.md`'s own color table (red→yellow zone is `remaining ≤ 0.2` with the same `t = remaining/0.2` formula, also yielding yellow at the 0.2 boundary), (c) continuity with the adjacent yellow→green zone (which independently evaluates to yellow at its own `t=0` boundary at the same `remaining=0.2`), and (d) this same plan's `done` criterion ("At progress=1 the disc is ... colored pure red"), which places pure red only at `remaining=0`.
- **Fix:** Implemented `discColorForRemaining` exactly per Pattern 3 / the UI-SPEC color table (continuous, no discontinuity at any zone boundary); wrote `disc_painter_test.dart` to assert `remaining=0.2` is pure yellow and `remaining=0.0` is pure red, matching the mathematically consistent behavior and the done-state criterion.
- **Files modified:** `lib/scenes/disc/disc_painter.dart`, `test/scenes/disc/disc_painter_test.dart`
- **Verification:** `flutter test test/scenes/disc/disc_painter_test.dart` passes; the discontinuity that would result from the literal wording was manually checked against the UI-SPEC table before writing the fix.
- **Committed in:** `c613f36` (Task 1 commit)

**2. [Rule 3 - Blocking] Retargeted `test/screens/setup_screen_test.dart`'s `PlaceholderRunningScreen` assertions to `RunningScreen`**
- **Found during:** Task 2 (wiring Setup's Start navigation to `RunningScreen`)
- **Issue:** `setup_screen_test.dart` asserted `find.byType(PlaceholderRunningScreen)` in five places; once `_handleStart` was repointed to `RunningScreen`, these assertions would never find a match and the suite would fail outright.
- **Fix:** Updated the import and all five assertions to `RunningScreen`; renamed the `group('SetupScreen -> PlaceholderRunningScreen')` to `group('SetupScreen -> RunningScreen')`.
- **Files modified:** `test/screens/setup_screen_test.dart`
- **Verification:** `flutter test test/screens/setup_screen_test.dart` passes.
- **Committed in:** `8215802` (Task 2 commit)

**3. [Rule 3 - Blocking] Replaced `pumpAndSettle()` with a bounded `pump()` after tapping Start**
- **Found during:** Task 2 (running the full test suite after wiring `RunningScreen`)
- **Issue:** `RunningScreen`'s default theme is Disc, whose `DiscScene` now runs a continuously-scheduling `Ticker` for the entire `TimerPhase.running` duration (correctly, per SCENE-01/05's smoothness requirement). Five `setup_screen_test.dart` tests called `tester.pumpAndSettle()` immediately after tapping Start, which — per `03-RESEARCH.md`'s own documented Pitfall 4 — hangs indefinitely against any screen hosting an infinitely-ticking scene, since `pumpAndSettle` waits for zero scheduled frames. Confirmed empirically: exactly these five tests timed out (`pumpAndSettle timed out`) while the sixth Start-then-pumpAndSettle test, which explicitly selects the still-static Walking Home theme before tapping Start, passed unaffected.
- **Fix:** Added a local `_pumpPastTransition(tester)` helper (`await tester.pump(); await tester.pump(const Duration(milliseconds: 300));`) and used it in place of `pumpAndSettle()` at the five call sites immediately following a Start tap into the (default) Disc scene.
- **Files modified:** `test/screens/setup_screen_test.dart`
- **Verification:** `flutter test test/screens/setup_screen_test.dart` and the full `flutter test` suite (63 tests) pass with no timeouts.
- **Committed in:** `8215802` (Task 2 commit)

---

**Total deviations:** 3 auto-fixed (1 bug fix, 2 blocking-issue fixes)
**Impact on plan:** All three were necessary to keep the plan's own success criteria (color-zone correctness, done-state = pure red, and a genuinely smooth per-frame-ticking scene) internally consistent and to keep the existing test suite green after this plan's intentional behavior change (a continuously-animating `RunningScreen`). No scope creep — no new files, screens, or scenes beyond what the plan specified.

## Issues Encountered
- `BoxShadow.convertRadiusToSigma` is not available as a `const`-callable static in this Flutter SDK version; inlined the equivalent `radius * 0.57735 + 0.5` Gaussian-sigma conversion as a local `const` instead (see `DiscPainter._shadowSigma`).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- `SceneRendererState<T>` and `sceneFor`/`scene_registry.dart` are ready for Plans 03-02 (Sunrise) and 03-03 (Walk/Car) to plug their real scenes in, replacing the two remaining `_PendingScene` fallback arms one at a time.
- The D-03 human end-of-phase smoothness check (real low/mid-end Android device, API 24-28) remains an open item for phase-gate verification, not resolved by this plan's automated tests.
- `lib/screens/placeholder_running_screen.dart` is now unreferenced by any navigation path (only a dartdoc cross-reference remains in `running_screen.dart`); left in place since it was outside this plan's explicit file scope — a candidate for deletion in a later cleanup pass.

---
*Phase: 03-scene-themes*
*Completed: 2026-07-07*
