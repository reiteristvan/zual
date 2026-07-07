---
phase: 03-scene-themes
plan: 03
subsystem: ui
tags: [flutter, custom-painter, canvas, animation, ticker]

# Dependency graph
requires:
  - phase: 03-scene-themes
    provides: SceneRenderer/SceneRendererState ticker contract (Plan 03-01), sceneFor registry pattern and DiscScene/SunriseScene precedent (Plan 03-01/03-02)
provides:
  - "arrivalLeftFraction pure fn (6%->68%, re-clamped) -- the shared arrival mechanic for both Walking Home and Car on a Road"
  - "WalkPainter + WalkScene: full-screen Walking Home scene (SCENE-03) with a bob-animated character walking toward a house"
  - "CarPainter + CarScene: full-screen Car on a Road scene (SCENE-04) reusing arrivalLeftFraction, with continuously spinning wheels"
  - "Exhaustive scene_registry.sceneFor: all four SceneTheme values now map to their real scene; the interim _PendingScene fallback is fully removed"
affects: [phase-04-running-screen-chrome, phase-04-parent-controls]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Static-per-size gradient Paint caching (_skyPaintFor): sky shaders that don't depend on progress but do depend on canvas size are cached lazily and only rebuilt when size changes, not every frame (Pitfall 5)"
    - "CSS-style bottom-offset helper (_bottomY(size, fraction, extraPx)): converts a `bottom: <fraction of height> + <extraPx px>` design-spec value into a canvas y-coordinate, reused across house/path/character/car/dashed-line placement"
    - "Box-to-center conversion for circles positioned via top/left or top/right design-spec offsets (eyes, headlight, wheels): center = box origin + half the diameter, to avoid off-by-half-diameter placement bugs"
    - "canvas.save()/translate()/rotate()/restore() for continuously spinning wheels driven by the shared ticker's loopPhase, never a second AnimationController"

key-files:
  created:
    - lib/scenes/walk/walk_painter.dart
    - lib/scenes/walk/walk_scene.dart
    - lib/scenes/car/car_painter.dart
    - lib/scenes/car/car_scene.dart
    - test/scenes/walk/walk_painter_test.dart
    - test/scenes/walk/walk_scene_test.dart
    - test/scenes/car/car_painter_test.dart
    - test/scenes/car/car_scene_test.dart
  modified:
    - lib/scenes/scene_registry.dart
    - test/scenes/scene_registry_test.dart
    - test/screens/setup_screen_test.dart

key-decisions:
  - "arrivalLeftFraction lives in walk_painter.dart and is imported by car_painter.dart (not redefined) -- one shared arrival formula for both scenes, per the plan's locked D-01 mechanic"
  - "Car door and roof have no rounded corners (drawn as plain Rect/triangle), matching the UI-SPEC's Car geometry table, which lists no radius for those elements unlike Walking Home's rounded door"
  - "Car scene's house roof has no -2px overlap (unlike Walking Home's), per the UI-SPEC's Car geometry table omitting that note"

requirements-completed: [SCENE-03, SCENE-04]

coverage:
  - id: D1
    description: "arrivalLeftFraction pure fn: 0.06 at p=0, 0.68 at p=1, re-clamps out-of-range input"
    requirement: "SCENE-03"
    verification:
      - kind: unit
        ref: "test/scenes/walk/walk_painter_test.dart#arrivalLeftFraction group"
        status: pass
    human_judgment: false
  - id: D2
    description: "WalkScene renders full-screen across the 0.0->1.0 progress sweep with no exceptions, no text, no gesture-reactive ancestor"
    requirement: "SCENE-03"
    verification:
      - kind: integration
        ref: "test/scenes/walk/walk_scene_test.dart"
        status: pass
    human_judgment: false
  - id: D3
    description: "CarScene renders full-screen across the 0.0->1.0 progress sweep, reuses the shared arrival formula, no text, no gesture-reactive ancestor"
    requirement: "SCENE-04"
    verification:
      - kind: integration
        ref: "test/scenes/car/car_scene_test.dart"
        status: pass
      - kind: unit
        ref: "test/scenes/car/car_painter_test.dart"
        status: pass
    human_judgment: false
  - id: D4
    description: "scene_registry.sceneFor is exhaustive over all four SceneTheme values with no pending fallback remaining"
    verification:
      - kind: unit
        ref: "test/scenes/scene_registry_test.dart"
        status: pass
    human_judgment: false
  - id: D5
    description: "Character walk/bob and car drive/wheel-spin animate smoothly with no jank on a real low/mid-end Android device (API 24-28) -- perceptual, end-of-phase UAT item"
    requirement: "SCENE-05"
    verification: []
    human_judgment: true
    rationale: "Smoothness/jank is a perceptual judgment that requires a real or throttled Android device; the plan explicitly defers this to the phase-gate UAT (D-03), with automated widget tests covering only progress-driven correctness as the CI-checkable layer."

