---
phase: 03-scene-themes
verified: 2026-07-08T00:00:00Z
status: human_needed
score: 9/10 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 8/10
  gaps_closed:
    - "The car's wheels visibly spin (0.7s loop) while the timer is running (SCENE-04, Truth #8 / CR-01) — CarPainter._paintWheel now draws an asymmetric spoke marking after canvas.rotate(spinAngle), and a raster-diff regression test (spinAngle 0.0 vs pi/2 produce non-identical rawRgba buffers) guards the fix."
  gaps_remaining: []
  regressions: []
deferred:
  - truth: "Nothing on the running screen is tappable by the child (ROADMAP Phase 3 Success Criterion 4, literal 'running screen' wording)"
    addressed_in: "Phase 4"
    evidence: "RunningScreen still renders a visible, tappable back IconButton (lib/screens/running_screen.dart:79-92) as an explicit, documented interim composition-root affordance, unchanged by gap-closure plan 03-04. Phase 4's own goal/Success Criterion 1 is precisely this: 'A hidden ~850ms long-press anywhere on the running screen opens the Parent Controls bottom sheet' (CTRL-01). The narrower, scene-scoped SCENE-05 requirement (nothing tappable within a scene's rendered subtree) remains independently verified as met."
human_verification:
  - test: "Watch each of the 4 scenes (Shrinking Disc, Night to Sunrise, Walking Home, Car on a Road) run a full countdown on a real low/mid-end Android device (API 24-28) or a throttled emulator as a lower-confidence fallback, paying particular attention to the Car on a Road scene's now-visible wheel spoke rotation."
    expected: "Each scene's progress-driven motion (disc shrink, sunrise sky/star/sun, walk bob + arrival, car drive + arrival + spoke rotation) is smooth with no visible stepping/jank."
    why_human: "D-03 explicitly designates 'smooth, no jank' perceptual validation as an end-of-phase human check — no pixel-diff/frame-timing tooling exists in this project. Still an open blocker recorded in STATE.md ('Needs real low/mid-end Android device (API 24-28) to validate CustomPainter performance'), unchanged by gap-closure plan 03-04, which only added a raster-diff *correctness* test, not a *performance/smoothness* test."
---

# Phase 3: Scene Themes Verification Report

