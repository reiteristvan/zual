---
phase: 03-scene-themes
plan: 04
subsystem: ui
tags: [flutter, custompainter, canvas, testing, regression-test, car-scene]

# Dependency graph
requires:
  - phase: 03-scene-themes
    provides: CarPainter/CarScene (03-01/02/03) and the code-review finding CR-01 (03-REVIEW.md) that the wheel-spin loop was a rotationally-symmetric visual no-op
provides:
  - Asymmetric wheel-spoke marking on CarPainter making the 0.7s wheel-spin loop visually observable
  - Raster-diff regression test guarding against rotationally-symmetric wheel regressions
affects: [phase-03-verification, phase-03-code-review-followup]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Raster-diff testing: PictureRecorder -> toImage -> toByteData(rawRgba) -> listEquals to assert CustomPainter output actually differs across an animated input, not just shouldRepaint's boolean"

key-files:
  created: []
  modified:
    - lib/scenes/car/car_painter.dart
    - test/scenes/car/car_painter_test.dart

key-decisions:
  - "Added a spoke marking reusing only the two already-locked wheel colors (#3A3230 rim / #6B5E58 tire) rather than introducing a new color, per the user-approved deviation from the design source's rotationally symmetric wheel (design/Zual.dc.html:236-237)."
  - "Verified true RED->GREEN TDD cycle by temporarily disabling the new drawLine call and confirming the new raster-diff test fails on the pre-fix symmetric-circle code, then restoring the fix and confirming it passes."

patterns-established: []

requirements-completed: [SCENE-04]

coverage:
  - id: D1
    description: "CarPainter wheel spoke marking makes the 0.7s wheel-spin loop visually observable (rendered raster differs across spinAngle values)"
    requirement: "SCENE-04"
    verification:
      - kind: unit
        ref: "test/scenes/car/car_painter_test.dart#CarPainter wheel spin is visible (CR-01 / Truth #8 regression) rendered rasters at spinAngle 0.0 vs pi/2 are NOT byte-identical"
        status: pass
    human_judgment: false
  - id: D2
    description: "Wheels visibly rotate smoothly on a real low/mid-end Android device (API 24-28) during a running countdown"
    verification: []
    human_judgment: true
    rationale: "Perceptual, on-device confirmation (D-03, end-of-phase human check) cannot be substituted by the automated raster-diff test alone."

duration: 20min
completed: 2026-07-07
status: complete
---

# Phase 3 Plan 04: Car Wheel Visible-Spin Fix (CR-01 Gap Closure) Summary

**Added an asymmetric spoke marking to CarPainter's wheel and a raster-diff regression test, closing the code-review CR-01 gap where the wheel-spin loop was a rotationally symmetric visual no-op.**

## Performance

- **Duration:** ~20 min
- **Completed:** 2026-07-07T20:26:20Z
- **Tasks:** 1
- **Files modified:** 2

## Accomplishments

- `CarPainter._paintWheel` now draws a single spoke line (`Offset.zero` to the rim edge) after `canvas.rotate(spinAngle)`, so the rendered raster genuinely changes as the wheel spins, restoring SCENE-04 / Truth #8.
- The spoke reuses the already-locked tire color (`0xFF6B5E58`) — no new color introduced into `car_painter.dart`.
- Added a raster-diff regression test (`PictureRecorder` -> `toImage` -> `toByteData(rawRgba)`) that renders the full scene at `spinAngle: 0.0` and `spinAngle: pi/2` and asserts the byte buffers differ — the automated guard the original `shouldRepaint`-only test suite lacked.
- Verified the TDD RED/GREEN cycle for real: temporarily disabled the new draw call, confirmed the new test fails against the pre-fix symmetric-circle implementation, then restored the fix and confirmed it passes.
- All pre-existing tests (arrival-mechanic, `shouldRepaint`, `car_scene_test.dart`'s 0..1 sweep and no-text/no-gesture assertions) remain green, unchanged.

## Task Commits

Each task was committed atomically (TDD RED -> GREEN):

1. **Task 1 (RED): add raster-diff regression test** - `2e370ee` (test)
2. **Task 1 (GREEN): add asymmetric wheel-spoke marking to CarPainter** - `6fc7463` (feat)

_TDD gate compliance: `test(...)` commit `2e370ee` precedes `feat(...)` commit `6fc7463`; no separate refactor commit was needed._

## Files Created/Modified

- `lib/scenes/car/car_painter.dart` - Added cached `_wheelSpokePaint` field and a single `canvas.drawLine` call inside `_paintWheel`'s rotate block, making the wheel-spin animation visually observable.
- `test/scenes/car/car_painter_test.dart` - Added a raster-diff regression test group asserting rendered pixel buffers differ across `spinAngle` values.

## Decisions Made

- Reused the two already-locked wheel colors for the spoke marking (no new hex color), per the user-approved deviation documented inline in `car_painter.dart` above the new draw call — the design source itself renders a rotationally symmetric wheel, so this is a deliberate, minimal fidelity deviation, not a bug.
- Ran an actual RED->GREEN verification cycle (temporarily reverting the fix, confirming the new test fails, then restoring it) rather than trusting reasoning alone, since this plan's entire purpose is a regression test guarding a previously-missed visual bug.

## Deviations from Plan

None - plan executed exactly as written. The single documented "deviation" (reusing the locked tire color for the spoke, rather than the literal symmetric-circle design source) was pre-approved by the user in the plan's `<action>` block itself, not discovered during execution.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- SCENE-04 / Truth #8 is restored; the Car on a Road scene's wheel-spin loop is now a genuine, automated-test-guarded visual behavior.
- Remaining Phase 3 verification item: the end-of-phase human check (D-03) — watching the Car on a Road scene run a full countdown on a real low/mid-end Android device (API 24-28) to perceptually confirm smooth wheel rotation. This is unchanged by this plan and remains a manual step.
- `.planning/REQUIREMENTS.md` still needs SCENE-04 ticked off to reflect this plan landing — a documentation-sync step outside this plan's code scope (owned by the orchestrator's post-wave state updates).

---
*Phase: 03-scene-themes*
*Completed: 2026-07-07*

## Self-Check: PASSED

All claimed files and commits verified present on disk / in git history:
- `lib/scenes/car/car_painter.dart` - FOUND
- `test/scenes/car/car_painter_test.dart` - FOUND
- `.planning/phases/03-scene-themes/03-04-SUMMARY.md` - FOUND
- Commit `2e370ee` (test) - FOUND
- Commit `6fc7463` (feat) - FOUND
- Commit `9546f78` (docs) - FOUND