# Metrics
duration: 111min
completed: 2026-07-07
status: complete
---

# Phase 3 Plan 3: Walking Home and Car on a Road Scenes Summary

**WalkPainter/WalkScene and CarPainter/CarScene, sharing one arrivalLeftFraction arrival formula, complete the four-scene set and make scene_registry.sceneFor exhaustive with no pending fallback left.**

## Performance

- **Duration:** ~111 min (commit-to-commit)
- **Started:** 2026-07-07T17:32:28+02:00 (approx, Task 1 commit)
- **Completed:** 2026-07-07T19:23:37+02:00 (Task 2 commit)
- **Tasks:** 2
- **Files modified:** 11 (8 created, 3 modified)

## Accomplishments

- Walking Home (SCENE-03): full-screen scene with a static sky/ground/dirt-path/house backdrop and a character that walks from 6% to 68% of screen width as progress advances, arriving exactly at the house door at time-up, with a 0.62s ease-in-out vertical bob.
- Car on a Road (SCENE-04): full-screen scene with a static sky/road/dashed-center-line/house backdrop and a car that drives the same 6%→68% arrival mechanic, with two wheels continuously spinning via `canvas.rotate` on a 0.7s linear loop.
- `arrivalLeftFraction` is defined once (in `walk_painter.dart`) and imported (never redefined) by `car_painter.dart` -- the single shared arrival formula the plan required.
- `scene_registry.sceneFor` is now exhaustive: all four `SceneTheme` values (disc, sunrise, walk, car) map to their real scene widget, and the interim `_PendingScene` placeholder class is deleted entirely.

## Task Commits

Each task was committed atomically:

1. **Task 1: Walking Home end-to-end (arrival fn + painter + scene + registry)** - `d1f0060` (feat)
2. **Task 2: Car on a Road end-to-end + finalize exhaustive registry** - `136dc36` (feat)

**Plan metadata:** (this commit) - `docs(03-03): complete Walking Home and Car on a Road scenes plan`

## Files Created/Modified

- `lib/scenes/walk/walk_painter.dart` - `arrivalLeftFraction` pure fn + `WalkPainter` (sky/clouds/ground/path/house/character with bob)
- `lib/scenes/walk/walk_scene.dart` - `WalkScene extends SceneRenderer`, wires `WalkPainter` to the shared ticker's progress and 620ms bob-loop phase
- `lib/scenes/car/car_painter.dart` - `CarPainter` (sky/road/dashed-line/house/car with spinning wheels), imports `arrivalLeftFraction` from `walk_painter.dart`
- `lib/scenes/car/car_scene.dart` - `CarScene extends SceneRenderer`, wires `CarPainter` to the shared ticker's progress and 700ms spin-loop phase (converted to radians)
- `lib/scenes/scene_registry.dart` - `sceneFor` now exhaustive over all four themes; `_PendingScene` fallback class removed
- `test/scenes/walk/walk_painter_test.dart` - arrival-formula value/re-clamp tests, `shouldRepaint` tests
- `test/scenes/walk/walk_scene_test.dart` - 0.0->1.0 progress-sweep render test, no-text/no-gesture subtree test
- `test/scenes/car/car_painter_test.dart` - shared-arrival assertion, `shouldRepaint` tests
- `test/scenes/car/car_scene_test.dart` - 0.0->1.0 progress-sweep render test, no-text/no-gesture subtree test
- `test/scenes/scene_registry_test.dart` - updated to assert all four themes map to their real scene class and that `_PendingScene` no longer exists in the source
- `test/screens/setup_screen_test.dart` - one test's post-Start `pumpAndSettle()` swapped for the existing `_pumpPastTransition()` helper (see Deviations)

## Decisions Made

