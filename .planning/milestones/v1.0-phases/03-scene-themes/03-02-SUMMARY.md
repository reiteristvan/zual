---
phase: 03-scene-themes
plan: 02
subsystem: ui
tags: [flutter, customPainter, ticker, gradient, animation]

# Dependency graph
requires:
  - phase: 03-scene-themes (Plan 01)
    provides: SceneRenderer/SceneRendererState contract (per-scene Ticker + loopPhase), scene_registry.dart, test/support/progress_sweep.dart
provides:
  - Real, fully animated Night to Sunrise scene (SunrisePainter + SunriseScene)
  - Pure sunrise formulas (starOpacity, moonOpacity, sunTopFraction, hillColor)
  - scene_registry.dart's sunrise arm wired to SunriseScene (walk/car remain pending)
affects: [03-03-walk-car-scenes]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Per-star twinkle phase derived from the scene's shared loopPhase() plus a per-star stagger offset, never a second AnimationController"
    - "Progress-driven gradient shaders (sky) reconstructed every paint call; progress-independent Paint objects (stars/moon/hill fields) cached and mutated in place"
    - "Every progress-derived opacity/alpha clamped via .clamp(0.0,1.0) before withValues(alpha:) -- required because the star/moon raw fade formulas go negative well before progress=1"

key-files:
  created:
    - lib/scenes/sunrise/sunrise_painter.dart
    - lib/scenes/sunrise/sunrise_scene.dart
    - test/scenes/sunrise/sunrise_painter_test.dart
    - test/scenes/sunrise/sunrise_scene_test.dart
  modified:
    - lib/scenes/scene_registry.dart
    - test/scenes/scene_registry_test.dart

key-decisions:
  - "Hill silhouette drawn via canvas.drawOval over a very wide/short bounding rect, matching the UI-SPEC's description of a flat wide ellipse whose top arc reads as a horizon -- no dedicated dashed/path primitive needed"
  - "Sun and moon glow blur radii converted to Gaussian sigma via the same radius*0.57735+0.5 conversion already established by DiscPainter._shadowSigma, applied dynamically since sun glow blur/spread are progress-driven (cannot be a const)"

patterns-established:
  - "Sunrise pure formulas (starOpacity/moonOpacity/sunTopFraction/hillColor) as standalone top-level functions, unit-tested in isolation from paint(), following disc_painter.dart's discColorForRemaining precedent"

requirements-completed: [SCENE-02]

coverage:
  - id: D1
    description: "starOpacity/moonOpacity/sunTopFraction/hillColor pure functions implement the locked sunrise formulas with required Pitfall-3 clamps, staying within 0..1 across the full progress range"
    requirement: "SCENE-02"
    verification:
      - kind: unit
        ref: "test/scenes/sunrise/sunrise_painter_test.dart#starOpacity/moonOpacity/sunTopFraction/hillColor"
        status: pass
    human_judgment: false
  - id: D2
    description: "SunrisePainter.shouldRepaint compares both progress and twinklePhase (Pitfall 2)"
    requirement: "SCENE-02"
    verification:
      - kind: unit
        ref: "test/scenes/sunrise/sunrise_painter_test.dart#SunrisePainter.shouldRepaint"
        status: pass
    human_judgment: false
  - id: D3
    description: "SunriseScene renders without throwing across the full 0.0->1.0 progress sweep, including past p=0.435 (stars) and p=0.588 (moon) where the raw fade formulas go negative"
    requirement: "SCENE-02"
    verification:
      - kind: widget
        ref: "test/scenes/sunrise/sunrise_scene_test.dart#SunriseScene renders without throwing"
        status: pass
    human_judgment: false
  - id: D4
    description: "SunriseScene subtree has no gesture-reactive ancestor and no visible text (SCENE-05)"
    requirement: "SCENE-02"
    verification:
      - kind: widget
        ref: "test/scenes/sunrise/sunrise_scene_test.dart#no gesture-reactive ancestor and no visible text"
        status: pass
    human_judgment: false
  - id: D5
    description: "scene_registry.sceneFor(SceneTheme.sunrise) returns a SunriseScene, replacing the Plan 01 pending fallback"
    requirement: "SCENE-02"
    verification:
      - kind: unit
        ref: "test/scenes/scene_registry_test.dart#sceneFor"
        status: pass
    human_judgment: false
  - id: D6
    description: "Perceptual smoothness ('no visible jank') of the sunrise sky/stars/sun animation on a real low/mid-end Android device (D-03)"
    verification: []
    human_judgment: true
    rationale: "No pixel-diff/frame-timing tooling exists in this project; D-03 explicitly designates this as an end-of-phase human check on a real low/mid-end Android device (API 24-28), not an automated gate."