**Phase Goal:** All four wordless scenes render full-screen and make time-remaining readable at a glance from a single shared progress value, with nothing tappable by the child.
**Verified:** 2026-07-08
**Status:** human_needed
**Re-verification:** Yes — after gap-closure plan 03-04 (CR-01 / Truth #8 wheel-spin fix)

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Each of the 4 themes renders full-screen in portrait with zero text/numerals; nothing tappable within any scene subtree (SCENE-05) | ✓ VERIFIED | Regression check: `disc_scene.dart`/`sunrise_scene.dart`/`walk_scene.dart`/`car_scene.dart` unchanged since initial verification; still each return a bare `CustomPaint(size: Size.infinite, ...)`. `git diff --stat` between pre-03-04 and post-03-04 commits confirms only `lib/scenes/car/car_painter.dart` and `test/scenes/car/car_painter_test.dart` changed. Full `flutter test` run: 108/108 pass. |
| 2 | Shrinking Disc scales down and shifts green→yellow→red as time passes, driven by a per-scene Ticker (not the 200ms notify cadence) | ✓ VERIFIED | Unchanged; `disc_painter_test.dart`/`scene_renderer_test.dart` still pass in the 108/108 full-suite run. |
| 3 | At progress=1 the disc is at its 0.001 radius floor and colored pure red; the scene freezes when phase leaves running | ✓ VERIFIED | Unchanged; covered by the same passing suite. |
| 4 | Night to Sunrise interpolates the sky night→day; stars/moon fade (clamped, never crashing); sun rises; hill warms | ✓ VERIFIED | Unchanged; `sunrise_painter_test.dart`/`sunrise_scene_test.dart` still pass. |
| 5 | Stars twinkle on a staggered loop driven by the same per-scene ticker (no second `AnimationController`) | ✓ VERIFIED | Unchanged; no `AnimationController` anywhere in `lib/scenes/` (confirmed via `03-REVIEW.md`'s fresh full-pass re-review, which covers all four painters). |
| 6 | Walking Home: character walks 6%→68% of screen width, arriving at the house door exactly at time-up, with a 0.62s bob | ✓ VERIFIED | Unchanged; `walk_painter_test.dart`/`walk_scene_test.dart` still pass. |
| 7 | Car on a Road: car drives the same 6%→68% arrival mechanic, arriving at the destination exactly at time-up | ✓ VERIFIED | Unchanged; `car_painter.dart` still imports (not redefines) `arrivalLeftFraction`; `car_painter_test.dart`'s arrival-mechanic group (0.06/0.68) passes. |
| 8 | The car's wheels visibly spin (0.7s loop) while the timer is running (SCENE-04, CR-01) | ✓ VERIFIED | **Gap closed.** `car_painter.dart:248-265`'s `_paintWheel` now draws `canvas.drawLine(Offset.zero, Offset(0, -(_wheelDiameter/2 - 3)), _wheelSpokePaint)` *after* `canvas.rotate(spinAngle)` — an asymmetric marking whose rendered position sweeps with the angle. Directly read the source and confirmed the spoke line is present, uses the pre-existing locked tire color `0xFF6B5E58` (no new color introduced), and sits inside the same `save()`/`rotate(spinAngle)`/`restore()` block as before. The new regression test in `car_painter_test.dart` (`'CarPainter wheel spin is visible (CR-01 / Truth #8 regression)'`) renders the full painter to raw RGBA bytes at `spinAngle: 0.0` and `spinAngle: pi/2` at fixed `progress: 0.5` and asserts `listEquals(bytesAtZero, bytesAtHalfPi)` is `false`. Ran this test directly: `flutter test test/scenes/car/car_painter_test.dart` → 6/6 pass, including this test. `03-REVIEW.md`'s independent re-review (dated after this fix) also traced the fix end-to-end and confirms CR-01 resolved, with save/restore balance and color reuse correct. |
| 9 | `scene_registry.sceneFor` is exhaustive over all four `SceneTheme` values; the interim pending fallback is removed | ✓ VERIFIED | Unchanged; `scene_registry_test.dart` still passes in the full suite. |
| 10 | Scenes animate smoothly without visible jank on a mid/low-end Android device | ? UNCERTAIN | No pixel-diff/frame-timing tooling exists in this project. `STATE.md` still records the open blocker: "Needs real low/mid-end Android device (API 24-28) to validate CustomPainter performance" — unchanged by gap-closure plan 03-04, which added a correctness (raster-diff) test, not a performance/smoothness test. Routed to Human Verification below. |

**Score:** 9/10 truths verified (1 needs human verification — up from 8/10 with 1 failed truth in the initial pass)

### Deferred Items

| # | Item | Addressed In | Evidence |
|---|------|-------------|----------|
| 1 | Nothing on the running screen is tappable by the child (ROADMAP Phase 3 Success Criterion 4's literal "running screen" wording) | Phase 4 | `RunningScreen` (`lib/screens/running_screen.dart:79-92`) still renders a visible, tappable back `IconButton` — unchanged by 03-04, which touched only `car_painter.dart` and its test. This is documented interim scaffolding; Phase 4's goal/Success Criterion 1 is precisely CTRL-01's hidden long-press replacement. The narrower, scene-scoped SCENE-05 requirement (nothing tappable *within* a scene) remains independently verified as met (Truth #1). |

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/scenes/scene_renderer.dart` | `SceneRenderer`/`SceneRendererState` per-scene ticker contract | ✓ VERIFIED | Unchanged since initial verification; still wired into all 4 scenes. |
| `lib/scenes/scene_registry.dart` | `sceneFor(theme)` exhaustive switch | ✓ VERIFIED | Unchanged; exhaustive over 4 themes, no pending fallback. |
| `lib/scenes/disc/disc_painter.dart` + `disc_scene.dart` | Shrinking Disc scene | ✓ VERIFIED | Unchanged. |
| `lib/scenes/sunrise/sunrise_painter.dart` + `sunrise_scene.dart` | Night to Sunrise scene | ✓ VERIFIED | Unchanged. |
| `lib/scenes/walk/walk_painter.dart` + `walk_scene.dart` | Walking Home scene | ✓ VERIFIED | Unchanged. |
| `lib/scenes/car/car_painter.dart` + `car_scene.dart` | Car on a Road scene | ✓ VERIFIED | **Upgraded from ⚠️ PARTIAL.** Wheel-spin sub-feature now genuinely observable; a `_wheelSpokePaint` field and spoke `drawLine` were added, guarded by a new passing raster-diff test. Arrival mechanic unchanged and still correct. |
| `lib/screens/running_screen.dart` | Real Start destination hosting `sceneFor` | ✓ VERIFIED | Unchanged. |
| `test/support/progress_sweep.dart` | Shared progress-sweep test helper | ✓ VERIFIED | Unchanged. |
| `test/scenes/car/car_painter_test.dart` | Regression guard for wheel-spin visibility | ✓ VERIFIED | New `group('CarPainter wheel spin is visible (CR-01 / Truth #8 regression)')` present, substantive (renders actual pixels via `PictureRecorder`→`toImage`→`toByteData(rawRgba)`, not just asserting `shouldRepaint`'s boolean), and passing. |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|----|--------|---------|
| `setup_screen.dart._handleStart` | `RunningScreen(theme: _theme)` | `Navigator.of(context).push(MaterialPageRoute(...))` | ✓ WIRED | Unchanged; `setup_screen_test.dart`'s "SetupScreen -> RunningScreen" group passes (confirmed in the 108-test full run). |
| `RunningScreen.build` | `sceneFor(widget.theme)` | `Positioned.fill(child: sceneFor(widget.theme))` | ✓ WIRED | Unchanged. |
| `scene_registry.sceneFor` | `DiscScene`/`SunriseScene`/`WalkScene`/`CarScene` | Exhaustive switch on `SceneTheme` | ✓ WIRED | Unchanged. |
| `SceneRendererState.loopPhase` | `SunrisePainter.twinklePhase` / `WalkPainter.bobPhase` / `CarPainter.spinAngle` | Each scene's `build()` passes `loopPhase(Duration(...))` into its painter | ✓ WIRED | Unchanged; `car_scene.dart` was explicitly NOT modified by 03-04 (confirmed via `git diff --stat`), only `car_painter.dart` changed. |
| `CarPainter.spinAngle` | Rendered wheel rotation | `canvas.rotate(spinAngle)` in `_paintWheel`, followed by an asymmetric `drawLine` spoke | ✓ EFFECTIVE (fixed) | **Previously ✗ NOT_EFFECTIVE.** The angle is computed and passed correctly every frame (unchanged), and the rotation now has an observable pixel effect because the spoke marking breaks the prior rotational symmetry. Confirmed by direct source read plus the new passing raster-diff test — the exact gap this key link's prior "wired but inert" classification identified. |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Wheel-spin regression test | `flutter test test/scenes/car/car_painter_test.dart` | 6/6 pass, including the new raster-diff assertion | ✓ PASS |
| Full test suite | `flutter test` | 108/108 pass | ✓ PASS |
| `flutter analyze` clean on all Phase 3 files | `flutter analyze lib/scenes lib/screens/running_screen.dart lib/screens/setup_screen.dart` | "No issues found!" | ✓ PASS |
| No debt markers in Phase 3 files | `grep -rn "TBD\|FIXME\|XXX" lib/scenes/ lib/screens/running_screen.dart lib/screens/setup_screen.dart test/scenes/car/car_painter_test.dart` | No matches | ✓ PASS |
| Only expected files changed by gap-closure plan | `git diff --stat` across the 03-04 commit range | Exactly `lib/scenes/car/car_painter.dart` and `test/scenes/car/car_painter_test.dart` (+58/-1) | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|--------------|--------|----------|
| SCENE-01 | 03-01 | Shrinking Disc renders full-screen, shrinks, green→yellow→red | ✓ SATISFIED | Truths #1-3, unchanged. REQUIREMENTS.md marks `[x]` / "Complete". |
| SCENE-02 | 03-02 | Night to Sunrise renders full-screen, sky/stars/moon/sun/hill | ✓ SATISFIED | Truths #1, #4, #5, unchanged. **Note:** REQUIREMENTS.md still shows `[ ]` / "Pending" (line 29, 94) — this is a pre-existing documentation-sync gap unrelated to 03-04's scope, not a code gap; carried forward from the initial verification, not newly introduced. |
| SCENE-03 | 03-03 | Walking Home renders full-screen, character walks and arrives at time-up | ✓ SATISFIED | Truth #6, unchanged. **Note:** REQUIREMENTS.md still shows `[ ]` / "Pending" (line 30, 95) — same pre-existing documentation-sync gap as SCENE-02, unrelated to 03-04. |
| SCENE-04 | 03-03, 03-04 | Car on a Road renders full-screen, car drives and arrives at time-up | ✓ SATISFIED | **Now fully satisfied.** Arrival mechanic (Truth #7) plus wheel-spin (Truth #8, previously failing) both confirmed. `REQUIREMENTS.md` now correctly marks `[x]` / "Complete" (line 31, 96) — confirmed present, committed in `9c2849d docs(03-04): mark SCENE-04 complete in requirements traceability`. |
| SCENE-05 | 03-01/02/03 | All 4 scenes read only shared `progress` via common contract; nothing tappable by the child | ✓ SATISFIED (scene-scoped) | Truth #1, #9, unchanged. Broader roadmap wording ("nothing on the running screen is tappable") remains deferred to Phase 4 — see Deferred Items. |

No orphaned requirements: all 5 requirement IDs declared across the 4 plans (03-01 through 03-04) match REQUIREMENTS.md's Phase 3 mapping exactly. SCENE-04 is declared in both `03-03-PLAN.md` and `03-04-PLAN.md` (the gap-closure plan correctly re-declared the requirement it was restoring).

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `lib/scenes/sunrise/sunrise_painter.dart` | 10-18, 34-36 | Field doc claims "every pure formula" re-clamps `progress`, but `sunTopFraction`/`hillColor` do not | ⚠️ Warning | Carried over from initial verification (WR-02 in `03-REVIEW.md`); no current observable defect; out of 03-04's scope. |
| `lib/scenes/scene_renderer.dart` | 33-45, 56-74 | Decorative `loopPhase` resets to 0 (rather than continuing) when the ticker is stopped/restarted | ⚠️ Warning | Carried over (WR-01); not reachable in Phase 3 (no pause control exists yet); tracked for Phase 4; out of 03-04's scope. |
| `test/support/progress_sweep.dart` | 26-52 | `controller.dispose()` not guarded by `try/finally` — leaks a periodic `Timer` if an assertion throws mid-sweep | ⚠️ Warning | New finding from the fresh `03-REVIEW.md` re-review (WR-03); test-infrastructure only, no production impact; not a phase-goal blocker. |
| `lib/screens/placeholder_running_screen.dart` | whole file | Orphaned dead code, unreachable since `RunningScreen` replaced it | ℹ️ Info | IN-01; maintainability only. |
| `lib/scenes/car/car_painter.dart` / `lib/scenes/walk/walk_painter.dart` | `_bottomY` helper | Duplicated verbatim in both files | ℹ️ Info | Carried over (IN-02); cosmetic only. |
| `test/scenes/scene_registry_test.dart` | 50 | CWD-relative file read | ℹ️ Info | IN-03; only fails if suite is run from a non-standard working directory. |
| `lib/scenes/car/car_painter.dart` | 134-147 | Unused intermediate `Rect` in `_paintDashedLine` | ℹ️ Info | IN-04; readability nit. |
| `lib/scenes/sunrise/sunrise_painter.dart` | 157 | Inline RGB literal instead of named constant | ℹ️ Info | IN-05; style nit. |

None of these are 🛑 Blocker severity (the prior CR-01 blocker is resolved, and `03-REVIEW.md`'s fresh pass confirms 0 critical findings). No `TBD`/`FIXME`/`XXX` debt markers found in any Phase 3 file.

### Human Verification Required

1 item, unchanged from the initial verification (not addressed by gap-closure plan 03-04, which was correctly scoped to the correctness fix only, not the performance/smoothness check):

1. **Real-device smoothness check (D-03)**
   **Test:** Watch each of the 4 scenes run a full countdown on a real low/mid-end Android device (API 24-28), or a throttled emulator as a documented lower-confidence fallback — paying particular attention to the Car on a Road scene's now-visible wheel spoke rotation.
   **Expected:** Each scene's progress-driven motion is smooth with no visible stepping/jank.
   **Why human:** No pixel-diff/frame-timing tooling exists in this project; explicitly deferred to an end-of-phase human check in all plans' `<verification>` blocks (including 03-04's own), and tracked as an open blocker in `STATE.md`.

### Gaps Summary

No blocking gaps remain. The single Phase 3 gap identified in the initial verification — the Car on a Road scene's wheel-spin decorative loop being a rotationally-symmetric visual no-op (Truth #8 / CR-01 / SCENE-04) — is resolved. `CarPainter._paintWheel` now draws an asymmetric spoke marking after `canvas.rotate(spinAngle)`, reusing only the two already-locked wheel colors (no new color), and a raster-diff regression test (rendering to raw RGBA bytes and asserting non-equality across two `spinAngle` values) guards against this exact class of regression — closing the "wired but visually inert" blind spot the original `shouldRepaint`-only test suite could not catch. This was independently confirmed by: (1) direct source reading of the fix, (2) running the new regression test directly (`flutter test test/scenes/car/car_painter_test.dart` → 6/6 pass), (3) running the full test suite (108/108 pass), (4) `flutter analyze` returning clean, and (5) a fresh, independent code review (`03-REVIEW.md`) that traced the same fix end-to-end and confirms CR-01 resolved with 0 critical findings remaining.

`.planning/REQUIREMENTS.md` now correctly marks SCENE-04 as `[x]` / "Complete" (committed in `9c2849d`). SCENE-02 and SCENE-03 remain shown as `[ ]` / "Pending" in that same document despite being functionally complete (verified via Truths #4-6) — this is a pre-existing documentation-sync gap that predates and is unrelated to 03-04's scope; it does not block Phase 3's goal achievement since the underlying code is verified correct, but is worth a follow-up doc-only fix.

The single remaining item — real-device smoothness/jank validation — is routed to human verification per D-03's own design; it was never intended to be an automated gate in this project, and 03-04 correctly did not attempt to substitute for it (a raster-diff test proves the pixels *differ* across frames, not that the *frame rate* is smooth on low-end hardware).

**Recommendation:** Phase 3's automated/code-verifiable goal is now fully achieved. Route the one remaining human-verification item (real low/mid-end Android device smoothness check, all 4 scenes including the new wheel-spoke rotation) to the human checkpoint before considering Phase 3 fully closed. Optionally fix the SCENE-02/SCENE-03 REQUIREMENTS.md checkbox-sync gap in a small doc-only follow-up.

---

*Verified: 2026-07-08*
*Verifier: Claude (gsd-verifier)*