- `arrivalLeftFraction` lives in `walk_painter.dart` and is imported by `car_painter.dart` via a `show` clause -- avoids duplicating the shared arrival formula, per the plan's explicit "do NOT redefine it" instruction.
- Car scene's house roof/door omit the -2px overlap and rounded corners that Walking Home's house uses, since `03-UI-SPEC.md`'s Car geometry table doesn't specify those details for the car scene's simplified house (no window, plain door).
- Static sky gradients in both new painters are cached lazily per canvas `size` (rebuilt only if `size` changes) rather than every frame, following the plan's explicit "cache the shader/Paint per Pitfall 5" instruction and mirroring `SunrisePainter`'s existing precedent of *not* caching a genuinely progress-driven gradient.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed `setup_screen_test.dart`'s Start-persistence test hanging on `pumpAndSettle()`**
- **Found during:** Task 1 (after wiring `WalkScene` into `scene_registry`, ran the full test suite per the plan's iterative verification)
- **Issue:** `SetupScreen persistence (PERSIST-01) Start persists theme and duration when a preset is selected (D-10)` selects the Walking Home theme and taps Start, then called `tester.pumpAndSettle()`. Once `SceneTheme.walk` started mapping to the real `WalkScene` (a ticking scene per `03-RESEARCH.md` Pitfall 4), `pumpAndSettle()` hung forever waiting for the scene's continuous per-frame `Ticker` to stop scheduling frames -- it never does while the timer is running. This is exactly the pre-existing `_pumpPastTransition()` helper's documented rationale (already applied to the disc-scene case in the same file), just newly triggered for the walk theme.
- **Fix:** Replaced `await tester.pumpAndSettle();` with `await _pumpPastTransition(tester);` (the existing helper: `pump()` then `pump(300ms)`) for that one assertion, matching the pattern already used elsewhere in the same test file for ticking scenes.
- **Files modified:** `test/screens/setup_screen_test.dart`
- **Verification:** `flutter test test/screens/setup_screen_test.dart` passes (16/16); full suite green (107/107).
- **Committed in:** `d1f0060` (Task 1 commit)

**2. [Rule 1 - Bug] Fixed inverted CSS-`bottom` sign convention for two car-scene elements during authoring**
- **Found during:** Task 2 (self-review before running tests, comparing against the `_bottomY` helper's sign convention already established for the house/path elements)
- **Issue:** The dashed center line (`bottom: 16% - 3px`) and the car group (`bottom: 16% + 6px`) were initially wired through `_bottomY` with an incorrectly negated `extraPx` argument, which would have placed both elements at the wrong vertical offset (sign-flipped by 6-9px) relative to the locked `03-UI-SPEC.md` geometry.
- **Fix:** Corrected the `extraPx` constants to carry their actual signed CSS-offset value directly (`_dashBottomExtraPx = -3`, `_carBottomExtraPx = +6`) and removed the double-negation at each call site, consistent with how `_houseBottomExtraPx` and `WalkPainter`'s equivalents were already correctly signed.
- **Files modified:** `lib/scenes/car/car_painter.dart` (caught and fixed before the file was ever committed)
- **Verification:** Re-derived each offset by hand against the CSS `bottom:` convention and cross-checked against `WalkPainter`'s already-correct usage; `flutter test test/scenes/car/` passes.
- **Committed in:** `136dc36` (Task 2 commit -- fixed during authoring, prior to first commit of this file)

**3. [Rule 1 - Bug] Fixed circle-center math for the car's headlight and wheels**
- **Found during:** Task 2 (self-review, comparing against `WalkPainter`'s correct eye-center derivation, which offsets a box's declared top/left position by half the element's diameter to get its center)
- **Issue:** The headlight (8x8 circle at `top: 14, right: 12` within the car body) and both wheels (28x28 circles at `left: 16`/`left: 66`, `bottom: -11px` within the car group) were initially drawn using the design spec's raw box-position values directly as `Canvas.drawCircle` centers, which is only correct for `Rect`-based elements (top-left origin), not circles (need a center point) -- this would have placed both elements roughly half their diameter off from the locked geometry.
- **Fix:** Converted each circle's box-position (`top`/`left`/`right`/`bottom` offset) to a center point by adding/subtracting half the diameter in each axis, matching `WalkPainter`'s existing correct pattern for the character's eyes.
- **Files modified:** `lib/scenes/car/car_painter.dart` (caught and fixed before the file was ever committed)
- **Verification:** Re-derived each offset by hand; `flutter test test/scenes/car/` passes; `flutter analyze` clean.
- **Committed in:** `136dc36` (Task 2 commit -- fixed during authoring, prior to first commit of this file)

---

**Total deviations:** 3 auto-fixed (all Rule 1 - bug fixes; 1 caught by the full test suite, 2 caught by self-review before committing)
**Impact on plan:** All three fixes were necessary for correctness (positional accuracy against the locked UI-SPEC geometry, and a test-suite regression directly caused by this plan's own change). No scope creep -- no files outside this plan's declared `files_modified` list were touched.

## Issues Encountered

None beyond the auto-fixed deviations above.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- All four scene themes (Shrinking Disc, Night to Sunrise, Walking Home, Car on a Road) now render their real, full-screen, wordless visualizations, completing this phase's core scope (SCENE-01 through SCENE-04).
- `scene_registry.sceneFor` has no remaining interim/pending branches -- Phase 4 (running-screen chrome, parent controls, completion chime) can build on top of a fully real scene set with no further scene-registry changes expected.
- Outstanding, tracked in `03-VERIFICATION.md`/`STATE.md`: the D-03 perceptual "smooth, no jank" check on a real low/mid-end Android device (API 24-28) is still an end-of-phase human UAT item, not resolved by this plan's automated tests -- STATE.md's existing Phase 3 blocker (real device availability) still applies at the phase gate.

---
*Phase: 03-scene-themes*
*Completed: 2026-07-07*