# Metrics
duration: ~20min
completed: 2026-07-07
status: complete
---

# Phase 3 Plan 2: Night to Sunrise Scene Summary

**Progress-driven Night to Sunrise scene (gradient sky, 28 staggered twinkling stars, fading moon, rising glowing sun, warming hill silhouette) wired into scene_registry.dart, replacing the Plan 01 pending fallback.**

## Performance

- **Duration:** ~20 min
- **Started:** 2026-07-07 (session start)
- **Completed:** 2026-07-07T17:15:47+02:00
- **Tasks:** 2
- **Files modified:** 6 (4 created, 2 modified)

## Accomplishments
- `starOpacity`/`moonOpacity`/`sunTopFraction`/`hillColor`: pure, unit-tested sunrise formulas locked per `design/README.md` §D, with the required `.clamp(0.0, 1.0)` correction on the star/moon fade formulas (Pitfall 3) since the raw `1 - p*k` forms go negative before `progress == 1`
- `SunrisePainter`: full-bleed progress-driven sky gradient (reconstructed every frame per Pitfall 5's explicit exception for this scene), 28 stars with per-star base opacity + staggered `(i%6)*0.5s` twinkle oscillation + layer-wide fade, a fading moon with soft glow, a rising sun with a progress-driven glow-growth formula transcribed verbatim from `Zual.dc.html`, and a warming hill silhouette drawn as a wide flat oval
- `SunriseScene`: mirrors `DiscScene`'s shape exactly -- no `Scaffold`/`GestureDetector`/`Text` anywhere in its subtree (SCENE-05)
- `scene_registry.dart`'s `sceneFor(SceneTheme.sunrise)` now returns the real `SunriseScene`, replacing Plan 01's `_PendingScene` fallback (walk/car remain pending for Plan 03)

## Task Commits

Each task was committed atomically:

1. **Task 1: Sunrise pure formulas + SunrisePainter** - `89ce442` (feat)
2. **Task 2: SunriseScene + register sunrise in the scene registry** - `d3f2580` (feat)

_Note: no TDD-style multi-commit tasks in this plan; each task's tests + implementation landed together._

## Files Created/Modified
- `lib/scenes/sunrise/sunrise_painter.dart` - `starOpacity`/`moonOpacity`/`sunTopFraction`/`hillColor` + `SunrisePainter`
- `lib/scenes/sunrise/sunrise_scene.dart` - `SunriseScene`
- `lib/scenes/scene_registry.dart` - `sceneFor(sunrise)` now returns `SunriseScene`
- `test/scenes/sunrise/sunrise_painter_test.dart` - formula boundary/sweep tests + `shouldRepaint` tests
- `test/scenes/sunrise/sunrise_scene_test.dart` - progress-sweep (including past p=0.435/0.588) + no-gesture/no-text tests
- `test/scenes/scene_registry_test.dart` - extended to assert `sceneFor(sunrise)` is a `SunriseScene`

## Decisions Made
- Hill silhouette drawn via `canvas.drawOval` over a very wide/short bounding rect (150% of screen width, 210px tall, bottom edge 70px past the screen bottom) -- the UI-SPEC explicitly describes this as "a very flat, very wide ellipse whose top arc reads as a hill horizon," and `drawOval` produces exactly that with no dedicated path primitive needed.
- Sun/moon glow blur radii converted to Gaussian sigma via the same `radius*0.57735+0.5` conversion `DiscPainter._shadowSigma` already established in this codebase, computed dynamically for the sun's glow (its blur/spread are themselves progress-driven, so cannot be `const`) and as a `const` for the moon's fixed 30px CSS glow.

## Deviations from Plan

None - plan executed exactly as written. All formulas, colors, geometry, and clamps match `03-UI-SPEC.md` §D verbatim; `SunriseScene` mirrors `DiscScene`'s established shape with no structural deviation.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- `scene_registry.dart` now has two real scenes (Disc, Sunrise) and two pending fallbacks (Walk, Car), ready for Plan 03-03 to finish the registry.
- The D-03 human end-of-phase smoothness check (real low/mid-end Android device, API 24-28) remains an open item for phase-gate verification, covering all scenes including this one -- not resolved by this plan's automated tests.
- Full `flutter test` suite (88 tests) and `flutter analyze` are green after this plan.

---
*Phase: 03-scene-themes*
*Completed: 2026-07-07*

## Self-Check: PASSED

All 4 created source/test files and the 2 modified files verified present on disk with expected content; both commit hashes (`89ce442`, `d3f2580`) verified present in `git log --oneline --all`.
